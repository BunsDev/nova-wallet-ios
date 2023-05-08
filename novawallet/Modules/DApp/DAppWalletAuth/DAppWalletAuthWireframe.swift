import Foundation

final class DAppWalletAuthWireframe: DAppWalletAuthWireframeProtocol {
    func close(from view: DAppWalletAuthViewProtocol?) {
        view?.controller.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func showWalletChoose(
        from view: DAppWalletAuthViewProtocol?,
        selectedWalletId: String,
        delegate: WalletsChooseDelegate
    ) {
        guard
            let chooseView = WalletsChooseViewFactory.createView(
                for: selectedWalletId,
                delegate: delegate
            ) else {
            return
        }

        let navigationController = NovaNavigationController(rootViewController: chooseView.controller)

        view?.controller.present(navigationController, animated: true)
    }
}
