import Foundation
import SubstrateSdk
import RobinHood

protocol ReferendumsOperationFactoryProtocol {
    func fetchAllReferendumsWrapper(
        from connection: JSONRPCEngine,
        runtimeProvider: RuntimeProviderProtocol
    ) -> CompoundOperationWrapper<[ReferendumLocal]>

    func fetchAccountVotesWrapper(
        for accountId: AccountId,
        from connection: JSONRPCEngine,
        runtimeProvider: RuntimeProviderProtocol,
        blockHash: Data?
    ) -> CompoundOperationWrapper<ReferendumAccountVotingDistribution>

    func fetchVotersWrapper(
        for referendumIndex: ReferendumIdLocal,
        from connection: JSONRPCEngine,
        runtimeProvider: RuntimeProviderProtocol
    ) -> CompoundOperationWrapper<[ReferendumVoterLocal]>
}

protocol ReferendumActionOperationFactoryProtocol {
    func fetchActionWrapper(
        for referendum: ReferendumLocal,
        connection: JSONRPCEngine,
        runtimeProvider: RuntimeProviderProtocol
    ) -> CompoundOperationWrapper<ReferendumActionLocal>
}

protocol GovernanceLockStateFactoryProtocol {
    func calculateLockStateDiff(
        for trackVotes: ReferendumTracksVotingDistribution,
        newVote: ReferendumNewVote?,
        from connection: JSONRPCEngine,
        runtimeProvider: RuntimeProviderProtocol,
        blockHash: Data?
    ) -> CompoundOperationWrapper<GovernanceLockStateDiff>
}
