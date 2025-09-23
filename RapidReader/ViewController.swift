//
//  ViewController.swift
//  RapidReader
//
//  Created by Imrul Kayes on 9/22/25.
//

import UIKit
import CoreNFC
import SwiftUI

class ViewController: UIViewController, SendNFCDataDelegate {
    var nfcManager: NFCService?
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var transactionTableView: UITableView!
    
    var transactions: [Transaction]?
    var displayTransactions: [DisplayTransaction] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.transactionTableView.delegate = self
        self.transactionTableView.dataSource = self
        
        nfcManager = NFCService()
        nfcManager?.delegate = self
    }
    
    @IBAction func startScanningButtonTapped(_ sender: UIButton) {
        if self.transactions != nil {
            self.transactions = nil
            self.displayTransactions = []
            self.transactionTableView.reloadData()
        }
        nfcManager?.startScan()
    }
    
    func sendTransactions(transactions: [Transaction]) {
        self.resultLabel.text = "৳ \(transactions.first?.balance ?? 0)"
        self.transactions = transactions
        
        let darr = self.generateDisplayTransactions(transactions: transactions)
        self.displayTransactions = darr
        for tx in darr {
            print("\(tx.title) \(tx.amount)")
        }
        self.transactionTableView.reloadData()
    }

    func generateDisplayTransactions(transactions: [Transaction]) -> [DisplayTransaction] {
        guard transactions.count > 1 else { return [] }
        var result: [DisplayTransaction] = []
        for i in 0..<(transactions.count - 1) {
            let current = transactions[i]
            let next = transactions[i + 1]
            let currBal = current.balance
            let nextBal = next.balance
            let delta = currBal - nextBal //nextBal - currBal
            
            if delta < 0 {
                // Fare paid
                let title = "\(current.fromStation) → \(current.toStation)"
                result.append(DisplayTransaction(date: current.timestamp, title: title, amount: delta))
            } else if delta > 0 {
                // Top-up
                result.append(DisplayTransaction(date: current.timestamp, title: "Balance Update", amount: delta))
            }
            // Ignore zero-difference (no event)
        }
        return result
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.displayTransactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath) as? TransactionCell else {
            fatalError("Could not dequeue TransactionCell")
        }
        let displayTx = displayTransactions[indexPath.row]
        
        // Set title (commuterLbl)
        cell.commuterLbl.text = displayTx.title
        
        // Set date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        cell.dateLbl.text = dateFormatter.string(from: displayTx.date)
        
        // Set amount (show minus for fare, plus for top-up)
        cell.amountLbl.text = "৳ \(displayTx.amount)"
        cell.amountLbl.textColor = displayTx.amount < 0 ? .systemRed : .label // Red for fare, default for top-up
        
        return cell
    }
}

struct DisplayTransaction {
    let date: Date
    let title: String         // either "Balance Update" or "From -> To"
    let amount: Int           // positive for top-up, negative for fare
}
