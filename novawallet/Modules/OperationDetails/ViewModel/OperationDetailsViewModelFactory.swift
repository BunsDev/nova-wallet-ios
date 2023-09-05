import Foundation
import SoraFoundation
import BigInt

protocol OperationDetailsViewModelFactoryProtocol {
    func createViewModel(
        from model: OperationDetailsModel,
        chainAsset: ChainAsset,
        locale: Locale
    ) -> OperationDetailsViewModel
}

final class OperationDetailsViewModelFactory {
    let balanceViewModelFactory: BalanceViewModelFactoryProtocol
    let feeViewModelFactory: BalanceViewModelFactoryProtocol?
    let dateFormatter: LocalizableResource<DateFormatter>
    let networkViewModelFactory: NetworkViewModelFactoryProtocol
    let displayAddressViewModelFactory: DisplayAddressViewModelFactoryProtocol
    let quantityFormatter: LocalizableResource<NumberFormatter>
    lazy var poolIconFactory: NominationPoolsIconFactoryProtocol = NominationPoolsIconFactory()

    init(
        balanceViewModelFactory: BalanceViewModelFactoryProtocol,
        feeViewModelFactory: BalanceViewModelFactoryProtocol?,
        dateFormatter: LocalizableResource<DateFormatter> = DateFormatter.txDetails,
        networkViewModelFactory: NetworkViewModelFactoryProtocol = NetworkViewModelFactory(),
        displayAddressViewModelFactory: DisplayAddressViewModelFactoryProtocol =
            DisplayAddressViewModelFactory(),
        quantityFormatter: LocalizableResource<NumberFormatter> =
            NumberFormatter.quantity.localizableResource()
    ) {
        self.balanceViewModelFactory = balanceViewModelFactory
        self.feeViewModelFactory = feeViewModelFactory
        self.dateFormatter = dateFormatter
        self.networkViewModelFactory = networkViewModelFactory
        self.displayAddressViewModelFactory = displayAddressViewModelFactory
        self.quantityFormatter = quantityFormatter
    }

    private func createIconViewModel(
        from model: OperationDetailsModel.OperationData,
        assetInfo: AssetBalanceDisplayInfo
    ) -> ImageViewModelProtocol? {
        switch model {
        case let .transfer(data):
            let image = data.outgoing ?
                R.image.iconOutgoingTransfer()! :
                R.image.iconIncomingTransfer()!

            return StaticImageViewModel(image: image)
        case .reward, .slash, .poolReward, .poolSlash:
            let image = R.image.iconRewardOperation()!
            return StaticImageViewModel(image: image)
        case .extrinsic, .contract:
            if let url = assetInfo.icon {
                return RemoteImageViewModel(url: url)
            } else {
                return nil
            }
        }
    }

    private func createAmount(
        from model: OperationDetailsModel.OperationData,
        assetInfo: AssetBalanceDisplayInfo,
        locale: Locale
    ) -> BalanceViewModelProtocol? {
        let amount: BigUInt
        let priceData: PriceData?
        let prefix: String

        switch model {
        case let .transfer(model):
            amount = model.amount
            priceData = model.amountPriceData
            prefix = model.outgoing ? "−" : "+"
        case let .extrinsic(model):
            amount = model.fee
            priceData = model.feePriceData
            prefix = "−"
        case let .contract(model):
            amount = model.fee
            priceData = model.feePriceData
            prefix = "−"
        case let .reward(model):
            amount = model.amount
            priceData = model.priceData
            prefix = "+"
        case let .slash(model):
            amount = model.amount
            priceData = model.priceData
            prefix = "−"
        case let .poolReward(model):
            amount = model.amount
            priceData = model.priceData
            prefix = "+"
        case let .poolSlash(model):
            amount = model.amount
            priceData = model.priceData
            prefix = "-"
        }

        return Decimal.fromSubstrateAmount(
            amount,
            precision: assetInfo.assetPrecision
        ).map { amountDecimal in
            let amountViewModel = balanceViewModelFactory.balanceFromPrice(
                amountDecimal,
                priceData: priceData
            ).value(for: locale)

            return BalanceViewModel(amount: prefix + amountViewModel.amount, price: amountViewModel.price)
        }
    }

    private func createContractViewModel(
        from model: OperationContractCallModel
    ) -> OperationContractCallViewModel {
        let sender = displayAddressViewModelFactory.createViewModel(from: model.sender)
        let contract = displayAddressViewModelFactory.createViewModel(from: model.contract)

        return .init(
            sender: sender,
            transactionHash: model.txHash,
            contract: contract,
            functionName: model.functionName
        )
    }

    private func createTransferViewModel(
        from model: OperationTransferModel,
        feeAssetInfo: AssetBalanceDisplayInfo,
        locale: Locale
    ) -> OperationTransferViewModel {
        let fee = Decimal.fromSubstrateAmount(
            model.fee,
            precision: feeAssetInfo.assetPrecision
        ).map { amount in
            let viewModelFactory = feeViewModelFactory ?? balanceViewModelFactory
            return viewModelFactory.balanceFromPrice(
                amount,
                priceData: model.feePriceData
            ).value(for: locale)
        }
        let sender = displayAddressViewModelFactory.createViewModel(from: model.sender)
        let recepient = displayAddressViewModelFactory.createViewModel(from: model.receiver)

        return OperationTransferViewModel(
            fee: fee,
            isOutgoing: model.outgoing,
            sender: sender,
            recepient: recepient,
            transactionHash: model.txHash
        )
    }

    private func createExtrinsicViewModel(
        from model: OperationExtrinsicModel
    ) -> OperationExtrinsicViewModel {
        let sender = displayAddressViewModelFactory.createViewModel(from: model.sender)

        return OperationExtrinsicViewModel(
            sender: sender,
            transactionHash: model.txHash,
            module: model.module.displayModule,
            call: model.call.displayCall
        )
    }

    private func createRewardOrSlashViewModel(
        from model: OperationRewardOrSlashModel,
        locale: Locale
    ) -> OperationRewardOrSlashViewModel {
        let validatorViewModel = model.validator.map { model in
            displayAddressViewModelFactory.createViewModel(from: model)
        }

        let eraString: String? = model.era.map { era in
            if let eraString = quantityFormatter.value(for: locale)
                .string(from: NSNumber(value: era)) {
                return R.string.localizable.commonEraFormat(
                    eraString,
                    preferredLanguages: locale.rLanguages
                )
            } else {
                return ""
            }
        }

        return OperationRewardOrSlashViewModel(
            eventId: model.eventId,
            validator: validatorViewModel,
            era: eraString
        )
    }

    private func createPoolRewardOrSlashViewModel(
        from model: OperationPoolRewardOrSlashModel,
        chainAsset: ChainAsset,
        locale _: Locale
    ) -> OperationPoolRewardOrSlashViewModel {
        guard let pool = model.pool else {
            return .init(eventId: model.eventId, pool: nil)
        }

        let poolViewModel = displayAddressViewModelFactory.createViewModel(
            from: pool,
            chainAsset: chainAsset
        )

        return OperationPoolRewardOrSlashViewModel(eventId: model.eventId, pool: poolViewModel)
    }

    private func createContentViewModel(
        from data: OperationDetailsModel.OperationData,
        chainAsset: ChainAsset,
        locale: Locale
    ) -> OperationDetailsViewModel.ContentViewModel {
        let feeAssetInfo = chainAsset.assetDisplayInfo
        switch data {
        case let .transfer(model):
            let viewModel = createTransferViewModel(
                from: model,
                feeAssetInfo: feeAssetInfo,
                locale: locale
            )

            return .transfer(viewModel)
        case let .extrinsic(model):
            let viewModel = createExtrinsicViewModel(from: model)
            return .extrinsic(viewModel)
        case let .reward(model):
            let viewModel = createRewardOrSlashViewModel(
                from: model,
                locale: locale
            )

            return .reward(viewModel)
        case let .slash(model):
            let viewModel = createRewardOrSlashViewModel(
                from: model,
                locale: locale
            )

            return .slash(viewModel)
        case let .contract(model):
            let viewModel = createContractViewModel(from: model)
            return .contract(viewModel)
        case let .poolReward(model):
            let viewModel = createPoolRewardOrSlashViewModel(
                from: model,
                chainAsset: chainAsset,
                locale: locale
            )
            return .poolReward(viewModel)
        case let .poolSlash(model):
            let viewModel = createPoolRewardOrSlashViewModel(
                from: model,
                chainAsset: chainAsset,
                locale: locale
            )
            return .poolReward(viewModel)
        }
    }
}

extension OperationDetailsViewModelFactory: OperationDetailsViewModelFactoryProtocol {
    func createViewModel(
        from model: OperationDetailsModel,
        chainAsset: ChainAsset,
        locale: Locale
    ) -> OperationDetailsViewModel {
        let timeString = dateFormatter.value(for: locale).string(from: model.time)
        let networkViewModel = networkViewModelFactory.createViewModel(from: chainAsset.chain)

        let assetInfo = chainAsset.assetDisplayInfo

        let contentViewModel = createContentViewModel(
            from: model.operation,
            chainAsset: chainAsset,
            locale: locale
        )

        let amount = createAmount(from: model.operation, assetInfo: assetInfo, locale: locale)

        let iconViewModel = createIconViewModel(from: model.operation, assetInfo: assetInfo)

        return OperationDetailsViewModel(
            time: timeString,
            status: model.status,
            amount: amount,
            networkViewModel: networkViewModel,
            iconViewModel: iconViewModel,
            content: contentViewModel
        )
    }
}
