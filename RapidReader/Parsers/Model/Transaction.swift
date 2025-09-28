import Foundation

enum TransactionType: String, Codable {
    case commute = "Commute"
    case balanceUpdate = "BalanceUpdate"
    case unknown = "Unknown"
    
    init(rawValue: String) {
        switch rawValue.lowercased() {
        case "commute": self = .commute
        case "balanceupdate": self = .balanceUpdate
        default: self = .unknown
        }
    }
}

struct Transaction: Codable {
    let fixedHeader: String
    let timestamp: Date
    let transactionType: String
    let fromStation: String
    let toStation: String
    let balance: Int
    let trailing: String
}

struct TransactionWithAmount: Codable {
    let transaction: Transaction
    let amount: Int?
}
