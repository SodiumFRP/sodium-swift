//
//  NAButton.swift
//  SodiumCoca
//
//  Created by Andrew Bradnan on 5/20/16.
//  Copyright © 2016 Whirlygig Ventures. All rights reserved.
//

import UIKit
import SodiumSwift
import SwiftCommon

public class NAButton : UIButton {
    public typealias Title = (String, UIControlState)
    private let empty : Title = ("", .Normal)

    private var enabledListener: Listener?
    public var enabledState = AnyCell<Bool>(Cell<Bool>(value: false)) {
        didSet {
            self.enabledListener = enabledState.listen { enabled in
                gui {
                    // we set disabled text color in init
                    self.enabled = enabled
                }
            }
        }
    }

    private var hiddenListener: Listener?
    public var hiddenState = AnyCell<Bool>(Cell<Bool>(value: false)) {
        didSet {
            self.hiddenListener = hiddenState.listen { hidden in
                gui { self.hidden = hidden }
            }
        }
    }

    let refs: MemReferences?
    private var txtListener: Listener?

    public let clicked: StreamSink<Unit>
    public var text: Title {
        get {
            return textCell.sample()
        }
        set(value) {
            Transaction.run { trans in
                Transaction.cantBeInSend()
                self.textCell.stream().send(trans, a: value)
            }
        }
    }
    
    public var textCell: Cell<Title> {
        didSet {
            self.txtListener = Operational.updates(textCell).listen(self.refs) { txt in
                gui { self.setTitle(txt.0, forState: txt.1) }
            }
        }
    }
    
    
    public convenience init(_ txt: Cell<Title>, refs: MemReferences? = nil) {
        self.init(type: .System, refs: refs)
        
        self.textCell = txt
        self.layer.borderColor = UIColor.redColor().CGColor
        self.sizeToFit()
        self.addTarget(self, action: #selector(NAButton.onclicked), forControlEvents: .TouchUpInside)
    }
    
    public convenience init(_ text: String, refs: MemReferences? = nil) {
        self.init(type: .System, refs: refs)
        
        self.titleLabel!.text = text
        self.layer.borderColor = UIColor.redColor().CGColor
        self.sizeToFit()
        self.addTarget(self, action: #selector(NAButton.onclicked), forControlEvents: .TouchUpInside)
    }
    
    init(type: UIButtonType, refs: MemReferences? = nil) {
        self.clicked = StreamSink<Unit>(refs: refs)
        self.refs = refs
        if let r = self.refs {
            r.addRef()
        }
        self.textCell = Cell<Title>(value: empty, refs: refs)
        super.init(frame: CGRectMake(0,0,10,10))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.refs = nil
        self.clicked = StreamSink<Unit>(refs: nil)
        self.textCell = Cell<Title>(value: empty, refs: nil)
        super.init(coder: aDecoder)
     
        self.setTitleColor(UIColor.lightTextColor(), forState: .Disabled)
        self.addTarget(self, action: #selector(NAButton.onclicked), forControlEvents: .TouchUpInside)
    }
    
    deinit {
        if let r = self.refs { r.release() }
        print("NAButton deinit")
    }
    
    func onclicked() {
        clicked.send(Unit.value)
    }
    
}
