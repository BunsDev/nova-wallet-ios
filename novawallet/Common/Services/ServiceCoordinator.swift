import Foundation
import SoraKeystore
import SoraFoundation
import SubstrateSdk
import RobinHood

protocol ServiceCoordinatorProtocol: ApplicationServiceProtocol {
    var dappMediator: DAppInteractionMediating { get }

    func updateOnAccountChange()
}

final class ServiceCoordinator {
    let walletSettings: SelectedWalletSettings
    let accountInfoService: AccountInfoUpdatingServiceProtocol
    let assetsService: AssetsUpdatingServiceProtocol
    let evmAssetsService: AssetsUpdatingServiceProtocol
    let evmNativeService: AssetsUpdatingServiceProtocol
    let githubPhishingService: ApplicationServiceProtocol
    let equilibriumService: AssetsUpdatingServiceProtocol
    let dappMediator: DAppInteractionMediating

    init(
        walletSettings: SelectedWalletSettings,
        accountInfoService: AccountInfoUpdatingServiceProtocol,
        assetsService: AssetsUpdatingServiceProtocol,
        evmAssetsService: AssetsUpdatingServiceProtocol,
        evmNativeService: AssetsUpdatingServiceProtocol,
        githubPhishingService: ApplicationServiceProtocol,
        equilibriumService: AssetsUpdatingServiceProtocol,
        dappMediator: DAppInteractionMediating
    ) {
        self.walletSettings = walletSettings
        self.accountInfoService = accountInfoService
        self.assetsService = assetsService
        self.evmAssetsService = evmAssetsService
        self.evmNativeService = evmNativeService
        self.equilibriumService = equilibriumService
        self.githubPhishingService = githubPhishingService
        self.dappMediator = dappMediator
    }
}

extension ServiceCoordinator: ServiceCoordinatorProtocol {
    func updateOnAccountChange() {
        if let selectedMetaAccount = walletSettings.value {
            accountInfoService.update(selectedMetaAccount: selectedMetaAccount)
            assetsService.update(selectedMetaAccount: selectedMetaAccount)
            evmAssetsService.update(selectedMetaAccount: selectedMetaAccount)
            evmNativeService.update(selectedMetaAccount: selectedMetaAccount)
            equilibriumService.update(selectedMetaAccount: selectedMetaAccount)
        }
    }

    func setup() {
        githubPhishingService.setup()
        accountInfoService.setup()
        assetsService.setup()
        evmAssetsService.setup()
        evmNativeService.setup()
        equilibriumService.setup()
        dappMediator.setup()
    }

    func throttle() {
        githubPhishingService.throttle()
        accountInfoService.throttle()
        assetsService.throttle()
        evmAssetsService.throttle()
        evmNativeService.throttle()
        equilibriumService.throttle()
        dappMediator.throttle()
    }
}

extension ServiceCoordinator {
    // swiftlint:disable:next function_body_length
    static func createDefault() -> ServiceCoordinatorProtocol {
        let githubPhishingAPIService = GitHubPhishingServiceFactory.createService()

        let chainRegistry = ChainRegistryFacade.sharedRegistry
        let logger = Logger.shared

        let assetsSyncOperationQueue = OperationManagerFacade.assetsSyncQueue
        let assetsSyncOperationManager = OperationManager(operationQueue: assetsSyncOperationQueue)

        let assetsRepositoryOperationQueue = OperationManagerFacade.assetsRepositoryQueue

        let walletSettings = SelectedWalletSettings.shared
        let substrateStorageFacade = SubstrateDataStorageFacade.shared

        let walletRemoteSubscription = WalletServiceFacade.sharedRemoteSubscriptionService
        let evmWalletRemoteSubscription = WalletServiceFacade.sharedEvmRemoteSubscriptionService

        let storageRequestFactory = StorageRequestFactory(
            remoteFactory: StorageKeyFactory(),
            operationManager: assetsSyncOperationManager
        )

        let accountInfoService = AccountInfoUpdatingService(
            selectedAccount: walletSettings.value,
            chainRegistry: chainRegistry,
            remoteSubscriptionService: walletRemoteSubscription,
            storageFacade: substrateStorageFacade,
            storageRequestFactory: storageRequestFactory,
            eventCenter: EventCenter.shared,
            operationQueue: assetsRepositoryOperationQueue,
            logger: logger
        )

        let assetsService = AssetsUpdatingService(
            selectedAccount: walletSettings.value,
            chainRegistry: chainRegistry,
            remoteSubscriptionService: walletRemoteSubscription,
            storageFacade: substrateStorageFacade,
            storageRequestFactory: storageRequestFactory,
            eventCenter: EventCenter.shared,
            operationQueue: assetsRepositoryOperationQueue,
            logger: logger
        )

        let evmTransactionHistoryUpdaterFactory = EvmTransactionHistoryUpdaterFactory(
            storageFacade: substrateStorageFacade,
            chainRegistry: chainRegistry,
            eventCenter: EventCenter.shared,
            operationQueue: assetsSyncOperationQueue,
            logger: logger
        )

        let evmAssetsService = EvmAssetBalanceUpdatingService(
            selectedAccount: walletSettings.value,
            chainRegistry: chainRegistry,
            remoteSubscriptionService: evmWalletRemoteSubscription,
            transactionHistoryUpdaterFactory: evmTransactionHistoryUpdaterFactory,
            logger: logger
        )

        let evmNativeService = EvmNativeBalanceUpdatingService(
            selectedAccount: walletSettings.value,
            chainRegistry: chainRegistry,
            remoteSubscriptionService: evmWalletRemoteSubscription,
            transactionHistoryUpdaterFactory: evmTransactionHistoryUpdaterFactory,
            logger: logger
        )

        let equilibriumService = EquilibriumAssetBalanceUpdatingService(
            selectedAccount: walletSettings.value,
            chainRegistry: chainRegistry,
            remoteSubscriptionService: walletRemoteSubscription,
            repositoryFactory: SubstrateRepositoryFactory(storageFacade: substrateStorageFacade),
            storageRequestFactory: storageRequestFactory,
            eventCenter: EventCenter.shared,
            operationQueue: OperationQueue(),
            logger: logger
        )

        return ServiceCoordinator(
            walletSettings: walletSettings,
            accountInfoService: accountInfoService,
            assetsService: assetsService,
            evmAssetsService: evmAssetsService,
            evmNativeService: evmNativeService,
            githubPhishingService: githubPhishingAPIService,
            equilibriumService: equilibriumService,
            dappMediator: DAppInteractionFactory.createMediator()
        )
    }
}
