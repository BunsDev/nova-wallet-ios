import Foundation
import SoraFoundation
import SoraKeystore
import RobinHood

struct CrowdloanYourContributionsViewInput {
    let crowdloans: [Crowdloan]
    let contributions: CrowdloanContributionDict
    let displayInfo: CrowdloanDisplayInfoDict?
    let chainAsset: ChainAssetDisplayInfo
}

enum CrowdloanYourContributionsViewFactory {
    static func createView(
        input: CrowdloanYourContributionsViewInput,
        sharedState: CrowdloanSharedState
    ) -> CrowdloanYourContributionsViewProtocol? {
        guard
            let chain = sharedState.settings.value,
            let selectedMetaAccount = SelectedWalletSettings.shared.value
        else { return nil }

        let chainRegistry = ChainRegistryFacade.sharedRegistry

        guard let runtimeService = chainRegistry.getRuntimeProvider(for: chain.chainId) else {
            return nil
        }

        let crowdloanLocalSubscriptionFactory = CrowdloanLocalSubscriptionFactory(
            chainRegistry: chainRegistry,
            storageFacade: SubstrateDataStorageFacade.shared,
            operationManager: OperationManagerFacade.sharedManager,
            logger: Logger.shared
        )

        let interactor = CrowdloanYourContributionsInteractor(
            chain: chain,
            selectedMetaAccount: selectedMetaAccount,
            operationManager: OperationManagerFacade.sharedManager,
            runtimeService: runtimeService,
            crowdloanLocalSubscriptionFactory: crowdloanLocalSubscriptionFactory,
            crowdloanOffchainProviderFactory: sharedState.crowdloanOffchainProviderFactory,
            priceLocalSubscriptionFactory: PriceProviderFactory.shared
        )

        let wireframe = CrowdloanYourContributionsWireframe()

        let viewModelFactory = CrowdloanYourContributionsVMFactory(
            chainDateCalculator: ChainDateCalculator(),
            calendar: Calendar.current
        )

        let presenter = CrowdloanYourContributionsPresenter(
            input: input,
            viewModelFactory: viewModelFactory,
            interactor: interactor,
            wireframe: wireframe,
            timeFormatter: TotalTimeFormatter(),
            localizationManager: LocalizationManager.shared,
            logger: Logger.shared
        )

        let view = CrowdloanYourContributionsViewController(
            presenter: presenter,
            localizationManager: LocalizationManager.shared
        )

        presenter.view = view
        interactor.presenter = presenter

        return view
    }
}
