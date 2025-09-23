//
//  NFCService.swift
//  RapidReader
//
//  Created by Imrul Kayes on 9/22/25.
//

import CoreNFC

protocol SendNFCDataDelegate: AnyObject {
    func sendTransactions(transactions: [Transaction])
}

final class NFCService: NSObject, NFCTagReaderSessionDelegate {
    
    weak var delegate: SendNFCDataDelegate?
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("Active session")
    }
    
    private var session: NFCTagReaderSession?

    func startScan() {
        guard NFCTagReaderSession.readingAvailable else {
            print("NFC not available on this device")
            return
        }

        session = NFCTagReaderSession(
            pollingOption: [.iso18092], // FeliCa only for transaction reading
            delegate: self,
            queue: nil
        )
        session?.alertMessage = "Hold your iPhone near the card."
        session?.begin()
    }

    // MARK: - NFCTagReaderSessionDelegate

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print("Session invalidated: \(error.localizedDescription)")
        self.session = nil
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let first = tags.first else { return }

        if tags.count > 1 {
            session.alertMessage = "More than one tag detected. Present a single tag."
            session.restartPolling()
            return
        }

        session.connect(to: first) { [weak self] err in
            guard err == nil else {
                print("Connect error: \(err!.localizedDescription)")
                session.invalidate(errorMessage: "Could not connect to the tag.")
                return
            }
            
            // Only proceed if FeliCa
            guard case .feliCa(let felicaTag) = first else {
                session.invalidate(errorMessage: "Unsupported tag type.")
                return
            }
            
            // Prepare to read blocks (example: 10 most recent, service code 0x220F)
            let serviceCode: Data = Data([0x0F, 0x22]) // 0x220F little-endian for iOS
            let serviceCodeList = [serviceCode]
            let numberOfBlocks = 10
            var blockList: [Data] = []
            for i in 0..<numberOfBlocks {
                // Control byte 0x80 means 1-block read, next byte is block number
                blockList.append(Data([0x80, UInt8(i)]))
            }
            
            felicaTag.readWithoutEncryption(serviceCodeList: serviceCodeList, blockList: blockList) { statusFlag1, statusFlag2, dataList, error in
                defer { session.invalidate() }
                if let error = error {
                    print("Read blocks error: \(error.localizedDescription)")
                    return
                }
                // Print each raw 16-byte block for inspection
                for (i, block) in dataList.enumerated() {
                    let bal = ByteParser.extractInt24(block, offset: 11) ?? -1
                    print("Block \(i):", ByteParser.toHexString(block), "Balance:", bal)
                }
                
                // Each element in dataList is a 16-byte Data block.
                let transactions = dataList.compactMap { try? TransactionParser.parseTransactionBlock($0) }
                
                DispatchQueue.main.async {
                    self?.delegate?.sendTransactions(transactions: transactions)
                }
            }
        }
    }
}

