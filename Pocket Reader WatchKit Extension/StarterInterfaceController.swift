//
//  StarterInterfaceController.swift
//  Pocket Reader WatchKit Extension
//
//  Created by Алексей Пархоменко on 18.04.2020.
//  Copyright © 2020 Алексей Пархоменко. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class StarterInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var table: WKInterfaceTable!
    
    func setupTable() {
        let pickedBooks = UserSettings.userBooks
        table.setNumberOfRows(pickedBooks.count, withRowType: "myBookRow")
        
        for (index, book) in pickedBooks.enumerated() {
            if let rowController = table.rowController(at: index) as? MyBookRowController {
                rowController.nameLabel.setText(book.name)
                let book = pickedBooks[index]
                rowController.book = book
            }
        }
    }

    override func willActivate() {
        super.willActivate()
        setupTable()
        sendSelectedBooksToPhone()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }
    
    func sendSelectedBooksToPhone() {
        if WCSession.isSupported() {
            let session = WCSession.default
            let pickedBooks = UserSettings.userBooks.map { (book) in
                return book.representation
            }
            
            do {
                let dict: [String: Any] = ["books": pickedBooks]
                try session.updateApplicationContext(dict)
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    
    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        if let rowController = table.rowController(at: rowIndex) as? MyBookRowController {
            return rowController.book
        }
        return nil
    }
    
    @IBAction func deleteAll() {
        UserSettings.userBooks = []
        sendSelectedBooksToPhone()
        setupTable()
    }
}
