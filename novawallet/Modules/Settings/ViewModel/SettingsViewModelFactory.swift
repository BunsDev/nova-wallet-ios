import Foundation
import SoraFoundation
import SubstrateSdk
import IrohaCrypto

final class SettingsViewModelFactory: SettingsViewModelFactoryProtocol {
    let iconGenerator: IconGenerating

    init(iconGenerator: IconGenerating) {
        self.iconGenerator = iconGenerator
    }

    func createAccountViewModel(for wallet: MetaAccountModel) -> SettingsAccountViewModel {
        let icon = wallet.walletIdenticonData().flatMap { try? iconGenerator.generateFromAccountId($0) }?
            .imageWithFillColor(
                .clear,
                size: UIConstants.normalAddressIconSize,
                contentScale: UIScreen.main.scale
            )

        return SettingsAccountViewModel(
            name: wallet.name,
            icon: icon,
            walletType: WalletsListSectionViewModel.SectionType(walletType: wallet.type)
        )
    }

    func createSectionViewModels(
        language: Language?,
        currency: String?,
        isBiometricAuthOn: Bool?,
        isPinConfirmationOn: Bool,
        locale: Locale
    ) -> [(SettingsSection, [SettingsCellViewModel])] {
        [
            (.general, [createCommonViewViewModel(row: .wallets, locale: locale)]),
            (.preferences, [
                createValuableViewModel(row: .currency, value: currency, locale: locale),
                createLanguageViewModel(from: language, locale: locale)
            ]),
            (.security, [
                isBiometricAuthOn.map {
                    createSwitchViewModel(row: .biometricAuth, isOn: $0, locale: locale)
                },
                createSwitchViewModel(row: .approveWithPin, isOn: isPinConfirmationOn, locale: locale),
                createCommonViewViewModel(row: .changePin, locale: locale)
            ].compactMap { $0 }),
            (.community, [
                createCommonViewViewModel(row: .telegram, locale: locale),
                createCommonViewViewModel(row: .twitter, locale: locale),
                createCommonViewViewModel(row: .youtube, locale: locale)
            ]),
            (.support, [
                createCommonViewViewModel(row: .rateUs, locale: locale),
                createCommonViewViewModel(row: .email, locale: locale)
            ]),
            (.about, [
                createCommonViewViewModel(row: .website, locale: locale),
                createCommonViewViewModel(row: .github, locale: locale),
                createCommonViewViewModel(row: .terms, locale: locale),
                createCommonViewViewModel(row: .privacyPolicy, locale: locale)
            ])
        ]
    }

    func createConfirmPinInfoAlert(
        locale: Locale,
        enableAction: @escaping () -> Void,
        cancelAction: @escaping () -> Void
    ) -> AlertPresentableViewModel {
        let title = R.string.localizable.settingsApproveWithPinAlertTitle(preferredLanguages: locale.rLanguages)
        let message = R.string.localizable.settingsApproveWithPinAlertMessage(preferredLanguages: locale.rLanguages)
        let enableButtonTitle = R.string.localizable.settingsApproveWithPinAlertEnableButtonTitle(
            preferredLanguages: locale.rLanguages)
        return AlertPresentableViewModel(
            title: title,
            message: message,
            actions: [
                .init(
                    title: enableButtonTitle,
                    handler: enableAction
                ),
                .init(
                    title: R.string.localizable.commonCancel(preferredLanguages: locale.rLanguages),
                    style: .cancel,
                    handler: cancelAction
                )
            ],
            closeAction: nil
        )
    }

    func askBiometryAlert(
        biometrySettings: BiometrySettings?,
        locale: Locale,
        useAction: @escaping () -> Void,
        skipAction: @escaping () -> Void
    ) -> AlertPresentableViewModel? {
        guard let biometryTypeName = biometrySettings?.name else {
            return nil
        }

        let languages = locale.rLanguages
        let title = R.string.localizable.settingsBiometryAuthAlertTitle(
            biometryTypeName,
            preferredLanguages: languages
        )
        let message = R.string.localizable.settingsBiometryAuthAlertMessage(
            biometryTypeName,
            preferredLanguages: languages
        )
        return AlertPresentableViewModel(
            title: title,
            message: message,
            actions: [
                .init(
                    title: R.string.localizable.commonOk(preferredLanguages: languages),
                    handler: useAction
                ),
                .init(
                    title: R.string.localizable.settingsBiometryAuthAlertDisableButton(preferredLanguages: languages),
                    style: .cancel,
                    handler: skipAction
                )
            ], closeAction: nil
        )
    }

    private func createCommonViewViewModel(
        row: SettingsRow,
        locale: Locale
    ) -> SettingsCellViewModel {
        .details(
            .init(
                row: row,
                title: row.title(for: locale),
                icon: row.icon,
                accessoryTitle: nil
            ))
    }

    private func createLanguageViewModel(from language: Language?, locale: Locale) -> SettingsCellViewModel {
        let title = R.string.localizable
            .profileLanguageTitle(preferredLanguages: locale.rLanguages)
        let subtitle = language?.title(in: locale)?.capitalized
        let viewModel = DetailsSettingsCellViewModel(
            row: .language,
            title: title,
            icon: SettingsRow.language.icon,
            accessoryTitle: subtitle
        )

        return .details(viewModel)
    }

    private func createValuableViewModel(
        row: SettingsRow,
        value: String?,
        locale: Locale
    ) -> SettingsCellViewModel {
        .details(
            .init(
                row: row,
                title: row.title(for: locale),
                icon: row.icon,
                accessoryTitle: value
            ))
    }

    private func createSwitchViewModel(
        row: SettingsRow,
        isOn: Bool,
        locale: Locale
    ) -> SettingsCellViewModel {
        .toggle(
            .init(
                row: row,
                title: row.title(for: locale),
                icon: row.icon,
                isOn: isOn
            ))
    }
}
