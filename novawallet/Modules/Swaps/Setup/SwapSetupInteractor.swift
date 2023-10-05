import UIKit
import RobinHood
import BigInt

final class SwapSetupInteractor: AnyCancellableCleaning {
    weak var presenter: SwapSetupInteractorOutputProtocol?
    let assetConversionOperationFactory: AssetConversionOperationFactoryProtocol
    let assetConversionExtrinsicService: AssetConversionExtrinsicServiceProtocol
    let runtimeService: RuntimeProviderProtocol
    let feeProxy: ExtrinsicFeeProxyProtocol
    let extrinsicServiceFactory: ExtrinsicServiceFactoryProtocol

    private let operationQueue: OperationQueue
    private var quoteCall: CancellableCall?

    init(
        assetConversionOperationFactory: AssetConversionOperationFactoryProtocol,
        assetConversionExtrinsicService: AssetConversionExtrinsicServiceProtocol,
        runtimeService: RuntimeProviderProtocol,
        feeProxy: ExtrinsicFeeProxyProtocol,
        extrinsicServiceFactory: ExtrinsicServiceFactoryProtocol,
        operationQueue: OperationQueue
    ) {
        self.assetConversionOperationFactory = assetConversionOperationFactory
        self.assetConversionExtrinsicService = assetConversionExtrinsicService
        self.runtimeService = runtimeService
        self.feeProxy = feeProxy
        self.extrinsicServiceFactory = extrinsicServiceFactory
        self.operationQueue = operationQueue
    }

    private func quote(args: AssetConversion.QuoteArgs) {
        clear(cancellable: &quoteCall)

        let wrapper = assetConversionOperationFactory.quote(for: args)
        wrapper.targetOperation.completionBlock = { [weak self] in
            guard self?.quoteCall === wrapper else {
                return
            }
            do {
                let result = try wrapper.targetOperation.extractNoCancellableResultData()
                DispatchQueue.main.async {
                    self?.presenter?.didReceive(quote: result)
                }
            } catch {
                self?.presenter?.didReceive(error: .quote(error))
            }
        }

        quoteCall = wrapper
        operationQueue.addOperations(wrapper.allOperations, waitUntilFinished: false)
    }

    private func extrinsicService() -> ExtrinsicServiceProtocol? {
        nil
    }

    private func fee(args _: AssetConversion.CallArgs) {
        guard let extrinsicService = extrinsicService() else {
            presenter?.didReceive(error: .fetchFeeFailed(CommonError.undefined))
            return
        }

//        let builder = assetConversionExtrinsicService.fetchExtrinsicBuilderClosure(
//            for: args,
//            codingFactory: runtimeCoderFactory
//        )
//        feeProxy.estimateFee(using: extrinsicService, reuseIdentifier: "", setupBy: builder)
    }
}

extension SwapSetupInteractor: SwapSetupInteractorInputProtocol {
    func setup() {
        feeProxy.delegate = self
    }

    func calculateQuote(for args: AssetConversion.QuoteArgs) {
        quote(args: args)
    }
}

extension SwapSetupInteractor: ExtrinsicFeeProxyDelegate {
    func didReceiveFee(result: Result<RuntimeDispatchInfo, Error>, for _: TransactionFeeId) {
        switch result {
        case let .success(dispatchInfo):
            let fee = BigUInt(dispatchInfo.fee)
            presenter?.didReceive(fee: fee)
        case let .failure(error):
            presenter?.didReceive(error: .fetchFeeFailed(error))
        }
    }
}
