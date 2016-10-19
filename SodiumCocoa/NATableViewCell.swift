/**
 # NATableViewCell.swift
## Sodium
 
 - Author: Andrew Bradnan
 - Date: 7/5/16
 */

import Foundation
import SodiumSwift
import SwiftCommon

open class NATableViewCell : UITableViewCell {
    
    fileprivate var hiddenListener: Listener?
    open var hiddenState: AnyCell<Bool> = AnyCell(Cell<Bool>(value: false)) {
        didSet {
            self.hiddenListener = hiddenState.listen { hidden in
                gui {
                    self.isHidden = hidden
                }
            }
        }
    }
 
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
