import XCTest
import SoraKeystore
import SubstrateSdk
import IrohaCrypto
@testable import novawallet

class PayoutRewardsServiceTests: XCTestCase {

    func testPayoutRewardsListForNominator() throws {
        let operationManager = OperationManagerFacade.sharedManager

        let selectedAccount = "5HKcmzDLApS5xERzruR6qwiLWjeVyg1RVQmFNoM44Gtni7SX"
        let chainId = "70255b4d28de0fc4e1a193d7e175ad1ccef431598211c55538f1018651a0344e"

        let storageFacade = SubstrateStorageTestFacade()
        let chainRegistry = ChainRegistryFacade.setupForIntegrationTest(with: storageFacade)

        var selectedChain: ChainModel?

        let syncExpectation = XCTestExpectation()

        chainRegistry.chainsSubscribe(self, runningInQueue: .main) { changes in
            for change in changes {
                switch change {
                case let .insert(chain):
                    if chain.chainId == chainId {
                        selectedChain = chain
                    }
                case let .update(chain):
                    if chain.chainId == chainId {
                        selectedChain = chain
                    }
                case .delete:
                    break
                }
            }

            if !changes.isEmpty {
                syncExpectation.fulfill()
            }
        }

        wait(for: [syncExpectation], timeout: 10)

        guard
            let chainAsset = selectedChain.map({ ChainAsset(chain: $0, asset: $0.assets.first!) }),
            let rewardUrl = selectedChain?.externalApis?.staking()?.first?.url else {
            XCTFail("Unexpected empty reward api")
            return
        }

        let storageRequestFactory = StorageRequestFactory(
            remoteFactory: StorageKeyFactory(),
            operationManager: operationManager
        )
        let validatorsResolutionFactory = PayoutValidatorsForNominatorFactory(
            url: rewardUrl
        )

        let identityOperation = IdentityOperationFactory(requestFactory: storageRequestFactory)
        let payoutInfoFactory = NominatorPayoutInfoFactory(chainAssetInfo: chainAsset.chainAssetInfo)

        let service = PayoutRewardsService(
            selectedAccountAddress: selectedAccount,
            chainFormat: chainAsset.chain.chainFormat,
            validatorsResolutionFactory: validatorsResolutionFactory,
            runtimeCodingService: chainRegistry.getRuntimeProvider(for: chainAsset.chain.chainId)!,
            storageRequestFactory: storageRequestFactory,
            engine: chainRegistry.getConnection(for: chainAsset.chain.chainId)!,
            operationManager: operationManager,
            identityOperationFactory: identityOperation,
            payoutInfoFactory: payoutInfoFactory
        )

        let expectation = XCTestExpectation()

        let wrapper = service.fetchPayoutsOperationWrapper()
        wrapper.targetOperation.completionBlock = {
            do {
                let info = try wrapper.targetOperation.extractNoCancellableResultData()
                let totalReward = info.payouts.reduce(Decimal(0.0)) { $0 + $1.reward }
                let eras = info.payouts.map { $0.era }.sorted()
                Logger.shared.info("Active era: \(info.activeEra)")
                Logger.shared.info("Total reward: \(totalReward)")
                Logger.shared.info("Eras: \(eras)")
            } catch {
                Logger.shared.error("Did receive error: \(error)")
            }

            expectation.fulfill()
        }

        operationManager.enqueue(operations: wrapper.allOperations, in: .transient)

        wait(for: [expectation], timeout: 30)
    }

    func testPayoutRewardsListForValidator() {
        let selectedAccount = "GqpApQStgzzGxYa1XQZQUq9L3aXhukxDWABccbeHEh7zPYR"
        let chainId = KnowChainId.kusama

        let storageFacade = SubstrateStorageTestFacade()
        let chainRegistry = ChainRegistryFacade.setupForIntegrationTest(with: storageFacade)

        var selectedChain: ChainModel?

        let syncExpectation = XCTestExpectation()

        chainRegistry.chainsSubscribe(self, runningInQueue: .main) { changes in
            for change in changes {
                switch change {
                case let .insert(chain):
                    if chain.chainId == chainId {
                        selectedChain = chain
                    }
                case let .update(chain):
                    if chain.chainId == chainId {
                        selectedChain = chain
                    }
                case .delete:
                    break
                }
            }

            if !changes.isEmpty {
                syncExpectation.fulfill()
            }
        }

        wait(for: [syncExpectation], timeout: 10)

        guard let chainAsset = selectedChain.map({ ChainAsset(chain: $0, asset: $0.assets.first! )}) else {
            XCTFail("Unexpected chain asset")
            return
        }

        let operationManager = OperationManagerFacade.sharedManager

        let storageRequestFactory = StorageRequestFactory(
            remoteFactory: StorageKeyFactory(),
            operationManager: operationManager
        )
        let validatorsResolutionFactory = PayoutValidatorsForValidatorFactory()

        let identityOperation = IdentityOperationFactory(requestFactory: storageRequestFactory)
        let payoutInfoFactory = ValidatorPayoutInfoFactory(chainAssetInfo: chainAsset.chainAssetInfo)

        let service = PayoutRewardsService(
            selectedAccountAddress: selectedAccount,
            chainFormat: chainAsset.chain.chainFormat,
            validatorsResolutionFactory: validatorsResolutionFactory,
            runtimeCodingService: chainRegistry.getRuntimeProvider(for: chainAsset.chain.chainId)!,
            storageRequestFactory: storageRequestFactory,
            engine: chainRegistry.getConnection(for: chainAsset.chain.chainId)!,
            operationManager: operationManager,
            identityOperationFactory: identityOperation,
            payoutInfoFactory: payoutInfoFactory
        )

        let expectation = XCTestExpectation()

        let wrapper = service.fetchPayoutsOperationWrapper()
        wrapper.targetOperation.completionBlock = {
            do {
                let info = try wrapper.targetOperation.extractNoCancellableResultData()

                for payout in info.payouts {
                    Logger.shared.info("Reward for era \(payout.era): \(payout.reward)")
                }

                let totalReward = info.payouts.reduce(Decimal(0.0)) { $0 + $1.reward }
                let eras = info.payouts.map { $0.era }.sorted()
                Logger.shared.info("Active era: \(info.activeEra)")
                Logger.shared.info("Total reward: \(totalReward)")
                Logger.shared.info("Eras: \(eras)")
            } catch {
                Logger.shared.error("Did receive error: \(error)")
            }

            expectation.fulfill()
        }

        operationManager.enqueue(operations: wrapper.allOperations, in: .transient)

        wait(for: [expectation], timeout: 30)
    }
}
