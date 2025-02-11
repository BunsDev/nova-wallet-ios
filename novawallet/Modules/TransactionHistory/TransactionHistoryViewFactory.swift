import Foundation
import SoraFoundation

import RobinHood

struct TransactionHistoryViewFactory {
    static func createView(chainAsset: ChainAsset) -> TransactionHistoryViewProtocol? {
        guard
            let selectedMetaAccount = SelectedWalletSettings.shared.value,
            let accountId = selectedMetaAccount.fetch(for: chainAsset.chain.accountRequest())?.accountId,
            let address = try? accountId.toAddress(using: chainAsset.chain.chainFormat),
            let currencyManager = CurrencyManager.shared else {
            return nil
        }

        let interactor = createInteractor(
            for: accountId,
            chainAsset: chainAsset,
            currencyManager: currencyManager
        )

        let wireframe = TransactionHistoryWireframe(chainAsset: chainAsset)

        let balanceViewModelFactory = BalanceViewModelFactory(
            targetAssetInfo: chainAsset.assetDisplayInfo,
            priceAssetInfoFactory: PriceAssetInfoFactory(currencyManager: currencyManager)
        )

        let viewModelFactory = TransactionHistoryViewModelFactory(
            chainAsset: chainAsset,
            dateFormatter: DateFormatter.txHistory,
            balanceViewModelFactory: balanceViewModelFactory,
            groupDateFormatter: DateFormatter.txHistoryDate.localizableResource()
        )

        let presenter = TransactionHistoryPresenter(
            address: address,
            interactor: interactor,
            wireframe: wireframe,
            viewModelFactory: viewModelFactory,
            localizationManager: LocalizationManager.shared,
            logger: Logger.shared
        )

        let view = TransactionHistoryViewController(
            presenter: presenter,
            localizationManager: LocalizationManager.shared,
            supportsFilters: WalletHistoryFilter.hasSupport(for: chainAsset)
        )

        presenter.view = view
        interactor.presenter = presenter

        return view
    }

    private static func createInteractor(
        for accountId: AccountId,
        chainAsset: ChainAsset,
        currencyManager: CurrencyManagerProtocol
    ) -> TransactionHistoryInteractor {
        let chainRegistry = ChainRegistryFacade.sharedRegistry
        let runtimeProvider = chainRegistry.getRuntimeProvider(for: chainAsset.chain.chainId)

        let operationQueue = OperationManagerFacade.sharedDefaultQueue
        let repositoryFactory = SubstrateRepositoryFactory(storageFacade: SubstrateDataStorageFacade.shared)

        let subscriptionFactory = TransactionLocalSubscriptionFactory(
            storageFacade: SubstrateDataStorageFacade.shared,
            operationQueue: OperationManagerFacade.sharedDefaultQueue
        )

        let fetcherFactory = TransactionHistoryFetcherFactory(
            remoteHistoryFacade: AssetHistoryFacade(),
            providerFactory: subscriptionFactory,
            repositoryFactory: repositoryFactory,
            operationQueue: operationQueue
        )

        let localFilterFactory = TransactionHistoryLocalFilterFactory(
            runtimeProvider: runtimeProvider,
            chainAsset: chainAsset,
            logger: Logger.shared
        )

        return .init(
            accountId: accountId,
            chainAsset: chainAsset,
            fetcherFactory: fetcherFactory,
            localFilterFactory: localFilterFactory,
            priceLocalSubscriptionFactory: PriceProviderFactory.shared,
            currencyManager: currencyManager,
            operationQueue: OperationManagerFacade.sharedDefaultQueue,
            pageSize: 100
        )
    }
}
