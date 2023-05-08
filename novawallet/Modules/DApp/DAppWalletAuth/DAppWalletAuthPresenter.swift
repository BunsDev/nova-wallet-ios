import Foundation
import SoraFoundation

final class DAppWalletAuthPresenter {
    weak var view: DAppWalletAuthViewProtocol?
    let wireframe: DAppWalletAuthWireframeProtocol
    let interactor: DAppWalletAuthInteractorInputProtocol
    let viewModelFactory: DAppWalletAuthViewModelFactoryProtocol
    let logger: LoggerProtocol

    private var selectedWallet: MetaAccountModel
    private var totalWalletValue: Decimal?
    private var request: DAppAuthRequest

    weak var delegate: DAppAuthDelegate?

    init(
        request: DAppAuthRequest,
        delegate: DAppAuthDelegate,
        viewModelFactory: DAppWalletAuthViewModelFactoryProtocol,
        interactor: DAppWalletAuthInteractorInputProtocol,
        wireframe: DAppWalletAuthWireframeProtocol,
        localizationManager: LocalizationManagerProtocol,
        logger: LoggerProtocol
    ) {
        self.request = request
        selectedWallet = request.wallet
        self.delegate = delegate
        self.viewModelFactory = viewModelFactory
        self.interactor = interactor
        self.wireframe = wireframe
        self.logger = logger
        self.localizationManager = localizationManager
    }

    private func complete(with result: Bool) {
        let response = DAppAuthResponse(approved: result, wallet: selectedWallet)
        delegate?.didReceiveAuthResponse(response, for: request)
        wireframe.close(from: view)
    }

    private func updateView() {
        guard
            let viewModel = viewModelFactory.createViewModel(
                from: request,
                wallet: selectedWallet,
                totalWalletValue: totalWalletValue,
                locale: selectedLocale
            ) else {
            return
        }

        view?.didReceive(viewModel: viewModel)
    }
}

extension DAppWalletAuthPresenter: DAppWalletAuthPresenterProtocol {
    func setup() {
        updateView()

        interactor.fetchTotalValue(for: selectedWallet)
    }

    func approve() {
        complete(with: true)
    }

    func reject() {
        complete(with: false)
    }
}

extension DAppWalletAuthPresenter: DAppWalletAuthInteractorOutputProtocol {
    func didFetchTotalValue(_ value: Decimal, wallet: MetaAccountModel) {
        guard wallet.metaId == selectedWallet.metaId else {
            return
        }

        totalWalletValue = value

        updateView()
    }
}

extension DAppWalletAuthPresenter: Localizable {
    func applyLocalization() {
        if let view = view, view.isSetup {
            updateView()
        }
    }
}
