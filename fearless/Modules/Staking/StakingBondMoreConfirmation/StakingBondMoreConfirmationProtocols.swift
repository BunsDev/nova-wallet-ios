import SoraFoundation
import CommonWallet
import BigInt

protocol StakingBondMoreConfirmationViewProtocol: ControllerBackedProtocol, Localizable, LoadableViewProtocol {
    func didReceiveConfirmation(viewModel: StakingBondMoreConfirmViewModel)
    func didReceiveAsset(viewModel: LocalizableResource<AssetBalanceViewModelProtocol>)
    func didReceiveFee(viewModel: LocalizableResource<BalanceViewModelProtocol>?)
}

protocol StakingBondMoreConfirmationPresenterProtocol: AnyObject {
    func setup()
    func confirm()
    func selectAccount()
}

protocol StakingBondMoreConfirmationInteractorInputProtocol: AnyObject {
    func setup()
    func submit(for amount: Decimal)
    func estimateFee(for amount: Decimal)
}

protocol StakingBondMoreConfirmationOutputProtocol: AnyObject {
    func didReceiveElectionStatus(result: Result<ElectionStatus?, Error>)
    func didReceiveAccountInfo(result: Result<DyAccountInfo?, Error>)
    func didReceivePriceData(result: Result<PriceData?, Error>)
    func didReceiveFee(result: Result<RuntimeDispatchInfo, Error>)
    func didReceiveStash(result: Result<AccountItem?, Error>)
    func didReceiveStashItem(result: Result<StashItem?, Error>)

    func didSubmitBonding(result: Result<String, Error>)
}

protocol StakingBondMoreConfirmationWireframeProtocol: AlertPresentable, ErrorPresentable,
    StakingErrorPresentable,
    AddressOptionsPresentable {
    func complete(from view: StakingBondMoreConfirmationViewProtocol?)
}