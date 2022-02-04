import Foundation
import RobinHood
import SubstrateSdk
import BigInt

protocol WalletListViewProtocol: ControllerBackedProtocol {
    func didReceiveHeader(viewModel: WalletListHeaderViewModel)
    func didReceiveGroups(state: WalletListGroupState)
    func didCompleteRefreshing()
}

protocol WalletListPresenterProtocol: AnyObject {
    func setup()
    func selectWallet()
    func selectAsset(for chainAssetId: ChainAssetId)
    func refresh()
    func presentSettings()
}

protocol WalletListInteractorInputProtocol: AnyObject {
    func setup()
    func refresh()
}

protocol WalletListInteractorOutputProtocol: AnyObject {
    func didReceive(genericAccountId: AccountId, name: String)
    func didReceiveChainModelChanges(_ changes: [DataProviderChange<ChainModel>])
    func didReceiveBalance(results: [ChainAssetId: Result<BigUInt?, Error>])
    func didReceivePrices(result: Result<[ChainAssetId: PriceData], Error>?)
    func didReceive(state: WebSocketEngine.State, for chainId: ChainModel.Id)
    func didChange(name: String)
    func didReceive(hidesZeroBalances: Bool)
}

protocol WalletListWireframeProtocol: AnyObject {
    func showWalletList(from view: WalletListViewProtocol?)
    func showAssetDetails(from view: WalletListViewProtocol?, chain: ChainModel, asset: AssetModel)
    func showAssetsManage(from view: WalletListViewProtocol?)
}
