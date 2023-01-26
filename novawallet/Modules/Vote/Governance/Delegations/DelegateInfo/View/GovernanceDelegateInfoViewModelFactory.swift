import Foundation
import SoraFoundation
import BigInt

protocol GovernanceDelegateInfoViewModelFactoryProtocol {
    func createStatsViewModel(
        from details: GovernanceDelegateDetails,
        chain: ChainModel,
        locale: Locale
    ) -> GovernanceDelegateInfoViewModel.Stats

    func createStatsViewModel(
        using stats: GovernanceDelegateStats,
        chain: ChainModel,
        locale: Locale
    ) -> GovernanceDelegateInfoViewModel.Stats

    func createDelegateViewModel(
        from address: AccountAddress,
        metadata: GovernanceDelegateMetadataRemote?,
        identity: AccountIdentity?,
        locale: Locale
    ) -> GovernanceDelegateInfoViewModel.Delegate
}

final class GovernanceDelegateInfoViewModelFactory {
    struct StatsModel {
        let delegationsCount: UInt64?
        let delegatedVotes: BigUInt?
        let recentVotes: UInt64?
        let allVotes: UInt64?
    }

    let quantityFormatter: LocalizableResource<NumberFormatter>
    let stringDisplayFactory: ReferendumDisplayStringFactoryProtocol
    let displayAddressViewModelFactory: DisplayAddressViewModelFactoryProtocol
    let recentVotesInDays: Int

    init(
        stringDisplayFactory: ReferendumDisplayStringFactoryProtocol = ReferendumDisplayStringFactory(),
        quantityFormatter: LocalizableResource<NumberFormatter> = NumberFormatter.quantity.localizableResource(),
        displayAddressViewModelFactory: DisplayAddressViewModelFactoryProtocol = DisplayAddressViewModelFactory(),
        recentVotesInDays: Int = GovernanceDelegationConstants.recentVotesInDays
    ) {
        self.stringDisplayFactory = stringDisplayFactory
        self.quantityFormatter = quantityFormatter
        self.displayAddressViewModelFactory = displayAddressViewModelFactory
        self.recentVotesInDays = recentVotesInDays
    }

    private func formatNonzeroQuantity(_ quantity: UInt64?, locale: Locale) -> String? {
        guard let quantity = quantity, quantity > 0 else {
            return nil
        }

        return quantityFormatter.value(for: locale).string(from: NSNumber(value: quantity))
    }

    private func formatNonzeroVotes(_ votes: BigUInt?, chain: ChainModel, locale: Locale) -> String? {
        guard let votes = votes, votes > 0 else {
            return nil
        }

        return stringDisplayFactory.createVotes(from: votes, chain: chain, locale: locale)
    }

    private func formatRecentVotesCount(
        _ votes: UInt64?,
        locale: Locale
    ) -> GovernanceDelegateInfoViewModel.RecentVotes? {
        guard
            let votesString = formatNonzeroQuantity(votes, locale: locale),
            let period = formatNonzeroQuantity(UInt64(recentVotesInDays), locale: locale) else {
            return nil
        }

        return .init(period: period, value: votesString)
    }

    private func createInternalStatsViewModel(
        from model: StatsModel,
        chain: ChainModel,
        locale: Locale
    ) -> GovernanceDelegateInfoViewModel.Stats {
        .init(
            delegations: formatNonzeroQuantity(model.delegationsCount, locale: locale),
            delegatedVotes: formatNonzeroVotes(model.delegatedVotes, chain: chain, locale: locale),
            recentVotes: formatRecentVotesCount(model.recentVotes, locale: locale),
            allVotes: formatNonzeroQuantity(model.allVotes, locale: locale)
        )
    }
}

extension GovernanceDelegateInfoViewModelFactory: GovernanceDelegateInfoViewModelFactoryProtocol {
    func createStatsViewModel(
        from details: GovernanceDelegateDetails,
        chain: ChainModel,
        locale: Locale
    ) -> GovernanceDelegateInfoViewModel.Stats {
        let model = StatsModel(
            delegationsCount: details.stats.delegationsCount,
            delegatedVotes: details.stats.delegatedVotes,
            recentVotes: details.stats.recentVotes,
            allVotes: details.allVotes
        )

        return createInternalStatsViewModel(from: model, chain: chain, locale: locale)
    }

    func createStatsViewModel(
        using stats: GovernanceDelegateStats,
        chain: ChainModel,
        locale: Locale
    ) -> GovernanceDelegateInfoViewModel.Stats {
        let model = StatsModel(
            delegationsCount: stats.delegationsCount,
            delegatedVotes: stats.delegatedVotes,
            recentVotes: stats.recentVotes,
            allVotes: nil
        )

        return createInternalStatsViewModel(from: model, chain: chain, locale: locale)
    }

    func createDelegateViewModel(
        from address: AccountAddress,
        metadata: GovernanceDelegateMetadataRemote?,
        identity: AccountIdentity?,
        locale: Locale
    ) -> GovernanceDelegateInfoViewModel.Delegate {
        let addressViewModel = displayAddressViewModelFactory.createViewModel(
            from: address,
            name: identity?.displayName ?? metadata?.name,
            iconUrl: metadata?.image
        )

        let type: GovernanceDelegateTypeView.Model = metadata.map {
            $0.isOrganization ? .organization : .individual
        }

        let hasFullDescription = !(metadata?.longDescription ?? "").isEmpty

        return .init(
            addressViewModel: addressViewModel,
            details: metadata?.shortDescription,
            type: type,
            hasFullDescription: hasFullDescription
        )
    }
}
