/**
 # NATableViewCell.swift
## Sodium
 
 - Author: Andrew Bradnan
 - Date: 7/5/16
 */

import Foundation
import SodiumSwift
import SwiftCommon

public class NATableViewCell : UITableViewCell {
    
    private var hiddenListener: Listener?
    public var hiddenState: AnyCell<Bool> = AnyCell(Cell<Bool>(value: false)) {
        didSet {
            self.hiddenListener = Operational.updates(hiddenState).listen { hidden in
                gui { self.hidden = hidden }
            }
        }
    }
 
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}