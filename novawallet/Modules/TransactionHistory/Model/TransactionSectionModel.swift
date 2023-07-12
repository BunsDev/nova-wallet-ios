import UIKit

struct TransactionSectionModel: Hashable {
    let title: String
    let date: Date
    let items: [TransactionItemViewModel]
}

struct TransactionItemViewModel: Hashable {
    static func == (lhs: TransactionItemViewModel, rhs: TransactionItemViewModel) -> Bool {
        lhs.identifier == rhs.identifier &&
            lhs.timestamp == rhs.timestamp &&
            lhs.title == rhs.title &&
            lhs.subtitle == rhs.subtitle &&
            lhs.amountDetails == rhs.amountDetails &&
            lhs.amount == rhs.amount &&
            lhs.type == rhs.type &&
            lhs.status == rhs.status
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(type)
    }

    let identifier: String
    let timestamp: Int64
    let title: String
    let subtitle: String
    let amount: String
    let amountDetails: String
    let type: TransactionType
    let status: TransactionHistoryItem.Status
    let imageViewModel: ImageViewModelProtocol?
}
