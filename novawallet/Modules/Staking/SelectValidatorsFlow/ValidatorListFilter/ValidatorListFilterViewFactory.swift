import SoraFoundation
import SoraKeystore

struct ValidatorListFilterViewFactory {
    static func createView(
        for state: RelaychainStakingSharedStateProtocol,
        filter: CustomValidatorListFilter,
        hasIdentity: Bool,
        delegate: ValidatorListFilterDelegate?
    ) -> ValidatorListFilterViewProtocol? {
        let chainAsset = state.stakingOption.chainAsset

        let wireframe = ValidatorListFilterWireframe()

        let viewModelFactory = ValidatorListFilterViewModelFactory()

        let presenter = ValidatorListFilterPresenter(
            wireframe: wireframe,
            viewModelFactory: viewModelFactory,
            assetInfo: chainAsset.assetDisplayInfo,
            filter: filter,
            hasIdentity: hasIdentity,
            localizationManager: LocalizationManager.shared
        )

        let view = ValidatorListFilterViewController(
            presenter: presenter,
            localizationManager: LocalizationManager.shared
        )

        presenter.delegate = delegate

        return view
    }
}
