import Foundation
import BigInt

extension ParachainStaking {
    struct CommonData {
        let account: MetaChainAccountResponse?
        let chainAsset: ChainAsset?
        let balance: AssetBalance?
        let price: PriceData?
        let networkInfo: ParachainStaking.NetworkInfo?
        let stakingDuration: ParachainStakingDuration?
        let calculatorEngine: ParaStakingRewardCalculatorEngineProtocol?
        let collatorsInfo: SelectedRoundCollators?
        let blockNumber: BlockNumber?
        let roundInfo: ParachainStaking.RoundInfo?
        let totalReward: TotalRewardItem?

        var roundCountdown: RoundCountdown? {
            if
                let blockNumber = blockNumber,
                let roundInfo = roundInfo,
                let stakingDuration = stakingDuration {
                return RoundCountdown(
                    roundInfo: roundInfo,
                    blockTime: stakingDuration.block,
                    currentBlock: blockNumber,
                    createdAtDate: Date()
                )
            } else {
                return nil
            }
        }
    }
}

extension ParachainStaking.CommonData {
    static var empty: ParachainStaking.CommonData {
        ParachainStaking.CommonData(
            account: nil,
            chainAsset: nil,
            balance: nil,
            price: nil,
            networkInfo: nil,
            stakingDuration: nil,
            calculatorEngine: nil,
            collatorsInfo: nil,
            blockNumber: nil,
            roundInfo: nil,
            totalReward: nil
        )
    }

    func byReplacing(account: MetaChainAccountResponse?) -> ParachainStaking.CommonData {
        ParachainStaking.CommonData(
            account: account,
            chainAsset: chainAsset,
            balance: balance,
            price: price,
            networkInfo: networkInfo,
            stakingDuration: stakingDuration,
            calculatorEngine: calculatorEngine,
            collatorsInfo: collatorsInfo,
            blockNumber: blockNumber,
            roundInfo: roundInfo,
            totalReward: totalReward
        )
    }

    func byReplacing(chainAsset: ChainAsset?) -> ParachainStaking.CommonData {
        ParachainStaking.CommonData(
            account: account,
            chainAsset: chainAsset,
            balance: balance,
            price: price,
            networkInfo: networkInfo,
            stakingDuration: stakingDuration,
            calculatorEngine: calculatorEngine,
            collatorsInfo: collatorsInfo,
            blockNumber: blockNumber,
            roundInfo: roundInfo,
            totalReward: totalReward
        )
    }

    func byReplacing(balance: AssetBalance?) -> ParachainStaking.CommonData {
        ParachainStaking.CommonData(
            account: account,
            chainAsset: chainAsset,
            balance: balance,
            price: price,
            networkInfo: networkInfo,
            stakingDuration: stakingDuration,
            calculatorEngine: calculatorEngine,
            collatorsInfo: collatorsInfo,
            blockNumber: blockNumber,
            roundInfo: roundInfo,
            totalReward: totalReward
        )
    }

    func byReplacing(price: PriceData?) -> ParachainStaking.CommonData {
        ParachainStaking.CommonData(
            account: account,
            chainAsset: chainAsset,
            balance: balance,
            price: price,
            networkInfo: networkInfo,
            stakingDuration: stakingDuration,
            calculatorEngine: calculatorEngine,
            collatorsInfo: collatorsInfo,
            blockNumber: blockNumber,
            roundInfo: roundInfo,
            totalReward: totalReward
        )
    }

    func byReplacing(networkInfo: ParachainStaking.NetworkInfo?) -> ParachainStaking.CommonData {
        ParachainStaking.CommonData(
            account: account,
            chainAsset: chainAsset,
            balance: balance,
            price: price,
            networkInfo: networkInfo,
            stakingDuration: stakingDuration,
            calculatorEngine: calculatorEngine,
            collatorsInfo: collatorsInfo,
            blockNumber: blockNumber,
            roundInfo: roundInfo,
            totalReward: totalReward
        )
    }

    func byReplacing(
        calculatorEngine: ParaStakingRewardCalculatorEngineProtocol?
    ) -> ParachainStaking.CommonData {
        ParachainStaking.CommonData(
            account: account,
            chainAsset: chainAsset,
            balance: balance,
            price: price,
            networkInfo: networkInfo,
            stakingDuration: stakingDuration,
            calculatorEngine: calculatorEngine,
            collatorsInfo: collatorsInfo,
            blockNumber: blockNumber,
            roundInfo: roundInfo,
            totalReward: totalReward
        )
    }

    func byReplacing(
        collatorsInfo: SelectedRoundCollators?
    ) -> ParachainStaking.CommonData {
        ParachainStaking.CommonData(
            account: account,
            chainAsset: chainAsset,
            balance: balance,
            price: price,
            networkInfo: networkInfo,
            stakingDuration: stakingDuration,
            calculatorEngine: calculatorEngine,
            collatorsInfo: collatorsInfo,
            blockNumber: blockNumber,
            roundInfo: roundInfo,
            totalReward: totalReward
        )
    }

    func byReplacing(
        stakingDuration: ParachainStakingDuration?
    ) -> ParachainStaking.CommonData {
        ParachainStaking.CommonData(
            account: account,
            chainAsset: chainAsset,
            balance: balance,
            price: price,
            networkInfo: networkInfo,
            stakingDuration: stakingDuration,
            calculatorEngine: calculatorEngine,
            collatorsInfo: collatorsInfo,
            blockNumber: blockNumber,
            roundInfo: roundInfo,
            totalReward: totalReward
        )
    }

    func byReplacing(
        blockNumber: BlockNumber?
    ) -> ParachainStaking.CommonData {
        ParachainStaking.CommonData(
            account: account,
            chainAsset: chainAsset,
            balance: balance,
            price: price,
            networkInfo: networkInfo,
            stakingDuration: stakingDuration,
            calculatorEngine: calculatorEngine,
            collatorsInfo: collatorsInfo,
            blockNumber: blockNumber,
            roundInfo: roundInfo,
            totalReward: totalReward
        )
    }

    func byReplacing(
        roundInfo: ParachainStaking.RoundInfo?
    ) -> ParachainStaking.CommonData {
        ParachainStaking.CommonData(
            account: account,
            chainAsset: chainAsset,
            balance: balance,
            price: price,
            networkInfo: networkInfo,
            stakingDuration: stakingDuration,
            calculatorEngine: calculatorEngine,
            collatorsInfo: collatorsInfo,
            blockNumber: blockNumber,
            roundInfo: roundInfo,
            totalReward: totalReward
        )
    }

    func byReplacing(
        totalReward: TotalRewardItem?
    ) -> ParachainStaking.CommonData {
        ParachainStaking.CommonData(
            account: account,
            chainAsset: chainAsset,
            balance: balance,
            price: price,
            networkInfo: networkInfo,
            stakingDuration: stakingDuration,
            calculatorEngine: calculatorEngine,
            collatorsInfo: collatorsInfo,
            blockNumber: blockNumber,
            roundInfo: roundInfo,
            totalReward: totalReward
        )
    }
}
