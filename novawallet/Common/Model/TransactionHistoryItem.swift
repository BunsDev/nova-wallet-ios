import Foundation
import RobinHood
import BigInt

enum TransactionHistoryItemSource: Int16, Codable {
    case substrate = 0
    case evmAsset = 1
    case evmNative = 2
}

struct TransactionHistoryItem: Codable {
    enum CodingKeys: String, CodingKey {
        case identifier
        case source
        case chainId
        case assetId
        case sender
        case receiver
        case amountInPlank
        case status
        case txHash
        case timestamp
        case fee
        case blockNumber
        case txIndex
        case callPath
        case call
    }

    enum Status: Int16, Codable {
        case pending
        case success
        case failed
    }

    let identifier: String
    let source: TransactionHistoryItemSource
    let chainId: String
    let assetId: UInt32
    let sender: String
    let receiver: String?
    let amountInPlank: String?
    let status: Status
    let txHash: String
    let timestamp: Int64
    let fee: String?
    let blockNumber: UInt64?
    let txIndex: UInt16?
    let callPath: CallCodingPath
    let call: Data?
}

extension TransactionHistoryItem: Identifiable {
    static func createIdentifier(from txHash: String, source: TransactionHistoryItemSource) -> String {
        txHash + " - " + String(source.rawValue)
    }
}

extension TransactionHistoryItem {
    var amountInPlankIntOrZero: BigUInt {
        amountInPlank.map { BigUInt($0) ?? 0 } ?? 0
    }

    var feeInPlankIntOrZero: BigUInt {
        fee.map { BigUInt($0) ?? 0 } ?? 0
    }

    var isIdentifierMatchesLocal: Bool {
        identifier == TransactionHistoryItem.createIdentifier(from: txHash, source: source)
    }
}

extension TransactionHistoryItemSource {
    init(assetTypeString: String?) {
        let assetType: AssetType? = assetTypeString.flatMap { .init(rawValue: $0) }
        switch assetType {
        case .statemine, .orml, .none, .equilibrium:
            self = .substrate
        case .evmAsset:
            self = .evmAsset
        case .evmNative:
            self = .evmNative
        }
    }
}
