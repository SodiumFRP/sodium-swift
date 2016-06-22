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
    let refs: MemReferences?
    public let clicked: StreamSink<Unit>
    
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
        super.init(frame: CGRectMake(0,0,10,10))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let r = self.refs { r.release() }
        print("NAButton deinit")
    }

    func onclicked() {
        clicked.send(Unit.value)
    }
    
}
