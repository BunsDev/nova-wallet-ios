import BigInt
protocol ReferendumVoteSetupViewProtocol: ControllerBackedProtocol {}

protocol ReferendumVoteSetupPresenterProtocol: AnyObject {
    func setup()
}

protocol ReferendumVoteSetupInteractorInputProtocol: ReferendumVoteInteractorInputProtocol {
    func refreshLockDiff(
        for votes: [ReferendumIdLocal: ReferendumAccountVoteLocal],
        newVote: ReferendumNewVote?,
        blockHash: Data?
    )

    func refreshBlockTime()
}

protocol ReferendumVoteSetupInteractorOutputProtocol: ReferendumVoteInteractorOutputProtocol {
    func didReceiveLockStateDiff(_ stateDiff: GovernanceLockStateDiff)
    func didReceiveAccountVotes(
        _ votes: CallbackStorageSubscriptionResult<[ReferendumIdLocal: ReferendumAccountVoteLocal]>
    )
    func didReceiveBlockNumber(_ number: BlockNumber)
    func didReceiveBlockTime(_ blockTime: BlockTime)
    func didReceiveError(_ error: ReferendumVoteSetupInteractorError)
}

protocol ReferendumVoteSetupWireframeProtocol: AnyObject {}
