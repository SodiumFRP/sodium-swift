/**
 # NALabel.swift
 ##  Sodium
 
 - Author: Andrew Bradnan
 - Date: 5/31/16
 - Copyright:   Copyright © 2016 Whirlygig Ventures. All rights reserved.
 */

import UIKit
import SodiumSwift

public class NALabel : UILabel {
    var txt: Cell<String>
    
    public init(txt: Cell<String>, refs: MemReferences? = nil ) {
        self.txt = txt //Cell<String>(value: text, refs: refs)
        super.init(frame: CGRectZero)
        
        l = Operational.updates(txt).listen ({ txt in
                if NSThread.isMainThread() {
                    self.text = txt
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.text = txt
                    }
                }
            }, refs: refs)
        
        // Set the text at the end of the transaction so SLabel works
        // with CellLoops.
        Transaction.post{ _ in
            dispatch_async(dispatch_get_main_queue()) {
                self.text = self.txt.sample()
            }
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    private var l: Listener?
    
    public func removeNotify() {
        l?.unlisten();
    }
}


