//
//  NAButton.swift
//  SodiumCoca
//
//  Created by Andrew Bradnan on 5/20/16.
//  Copyright © 2016 Whirlygig Ventures. All rights reserved.
//

import UIKit
import SodiumSwift

public class NAButton : UIButton {
    private var txtListener: Listener?

    public var txt: Cell<String> {
        didSet{
            self.txtListener = Operational.updates(txt).listen ({ txt in
                gui() {
                    self.setTitle(txt, forState: .Normal)
                }
            }, refs: self.refs)
        }
    }
    
    let refs: MemReferences?
    public let clicked: StreamSink<Unit>
    
    public convenience init(_ txt: Cell<String>, refs: MemReferences? = nil) {
        self.init(type: .System, refs: refs)
        
        self.txt = txt
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
        self.txt = Cell<String>(value: "", refs: nil)
        super.init(frame: CGRectMake(0,0,10,10))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.refs = nil
        self.clicked = StreamSink<Unit>(refs: nil)
        self.txt = Cell<String>(value: "", refs: nil)
        super.init(coder: aDecoder)
        
        self.layer.borderColor = UIColor.redColor().CGColor
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
