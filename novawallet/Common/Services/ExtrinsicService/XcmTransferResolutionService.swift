import Foundation
import RobinHood
import SubstrateSdk

typealias XcmTrasferResolutionResult = Result<XcmTransferParties, Error>
typealias XcmTransferResolutionClosure = (XcmTrasferResolutionResult) -> Void

protocol XcmTransferResolutionServiceProtocol {
    func resolveTransferParties(
        for originChainAssetId: ChainAssetId,
        transferDestinationId: XcmTransferDestinationId,
        xcmTransfers: XcmTransfers,
        runningIn queue: DispatchQueue,
        completion completionClosure: @escaping XcmTransferResolutionClosure
    )
}

final class XcmTransferResolutionService {
    struct ResolvedChains {
        let origin: ChainAsset
        let destination: ChainModel
        let reserve: ChainModel
    }

    let chainRegistry: ChainRegistryProtocol
    let operationQueue: OperationQueue

    private lazy var storageRequestFactory: StorageRequestFactoryProtocol = {
        let operationManager = OperationManager(operationQueue: operationQueue)
        return StorageRequestFactory(
            remoteFactory: StorageKeyFactory(),
            operationManager: operationManager
        )
    }()

    init(
        chainRegistry: ChainRegistryProtocol,
        operationQueue: OperationQueue
    ) {
        self.chainRegistry = chainRegistry
        self.operationQueue = operationQueue
    }

    private func resolveChains(
        for originChainAssetId: ChainAssetId,
        destinationId: XcmTransferDestinationId,
        xcmTransfers: XcmTransfers
    ) throws -> ResolvedChains {
        guard
            let originChain = chainRegistry.getChain(for: originChainAssetId.chainId),
            let originAsset = originChain.asset(for: originChainAssetId.assetId) else {
            throw ChainRegistryError.noChain(originChainAssetId.chainId)
        }

        let originChainAsset = ChainAsset(chain: originChain, asset: originAsset)

        guard let destinationChain = chainRegistry.getChain(for: destinationId.chainId) else {
            throw ChainRegistryError.noChain(destinationId.chainId)
        }

        guard let reserveId = xcmTransfers.getReserveTransfering(
            from: originChainAssetId.chainId,
            assetId: originChainAssetId.assetId
        ) else {
            throw XcmTransferFactoryError.noReserve(originChainAssetId)
        }

        guard let reserveChain = chainRegistry.getChain(for: reserveId) else {
            throw ChainRegistryError.noChain(reserveId)
        }

        return ResolvedChains(origin: originChainAsset, destination: destinationChain, reserve: reserveChain)
    }

    private func createParachainIdWrapper(for chainId: ChainModel.Id) -> CompoundOperationWrapper<ParaId> {
        guard let runtimeProvider = chainRegistry.getRuntimeProvider(for: chainId) else {
            return CompoundOperationWrapper.createWithError(ChainRegistryError.runtimeMetadaUnavailable)
        }

        guard let connection = chainRegistry.getConnection(for: chainId) else {
            return CompoundOperationWrapper.createWithError(ChainRegistryError.connectionUnavailable)
        }

        let coderFactoryOperation = runtimeProvider.fetchCoderFactoryOperation()
        let wrapper: CompoundOperationWrapper<StorageResponse<StringScaleMapper<ParaId>>>

        wrapper = storageRequestFactory.queryItem(
            engine: connection,
            factory: { try coderFactoryOperation.extractNoCancellableResultData() },
            storagePath: .parachainId
        )

        wrapper.addDependency(operations: [coderFactoryOperation])

        let mapperOperation = ClosureOperation<ParaId> {
            let response = try wrapper.targetOperation.extractNoCancellableResultData()

            guard let paraId = response.value?.value else {
                throw CommonError.undefined
            }

            return paraId
        }

        mapperOperation.addDependency(wrapper.targetOperation)

        let dependencies = [coderFactoryOperation] + wrapper.allOperations

        return CompoundOperationWrapper(targetOperation: mapperOperation, dependencies: dependencies)
    }

    private func createMergeOperation(
        for resolvedChains: ResolvedChains,
        transferDestinationId: XcmTransferDestinationId,
        destinationParaIdWrapper: CompoundOperationWrapper<ParaId>?,
        reserveParaIdWrapper: CompoundOperationWrapper<ParaId>?
    ) -> BaseOperation<XcmTransferParties> {
        ClosureOperation<XcmTransferParties> {
            let destinationParaId = try destinationParaIdWrapper?.targetOperation.extractNoCancellableResultData()
            let reserveParaId = try reserveParaIdWrapper?.targetOperation.extractNoCancellableResultData()

            let destination = XcmTransferDestination(
                chain: resolvedChains.destination,
                parachainId: destinationParaId,
                accountId: transferDestinationId.accountId
            )

            let reserve = XcmTransferReserve(chain: resolvedChains.reserve, parachainId: reserveParaId)

            return XcmTransferParties(origin: resolvedChains.origin, destination: destination, reserve: reserve)
        }
    }
}

extension XcmTransferResolutionService: XcmTransferResolutionServiceProtocol {
    func resolveTransferParties(
        for originChainAssetId: ChainAssetId,
        transferDestinationId: XcmTransferDestinationId,
        xcmTransfers: XcmTransfers,
        runningIn queue: DispatchQueue,
        completion completionClosure: @escaping XcmTransferResolutionClosure
    ) {
        do {
            let resolvedChains = try resolveChains(
                for: originChainAssetId,
                destinationId: transferDestinationId,
                xcmTransfers: xcmTransfers
            )

            var dependencies: [Operation] = []

            let destinationParaIdWrapper: CompoundOperationWrapper<ParaId>?

            if !resolvedChains.destination.isRelaychain {
                let wrapper = createParachainIdWrapper(
                    for: resolvedChains.destination.chainId
                )

                dependencies.append(contentsOf: wrapper.allOperations)

                destinationParaIdWrapper = wrapper
            } else {
                destinationParaIdWrapper = nil
            }

            let reserveParaIdWrapper: CompoundOperationWrapper<ParaId>?

            if !resolvedChains.reserve.isRelaychain {
                if resolvedChains.reserve.chainId != resolvedChains.destination.chainId {
                    let wrapper = createParachainIdWrapper(for: resolvedChains.reserve.chainId)

                    dependencies.append(contentsOf: wrapper.allOperations)

                    reserveParaIdWrapper = wrapper
                } else {
                    reserveParaIdWrapper = destinationParaIdWrapper
                }
            } else {
                reserveParaIdWrapper = nil
            }

            let mergeOperation = createMergeOperation(
                for: resolvedChains,
                transferDestinationId: transferDestinationId,
                destinationParaIdWrapper: destinationParaIdWrapper,
                reserveParaIdWrapper: reserveParaIdWrapper
            )

            dependencies.forEach { mergeOperation.addDependency($0) }

            mergeOperation.completionBlock = {
                switch mergeOperation.result {
                case let .some(result):
                    callbackClosureIfProvided(completionClosure, queue: queue, result: result)
                case .none:
                    let error = BaseOperationError.parentOperationCancelled
                    callbackClosureIfProvided(completionClosure, queue: queue, result: .failure(error))
                }
            }

            operationQueue.addOperations(dependencies + [mergeOperation], waitUntilFinished: false)

        } catch {
            callbackClosureIfProvided(completionClosure, queue: queue, result: .failure(error))
        }
    }
}
