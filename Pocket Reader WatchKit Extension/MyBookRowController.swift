//
//  MyBookRowController.swift
//  Pocket Reader WatchKit Extension
//
//  Created by Алексей Пархоменко on 18.04.2020.
//  Copyright © 2020 Алексей Пархоменко. All rights reserved.
//

import WatchKit

class MyBookRowController: NSObject {
    
    var book: BookItem! {
        didSet {
            nameLabel.setText(book.name)
        }
    }
    
    @IBOutlet weak var nameLabel: WKInterfaceLabel!
}
