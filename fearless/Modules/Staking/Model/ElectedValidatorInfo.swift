import Foundation
import IrohaCrypto

struct ElectedValidatorInfo {
    let address: String
    let nominators: [NominatorInfo]
    let totalStake: Decimal
    let ownStake: Decimal
    let comission: Decimal
    let identity: AccountIdentity?
    let stakeReturnPer: Decimal
    let hasSlashes: Bool
    let oversubscribed: Bool

    var hasIdentity: Bool {
        identity != nil
    }
}

struct NominatorInfo {
    let address: String
    let stake: Decimal
}

extension ElectedValidatorInfo {
    init(validator: EraValidatorInfo,
         identity: AccountIdentity?,
         stakeReturnPer: Decimal,
         hasSlashes: Bool,
         maxNominatorsAllowed: UInt32,
         addressType: SNAddressType) throws {

        self.hasSlashes = hasSlashes
        self.identity = identity
        self.stakeReturnPer = stakeReturnPer

        let addressFactory = SS58AddressFactory()

        address = try addressFactory.addressFromAccountId(data: validator.accountId, type: addressType)
        nominators = try validator.exposure.others.map { nominator in
            let nominatorAddress = try addressFactory.addressFromAccountId(data: nominator.who,
                                                                           type: addressType)
            let stake = Decimal.fromSubstrateAmount(nominator.value, precision: addressType.precision) ?? 0.0
            return NominatorInfo(address: nominatorAddress, stake: stake)
        }

        self.oversubscribed = nominators.count >= maxNominatorsAllowed

        totalStake = Decimal.fromSubstrateAmount(validator.exposure.total, precision: addressType.precision) ?? 0.0
        ownStake = Decimal.fromSubstrateAmount(validator.exposure.own, precision: addressType.precision) ?? 0.0
        comission = Decimal.fromSubstratePerbill(value: validator.prefs.commission) ?? 0.0
    }
}
