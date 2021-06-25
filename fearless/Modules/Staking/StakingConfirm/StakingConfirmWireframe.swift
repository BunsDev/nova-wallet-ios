import Foundation

final class StakingConfirmWireframe: StakingConfirmWireframeProtocol, ModalAlertPresenting {
    func complete(from view: StakingConfirmViewProtocol?) {
        let languages = view?.localizationManager?.selectedLocale.rLanguages
        let title = R.string.localizable
            .stakingSetupSentMessage(preferredLanguages: languages)

        let presenter = view?.controller.navigationController?.presentingViewController

        presenter?.dismiss(animated: true) {
            self.presentSuccessNotification(title, from: presenter, completion: nil)
        }
    }
}