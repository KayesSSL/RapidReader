import Foundation

enum TransactionParserError: Error {
    case invalidBlockSize
    case failedToParseBlock
}

struct TransactionParser {
    /// Only include transactions with timestamp after this cutoff
    private static var cutoffDate: Date {
        var dateComponents = DateComponents()
        dateComponents.year = 2020
        dateComponents.month = 1
        dateComponents.day = 1
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0
        dateComponents.timeZone = TimeZone(identifier: "Asia/Dhaka")
        return Calendar(identifier: .gregorian).date(from: dateComponents)!
    }
    
    private static func isValidTransaction(_ transaction: Transaction) -> Bool {
        return transaction.timestamp > cutoffDate
    }
    
    /// Parse a single transaction block. Throws if block is not exactly 16 bytes or parsing fails.
    static func parseTransactionBlock(_ block: Data) throws -> Transaction {
        guard block.count == 16 else {
            throw TransactionParserError.invalidBlockSize
        }
        
        let fixedHeader = block.prefix(4)
        let fixedHeaderStr = ByteParser.toHexString(fixedHeader)
        
        guard let timestampValue = ByteParser.extractInt24BigEndian(block, offset: 4) else {
            throw TransactionParserError.failedToParseBlock
        }
        let transactionTypeBytes = block.subdata(in: 6..<8)
        let transactionType = ByteParser.toHexString(transactionTypeBytes)
        
        guard let fromStationCode = ByteParser.extractByte(block, offset: 8),
              let toStationCode = ByteParser.extractByte(block, offset: 10),
              let balance = ByteParser.extractInt24(block, offset: 11) else {
            throw TransactionParserError.failedToParseBlock
        }
        
        let trailingBytes = block.subdata(in: 14..<16)
        let trailing = ByteParser.toHexString(trailingBytes)
        
        let timestamp = TimestampService.decodeTimestamp(timestampValue)
        let fromStation = StationService.getStationName(fromStationCode)
        let toStation = StationService.getStationName(toStationCode)
        
        return Transaction(
            fixedHeader: fixedHeaderStr,
            timestamp: timestamp,
            transactionType: transactionType,
            fromStation: fromStation,
            toStation: toStation,
            balance: balance,
            trailing: trailing
        )
    }
    
    /// Parse a response containing a sequence of transaction blocks.
    static func parseTransactionResponse(_ response: Data) -> [Transaction] {
        var transactions: [Transaction] = []
        if response.count < 13 { return transactions }
        
        let statusFlag1 = response[10]
        let statusFlag2 = response[11]
        if statusFlag1 != 0x00 || statusFlag2 != 0x00 { return transactions }
        
        let numBlocks = Int(response[12]) & 0xFF
        let blockData = response.subdata(in: 13..<response.count)
        let blockSize = 16
        if blockData.count < numBlocks * blockSize { return transactions }
        
        for i in 0..<numBlocks {
            let offset = i * blockSize
            let block = blockData.subdata(in: offset..<(offset + blockSize))
            do {
                let transaction = try parseTransactionBlock(block)
                if isValidTransaction(transaction) {
                    transactions.append(transaction)
                }
            } catch {
                // Ignore this block and continue
                continue
            }
        }
        return transactions
    }
}
