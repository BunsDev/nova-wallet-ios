import UIKit
import RobinHood
import FearlessUtils
import IrohaCrypto

final class RecommendedValidatorsInteractor {
    weak var presenter: RecommendedValidatorsInteractorOutputProtocol!

    let operationFactory: ValidatorOperationFactorProtocol
    let operationManager: OperationManagerProtocol
    let logger: LoggerProtocol

    init(operationFactory: ValidatorOperationFactorProtocol,
         operationManager: OperationManagerProtocol,
         logger: LoggerProtocol) {
        self.operationFactory = operationFactory
        self.operationManager = operationManager
        self.logger = logger
    }

    private func prepareRecommendedValidatorList() {
        let wrapper = operationFactory.allElectedOperation()

        wrapper.targetOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                do {
                    let validators = try wrapper.targetOperation.extractNoCancellableResultData()
                    self?.presenter.didReceive(validators: validators)
                } catch {
                    self?.presenter.didReceive(error: error)
                }
            }
        }

        operationManager.enqueue(operations: wrapper.allOperations, in: .transient)
    }
}

extension RecommendedValidatorsInteractor: RecommendedValidatorsInteractorInputProtocol {
    func setup() {
        prepareRecommendedValidatorList()
    }
}
