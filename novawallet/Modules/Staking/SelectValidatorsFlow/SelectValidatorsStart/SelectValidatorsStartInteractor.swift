import UIKit
import RobinHood
import SubstrateSdk
import IrohaCrypto

final class SelectValidatorsStartInteractor: RuntimeConstantFetching {
    weak var presenter: SelectValidatorsStartInteractorOutputProtocol!

    let operationFactory: ValidatorOperationFactoryProtocol
    let operationManager: OperationManagerProtocol
    let runtimeService: RuntimeCodingServiceProtocol
    let preferredValidators: [AccountId]

    init(
        runtimeService: RuntimeCodingServiceProtocol,
        operationFactory: ValidatorOperationFactoryProtocol,
        operationManager: OperationManagerProtocol,
        preferredValidators: [AccountId]
    ) {
        self.runtimeService = runtimeService
        self.operationFactory = operationFactory
        self.operationManager = operationManager
        self.preferredValidators = preferredValidators
    }

    private func prepareRecommendedValidatorList() {
        let wrapper = operationFactory.allPreferred(for: preferredValidators)

        wrapper.targetOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                do {
                    let validators = try wrapper.targetOperation.extractNoCancellableResultData()
                    self?.presenter.didReceiveValidators(result: .success(validators))
                } catch {
                    self?.presenter.didReceiveValidators(result: .failure(error))
                }
            }
        }

        operationManager.enqueue(operations: wrapper.allOperations, in: .transient)
    }

    private func provideMaxNominations() {
        fetchConstant(
            for: .maxNominations,
            runtimeCodingService: runtimeService,
            operationManager: operationManager,
            fallbackValue: SubstrateConstants.maxNominations
        ) { [weak self] (result: Result<Int, Error>) in
            self?.presenter.didReceiveMaxNominations(result: result)
        }
    }
}

extension SelectValidatorsStartInteractor: SelectValidatorsStartInteractorInputProtocol {
    func setup() {
        prepareRecommendedValidatorList()
        provideMaxNominations()
    }
}
