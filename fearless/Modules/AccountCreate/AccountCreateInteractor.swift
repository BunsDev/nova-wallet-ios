import UIKit
import IrohaCrypto
import RobinHood

final class AccountCreateInteractor {
    weak var presenter: AccountCreateInteractorOutputProtocol!

    let accountOperationFactory: AccountOperationFactoryProtocol
    let mnemonicCreator: IRMnemonicCreatorProtocol
    let operationManager: OperationManagerProtocol

    private var mnemonic: IRMnemonicProtocol?

    private var currentOperation: Operation?

    init(accountOperationFactory: AccountOperationFactoryProtocol,
         mnemonicCreator: IRMnemonicCreatorProtocol,
         operationManager: OperationManagerProtocol) {
        self.accountOperationFactory = accountOperationFactory
        self.mnemonicCreator = mnemonicCreator
        self.operationManager = operationManager
    }
}

extension AccountCreateInteractor: AccountCreateInteractorInputProtocol {
    func setup() {
        do {
            let mnemonic = try mnemonicCreator.randomMnemonic(.entropy128)
            self.mnemonic = mnemonic

            let availableAccountTypes: [SNAddressType] = [.kusamaMain, .polkadotMain, .genericSubstrate]
            let metadata = AccountCreationMetadata(mnemonic: mnemonic.allWords(),
                                                   availableAccountTypes: availableAccountTypes,
                                                   defaultAccountType: .kusamaMain,
                                                   availableCryptoTypes: CryptoType.allCases,
                                                   defaultCryptoType: .sr25519)
            presenter.didReceive(metadata: metadata)
        } catch {
            presenter.didReceiveMnemonicGeneration(error: error)
        }
    }

    func createAccount(request: AccountCreationRequest) {
        guard currentOperation == nil else {
            return
        }

        guard let mnemonic = mnemonic else {
            return
        }

        let operation = accountOperationFactory.newAccountOperation(request: request,
                                                                    mnemonic: mnemonic)

        self.currentOperation = operation

        operation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                self?.currentOperation = nil

                switch operation.result {
                case .success:
                    self?.presenter?.didCompleteAccountCreation()
                case .failure(let error):
                    self?.presenter?.didReceiveAccountCreation(error: error)
                case .none:
                    let error = BaseOperationError.parentOperationCancelled
                    self?.presenter?.didReceiveAccountCreation(error: error)
                }
            }
        }

        operationManager.enqueue(operations: [operation], in: .transient)
    }
}
