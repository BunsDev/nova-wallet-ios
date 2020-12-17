import Foundation
import CommonWallet

enum FearlessTransferValidatingError: Error {
    case receiverBalanceTooLow
}

extension FearlessTransferValidatingError: WalletErrorContentConvertible {
    public func toErrorContent(for locale: Locale?) -> WalletErrorContentProtocol {
        let title: String
        let message: String

        switch self {
        case .receiverBalanceTooLow:
            title = R.string.localizable
                .walletSendDeadRecipientTitle(preferredLanguages: locale?.rLanguages)
            message = R.string.localizable
                .walletSendDeadRecipientMessage(preferredLanguages: locale?.rLanguages)
        }

        return ErrorContent(title: title, message: message)
    }
}
