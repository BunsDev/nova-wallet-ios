import Foundation
import BigInt
import SoraFoundation

final class StakingUnbondConfirmPresenter {
    weak var view: StakingUnbondConfirmViewProtocol?
    let wireframe: StakingUnbondConfirmWireframeProtocol
    let interactor: StakingUnbondConfirmInteractorInputProtocol

    let inputAmount: Decimal
    let confirmViewModelFactory: StakingUnbondConfirmViewModelFactoryProtocol
    let balanceViewModelFactory: BalanceViewModelFactoryProtocol
    let dataValidatingFactory: StakingDataValidatingFactoryProtocol
    let assetInfo: AssetBalanceDisplayInfo
    let explorers: [ChainModel.Explorer]?
    let logger: LoggerProtocol?

    private var bonded: Decimal?
    private var balance: Decimal?
    private var minimalBalance: Decimal?
    private var minNominatorBonded: Decimal?
    private var nomination: Nomination?
    private var priceData: PriceData?
    private var fee: Decimal?
    private var controller: MetaChainAccountResponse?
    private var stashItem: StashItem?
    private var payee: RewardDestinationArg?
    private var stakingDuration: StakingDuration?
    private var bondingDuration: UInt32?

    private var shouldResetRewardDestination: Bool {
        switch payee {
        case .staked:
            if let bonded = bonded, let minimalBalance = minimalBalance {
                return bonded - inputAmount < minimalBalance
            } else {
                return false
            }
        default:
            return false
        }
    }

    private var shouldChill: Bool {
        if let bonded = bonded, let minNominatorBonded = minNominatorBonded, nomination != nil {
            return bonded - inputAmount < minNominatorBonded
        } else {
            return false
        }
    }

    private func provideFeeViewModel() {
        if let fee = fee {
            let feeViewModel = balanceViewModelFactory.balanceFromPrice(fee, priceData: priceData)
            view?.didReceiveFee(viewModel: feeViewModel)
        } else {
            view?.didReceiveFee(viewModel: nil)
        }
    }

    private func provideAmountViewModel() {
        let viewModel = balanceViewModelFactory.lockingAmountFromPrice(inputAmount, priceData: priceData)

        view?.didReceiveAmount(viewModel: viewModel)
    }

    private func provideShouldResetRewardsDestination() {
        view?.didSetShouldResetRewardsDestination(value: shouldResetRewardDestination)
    }

    private func provideConfirmationViewModel() {
        guard let controller = controller else {
            return
        }

        do {
            let viewModel = try confirmViewModelFactory.createUnbondConfirmViewModel(
                controllerItem: controller
            )

            view?.didReceiveConfirmation(viewModel: viewModel)
        } catch {
            logger?.error("Did receive view model factory error: \(error)")
        }
    }

    private func provideBondingDuration() {
        guard let erasPerDay = stakingDuration?.era.intervalsInDay else {
            return
        }

        let daysCount = bondingDuration.map { erasPerDay > 0 ? Int($0) / erasPerDay : 0 }
        let bondingDuration: LocalizableResource<String> = LocalizableResource { locale in
            guard let daysCount = daysCount else {
                return ""
            }

            return R.string.localizable.commonDaysFormat(
                format: daysCount,
                preferredLanguages: locale.rLanguages
            )
        }

        view?.didReceiveBonding(duration: bondingDuration)
    }

    func refreshFeeIfNeeded() {
        guard fee == nil, controller != nil, payee != nil, bonded != nil, minimalBalance != nil else {
            return
        }

        interactor.estimateFee(
            for: inputAmount,
            resettingRewardDestination: shouldResetRewardDestination,
            chilling: shouldChill
        )
    }

    init(
        interactor: StakingUnbondConfirmInteractorInputProtocol,
        wireframe: StakingUnbondConfirmWireframeProtocol,
        inputAmount: Decimal,
        confirmViewModelFactory: StakingUnbondConfirmViewModelFactoryProtocol,
        balanceViewModelFactory: BalanceViewModelFactoryProtocol,
        dataValidatingFactory: StakingDataValidatingFactoryProtocol,
        assetInfo: AssetBalanceDisplayInfo,
        explorers: [ChainModel.Explorer]?,
        logger: LoggerProtocol? = nil
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.inputAmount = inputAmount
        self.confirmViewModelFactory = confirmViewModelFactory
        self.balanceViewModelFactory = balanceViewModelFactory
        self.dataValidatingFactory = dataValidatingFactory
        self.assetInfo = assetInfo
        self.explorers = explorers
        self.logger = logger
    }
}

extension StakingUnbondConfirmPresenter: StakingUnbondConfirmPresenterProtocol {
    func setup() {
        provideConfirmationViewModel()
        provideAmountViewModel()
        provideFeeViewModel()
        provideShouldResetRewardsDestination()

        interactor.setup()
    }

    func confirm() {
        let locale = view?.localizationManager?.selectedLocale ?? Locale.current
        DataValidationRunner(validators: [
            dataValidatingFactory.canUnbond(amount: inputAmount, bonded: bonded, locale: locale),

            dataValidatingFactory.has(fee: fee, locale: locale, onError: { [weak self] in
                self?.refreshFeeIfNeeded()
            }),

            dataValidatingFactory.canPayFee(balance: balance, fee: fee, asset: assetInfo, locale: locale),

            dataValidatingFactory.has(
                controller: controller?.chainAccount,
                for: stashItem?.controller ?? "",
                locale: locale
            )
        ]).runValidation { [weak self] in
            guard let strongSelf = self else {
                return
            }

            strongSelf.view?.didStartLoading()

            strongSelf.interactor.submit(
                for: strongSelf.inputAmount,
                resettingRewardDestination: strongSelf.shouldResetRewardDestination,
                chilling: strongSelf.shouldChill
            )
        }
    }

    func selectAccount() {
        guard let view = view, let address = stashItem?.controller else { return }

        let locale = view.localizationManager?.selectedLocale ?? Locale.current

        wireframe.presentAccountOptions(
            from: view,
            address: address,
            explorers: explorers,
            locale: locale
        )
    }
}

extension StakingUnbondConfirmPresenter: StakingUnbondConfirmInteractorOutputProtocol {
    func didReceiveAccountInfo(result: Result<AccountInfo?, Error>) {
        switch result {
        case let .success(accountInfo):
            let amountInPlank = accountInfo?.data.available ?? 0

            balance = Decimal.fromSubstrateAmount(
                amountInPlank,
                precision: assetInfo.assetPrecision
            )
        case let .failure(error):
            logger?.error("Account Info subscription error: \(error)")
        }
    }

    func didReceiveStakingLedger(result: Result<StakingLedger?, Error>) {
        switch result {
        case let .success(stakingLedger):
            if let stakingLedger = stakingLedger {
                bonded = Decimal.fromSubstrateAmount(
                    stakingLedger.active,
                    precision: assetInfo.assetPrecision
                )
            } else {
                bonded = nil
            }

            provideAmountViewModel()
            provideShouldResetRewardsDestination()
            refreshFeeIfNeeded()
        case let .failure(error):
            logger?.error("Staking ledger subscription error: \(error)")
        }
    }

    func didReceivePriceData(result: Result<PriceData?, Error>) {
        switch result {
        case let .success(priceData):
            self.priceData = priceData

            provideAmountViewModel()
            provideFeeViewModel()
            provideConfirmationViewModel()
        case let .failure(error):
            logger?.error("Price data subscription error: \(error)")
        }
    }

    func didReceiveFee(result: Result<RuntimeDispatchInfo, Error>) {
        switch result {
        case let .success(dispatchInfo):
            if let fee = BigUInt(dispatchInfo.fee) {
                self.fee = Decimal.fromSubstrateAmount(fee, precision: assetInfo.assetPrecision)
            }

            provideFeeViewModel()
        case let .failure(error):
            logger?.error("Did receive fee error: \(error)")
        }
    }

    func didReceiveExistentialDeposit(result: Result<BigUInt, Error>) {
        switch result {
        case let .success(minimalBalance):
            self.minimalBalance = Decimal.fromSubstrateAmount(
                minimalBalance,
                precision: assetInfo.assetPrecision
            )

            provideAmountViewModel()
            provideShouldResetRewardsDestination()
            refreshFeeIfNeeded()
        case let .failure(error):
            logger?.error("Minimal balance fetching error: \(error)")
        }
    }

    func didReceiveController(result: Result<MetaChainAccountResponse?, Error>) {
        switch result {
        case let .success(accountItem):
            if let accountItem = accountItem {
                controller = accountItem
            }

            provideConfirmationViewModel()
            refreshFeeIfNeeded()
        case let .failure(error):
            logger?.error("Did receive controller account error: \(error)")
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

    func didReceivePayee(result: Result<RewardDestinationArg?, Error>) {
        switch result {
        case let .success(payee):
            self.payee = payee

            refreshFeeIfNeeded()

            provideConfirmationViewModel()
            provideShouldResetRewardsDestination()
        case let .failure(error):
            logger?.error("Did receive payee item error: \(error)")
        }
    }

    func didReceiveMinBonded(result: Result<BigUInt?, Error>) {
        switch result {
        case let .success(minNominatorBonded):
            if let minNominatorBonded = minNominatorBonded {
                self.minNominatorBonded = Decimal.fromSubstrateAmount(
                    minNominatorBonded,
                    precision: assetInfo.assetPrecision
                )
            } else {
                self.minNominatorBonded = nil
            }

            provideShouldResetRewardsDestination()
            refreshFeeIfNeeded()
        case let .failure(error):
            logger?.error("Did receive min bonded error: \(error)")
        }
    }

    func didReceiveNomination(result: Result<Nomination?, Error>) {
        switch result {
        case let .success(nomination):
            self.nomination = nomination
            refreshFeeIfNeeded()
        case let .failure(error):
            logger?.error("Did receive nomination error: \(error)")
        }
    }

    func didSubmitUnbonding(result: Result<String, Error>) {
        view?.didStopLoading()

        guard let view = view else {
            return
        }

        switch result {
        case .success:
            wireframe.complete(from: view)
        case .failure:
            wireframe.presentExtrinsicFailed(from: view, locale: view.localizationManager?.selectedLocale)
        }
    }

    func didReceiveBondingDuration(result: Result<UInt32, Error>) {
        switch result {
        case let .success(bondingDuration):
            self.bondingDuration = bondingDuration
            provideBondingDuration()
        case let .failure(error):
            logger?.error("Boding duration fetching error: \(error)")
        }
    }

    func didReceiveStakingDuration(result: Result<StakingDuration, Error>) {
        switch result {
        case let .success(duration):
            stakingDuration = duration
            provideBondingDuration()
        case let .failure(error):
            logger?.error("Did receive stash item error: \(error)")
        }
    }
}
