import Foundation
import SoraFoundation
import SoraUI

final class GovernanceAddDelegationTracksWireframe: GovernanceSelectTracksWireframe,
    GovAddDelegationTracksWireframeProtocol {
    let state: GovernanceSharedState
    let delegateId: AccountId

    init(state: GovernanceSharedState, delegate: AccountId) {
        self.state = state
        delegateId = delegate
    }

    func presentUnavailableTracks(
        from _: ControllerBackedProtocol?,
        votedTracks _: [GovernanceTrackInfoLocal],
        delegatedTracks _: [GovernanceTrackInfoLocal]
    ) {
        // TODO: #860pmdtgx
    }

    func showRemoveVotesRequest(
        from view: ControllerBackedProtocol?,
        tracksCount: Int,
        skipClosure: @escaping () -> Void,
        removeVotesClosure: @escaping () -> Void
    ) {
        let title = LocalizableResource { locale in
            R.string.localizable.govRemoveVotesAskTitle(preferredLanguages: locale.rLanguages)
        }

        let message = LocalizableResource { locale in
            let tracksString = R.string.localizable.commonInTracks(
                format: tracksCount,
                preferredLanguages: locale.rLanguages
            )

            return R.string.localizable.govRemoveVotesAskDetails(
                tracksString,
                preferredLanguages: locale.rLanguages
            )
        }

        let skipAction = MessageSheetAction(
            title: LocalizableResource { locale in
                R.string.localizable.commonSkip(preferredLanguages: locale.rLanguages)
            },
            handler: skipClosure
        )

        let removeVotesAction = MessageSheetAction(
            title: LocalizableResource { locale in
                R.string.localizable.govRemoveVotes(preferredLanguages: locale.rLanguages)
            },
            handler: removeVotesClosure
        )

        let viewModel = TitleDetailsSheetViewModel(
            title: title,
            message: message,
            mainAction: removeVotesAction,
            secondaryAction: skipAction
        )

        let bottomSheet = TitleDetailsSheetViewFactory.createView(
            from: viewModel,
            allowsSwipeDown: false,
            preferredContentSize: CGSize(width: 0, height: 200)
        )

        let factory = ModalSheetPresentationFactory(configuration: ModalSheetPresentationConfiguration.fearless)

        bottomSheet.controller.modalTransitioningFactory = factory
        bottomSheet.controller.modalPresentationStyle = .custom

        view?.controller.present(bottomSheet.controller, animated: true)
    }

    func showRemoveVotes(
        from _: ControllerBackedProtocol?,
        trackIds _: Set<TrackIdLocal>
    ) {
        // TODO: #860pmdtgt
    }
}
