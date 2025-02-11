import Foundation
import BigInt

final class StakingBondMoreConfirmationPresenter {
    weak var view: StakingBondMoreConfirmationViewProtocol?
    let wireframe: StakingBondMoreConfirmationWireframeProtocol
    let interactor: StakingBondMoreConfirmationInteractorInputProtocol

    let inputAmount: Decimal
    let confirmViewModelFactory: StakingBondMoreConfirmViewModelFactoryProtocol
    let balanceViewModelFactory: BalanceViewModelFactoryProtocol
    let dataValidatingFactory: StakingDataValidatingFactoryProtocol
    let assetInfo: AssetBalanceDisplayInfo
    let chain: ChainModel
    let logger: LoggerProtocol?

    private var freeBalance: Decimal?
    private var transferableBalance: Decimal?
    private var bondBalance: Decimal?
    private var priceData: PriceData?
    private var fee: Decimal?
    private var stashAccount: MetaChainAccountResponse?
    private var stashItem: StashItem?

    private var availableAmountToStake: Decimal? {
        let free = freeBalance ?? 0
        let bond = bondBalance ?? 0

        return free >= bond ? free - bond : 0
    }

    init(
        interactor: StakingBondMoreConfirmationInteractorInputProtocol,
        wireframe: StakingBondMoreConfirmationWireframeProtocol,
        inputAmount: Decimal,
        confirmViewModelFactory: StakingBondMoreConfirmViewModelFactoryProtocol,
        balanceViewModelFactory: BalanceViewModelFactoryProtocol,
        dataValidatingFactory: StakingDataValidatingFactoryProtocol,
        assetInfo: AssetBalanceDisplayInfo,
        chain: ChainModel,
        logger: LoggerProtocol? = nil
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.inputAmount = inputAmount
        self.confirmViewModelFactory = confirmViewModelFactory
        self.balanceViewModelFactory = balanceViewModelFactory
        self.dataValidatingFactory = dataValidatingFactory
        self.assetInfo = assetInfo
        self.chain = chain
        self.logger = logger
    }

    private func provideFeeViewModel() {
        if let fee = fee {
            let feeViewModel = balanceViewModelFactory.balanceFromPrice(fee, priceData: priceData)
            view?.didReceiveFee(viewModel: feeViewModel)
        } else {
            view?.didReceiveFee(viewModel: nil)
        }
    }

    private func provideAssetViewModel() {
        let viewModel = balanceViewModelFactory.lockingAmountFromPrice(inputAmount, priceData: priceData)

        view?.didReceiveAmount(viewModel: viewModel)
    }

    private func provideConfirmationViewModel() {
        guard let stashAccount = stashAccount else {
            return
        }

        do {
            let viewModel = try confirmViewModelFactory.createViewModel(stash: stashAccount)

            view?.didReceiveConfirmation(viewModel: viewModel)
        } catch {
            logger?.error("Did receive view model factory error: \(error)")
        }
    }

    func refreshFeeIfNeeded() {
        guard fee == nil else {
            return
        }

        interactor.estimateFee(for: inputAmount)
    }
}

extension StakingBondMoreConfirmationPresenter: StakingBondMoreConfirmationPresenterProtocol {
    func setup() {
        provideConfirmationViewModel()
        provideAssetViewModel()
        provideFeeViewModel()

        interactor.setup()
    }

    func confirm() {
        let locale = view?.localizationManager?.selectedLocale ?? Locale.current
        DataValidationRunner(validators: [
            dataValidatingFactory.has(fee: fee, locale: locale, onError: { [weak self] in
                self?.refreshFeeIfNeeded()
            }),

            dataValidatingFactory.canSpendAmount(
                balance: availableAmountToStake,
                spendingAmount: inputAmount,
                locale: locale
            ),

            dataValidatingFactory.canPayFee(
                balance: transferableBalance,
                fee: fee,
                asset: assetInfo,
                locale: locale
            ),

            dataValidatingFactory.canPayFeeSpendingAmount(
                balance: availableAmountToStake,
                fee: fee,
                spendingAmount: inputAmount,
                asset: assetInfo,
                locale: locale
            ),

            dataValidatingFactory.has(
                stash: stashAccount?.chainAccount,
                for: stashItem?.stash ?? "",
                locale: locale
            )
        ]).runValidation { [weak self] in
            guard let strongSelf = self else {
                return
            }

            strongSelf.view?.didStartLoading()

            strongSelf.interactor.submit(for: strongSelf.inputAmount)
        }
    }

    func selectAccount() {
        guard let view = view, let address = stashItem?.controller else { return }

        let locale = view.localizationManager?.selectedLocale ?? Locale.current

        wireframe.presentAccountOptions(
            from: view,
            address: address,
            chain: chain,
            locale: locale
        )
    }
}

extension StakingBondMoreConfirmationPresenter: StakingBondMoreConfirmationOutputProtocol {
    func didReceiveAccountBalance(result: Result<AssetBalance?, Error>) {
        switch result {
        case let .success(assetBalance):
            if let assetBalance = assetBalance {
                freeBalance = Decimal.fromSubstrateAmount(
                    assetBalance.freeInPlank,
                    precision: assetInfo.assetPrecision
                )

                transferableBalance = Decimal.fromSubstrateAmount(
                    assetBalance.transferable,
                    precision: assetInfo.assetPrecision
                )
            } else {
                freeBalance = nil
                transferableBalance = nil
            }

            provideAssetViewModel()
            provideConfirmationViewModel()
        case let .failure(error):
            logger?.error("Did receive account info error: \(error)")
        }
    }

    func didReceiveStakingLedger(result: Result<StakingLedger?, Error>) {
        switch result {
        case let .success(ledger):
            if let ledger = ledger {
                bondBalance = Decimal.fromSubstrateAmount(
                    ledger.total,
                    precision: assetInfo.assetPrecision
                )
            } else {
                bondBalance = nil
            }
        case let .failure(error):
            logger?.error("Did receive staking ledger error: \(error)")
        }
    }

    func didReceivePriceData(result: Result<PriceData?, Error>) {
        switch result {
        case let .success(priceData):
            self.priceData = priceData

            provideAssetViewModel()
            provideFeeViewModel()
            provideConfirmationViewModel()
        case let .failure(error):
            logger?.error("Did receive price data error: \(error)")
        }
    }

    func didReceiveFee(result: Result<RuntimeDispatchInfo, Error>) {
        switch result {
        case let .success(dispatchInfo):
            if let feeValue = BigUInt(dispatchInfo.fee) {
                fee = Decimal.fromSubstrateAmount(feeValue, precision: assetInfo.assetPrecision)
            } else {
                fee = nil
            }

            provideFeeViewModel()
        case let .failure(error):
            logger?.error("Did receive fee error: \(error)")
        }
    }

    func didReceiveStash(result: Result<MetaChainAccountResponse?, Error>) {
        switch result {
        case let .success(stashAccount):
            self.stashAccount = stashAccount

            provideConfirmationViewModel()

            refreshFeeIfNeeded()
        case let .failure(error):
            logger?.error("Did receive stash account error: \(error)")
        }
    }

    func didReceiveStashItem(result: Result<StashItem?, Error>) {
        switch result {
        case let .success(stashItem):
            self.stashItem = stashItem
        case let .failure(error):
            logger?.error("Did receive stash item error: \(error)")
        }
    }

    func didSubmitBonding(result: Result<String, Error>) {
        view?.didStopLoading()

        guard let view = view else {
            return
        }

        switch result {
        case .success:
            wireframe.complete(from: view)
        case let .failure(error):
            if error.isWatchOnlySigning {
                wireframe.presentDismissingNoSigningView(from: view)
            } else if error.isHardwareWalletSigningCancelled {
                return
            } else {
                wireframe.presentExtrinsicFailed(from: view, locale: view.localizationManager?.selectedLocale)
            }
        }
    }
}
