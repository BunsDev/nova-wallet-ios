import Foundation
import UIKit
import SoraUI

final class AssetListWireframe: AssetListWireframeProtocol {
    let dappMediator: DAppInteractionMediating

    init(dappMediator: DAppInteractionMediating) {
        self.dappMediator = dappMediator
    }

    func showAssetDetails(from view: AssetListViewProtocol?, chain: ChainModel, asset: AssetModel) {
        guard let assetDetailsView = AssetDetailsContainerViewFactory.createView(
            chain: chain,
            asset: asset
        ),
            let navigationController = view?.controller.navigationController else {
            return
        }
        navigationController.pushViewController(
            assetDetailsView.controller,
            animated: true
        )
    }

    func showHistory(from view: AssetListViewProtocol?, chain: ChainModel, asset: AssetModel) {
        guard let history = TransactionHistoryViewFactory.createView(
            chainAsset: .init(chain: chain, asset: asset)
        ) else {
            return
        }
        guard let navigationController = view?.controller.navigationController else {
            return
        }

        navigationController.pushViewController(
            history.controller,
            animated: true
        )
    }

    func showAssetsSettings(from view: AssetListViewProtocol?) {
        guard let assetsManageView = AssetsSettingsViewFactory.createView() else {
            return
        }

        let navigationController = NovaNavigationController(
            rootViewController: assetsManageView.controller
        )

        view?.controller.present(navigationController, animated: true, completion: nil)
    }

    func showTokensManage(from view: AssetListViewProtocol?) {
        guard let tokensManageView = TokensManageViewFactory.createView() else {
            return
        }

        let navigationController = NovaNavigationController(
            rootViewController: tokensManageView.controller
        )

        view?.controller.present(navigationController, animated: true, completion: nil)
    }

    func showAssetsSearch(
        from view: AssetListViewProtocol?,
        initState: AssetListInitState,
        delegate: AssetsSearchDelegate
    ) {
        guard let assetsSearchView = AssetsSearchViewFactory.createView(for: initState, delegate: delegate) else {
            return
        }

        assetsSearchView.controller.modalTransitionStyle = .crossDissolve
        assetsSearchView.controller.modalPresentationStyle = .fullScreen

        view?.controller.present(assetsSearchView.controller, animated: true, completion: nil)
    }

    func showSendTokens(
        from view: AssetListViewProtocol?,
        state: AssetListInitState,
        transferCompletion: @escaping TransferCompletionClosure
    ) {
        showAssetsSelection(for: .send, from: view, state: state, transferCompletion: transferCompletion)
    }

    func showRecieveTokens(from view: AssetListViewProtocol?, state: AssetListInitState) {
        showAssetsSelection(for: .receive, from: view, state: state, transferCompletion: nil)
    }

    func showBuyTokens(
        from view: AssetListViewProtocol?,
        state: AssetListInitState
    ) {
        showAssetsSelection(for: .buy, from: view, state: state, transferCompletion: nil)
    }

    private func showAssetsSelection(
        for operation: TokenOperation,
        from view: AssetListViewProtocol?,
        state: AssetListInitState,
        transferCompletion: TransferCompletionClosure?
    ) {
        guard let assetsSearchView = AssetOperationViewFactory.createView(
            for: state,
            operation: operation,
            transferCompletion: transferCompletion
        ) else {
            return
        }

        let navigationController = NovaNavigationController(
            rootViewController: assetsSearchView.controller
        )

        view?.controller.present(navigationController, animated: true, completion: nil)
    }

    func showNfts(from view: AssetListViewProtocol?) {
        guard let nftListView = NftListViewFactory.createView() else {
            return
        }

        nftListView.controller.hidesBottomBarWhenPushed = true
        view?.controller.navigationController?.pushViewController(nftListView.controller, animated: true)
    }

    func showBalanceBreakdown(
        from view: AssetListViewProtocol?,
        prices: [ChainAssetId: PriceData],
        balances: [AssetBalance],
        chains: [ChainModel.Id: ChainModel],
        locks: [AssetLock],
        crowdloans: [ChainModel.Id: [CrowdloanContributionData]]
    ) {
        guard let viewController = LocksViewFactory.createView(input:
            .init(
                prices: prices,
                balances: balances,
                chains: chains,
                locks: locks,
                crowdloans: crowdloans
            )) else {
            return
        }

        let factory = ModalSheetPresentationFactory(configuration: ModalSheetPresentationConfiguration.nova)
        viewController.controller.modalTransitioningFactory = factory
        viewController.controller.modalPresentationStyle = .custom

        view?.controller.present(viewController.controller, animated: true)
    }

    func showWalletConnect(from view: AssetListViewProtocol?) {
        guard
            let walletConnectView = WalletConnectSessionsViewFactory.createViewForCurrentWallet(
                with: dappMediator
            ) else {
            return
        }

        walletConnectView.controller.hidesBottomBarWhenPushed = true
        view?.controller.navigationController?.pushViewController(walletConnectView.controller, animated: true)
    }
}
