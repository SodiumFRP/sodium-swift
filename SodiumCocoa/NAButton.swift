//
//  NAButton.swift
//  SodiumCoca
//
//  Created by Andrew Bradnan on 5/20/16.
//  Copyright © 2016 Whirlygig Ventures. All rights reserved.
//

import UIKit
import Sodium

public class NAButton : UIButton {
    public var clicked = StreamSink<Unit>()
    
    public convenience init(_ text: String) {
        self.init(type: .System)
        
        self.titleLabel!.text = text
        self.layer.borderColor = UIColor.redColor().CGColor
        self.sizeToFit()
        self.addTarget(self, action: #selector(NAButton.onclicked), forControlEvents: .TouchUpInside)
    }
    
    init(type: UIButtonType) {
        super.init(frame: CGRectMake(0,0,10,10))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("NAButton deinit")
    }

    func onclicked() {
        clicked.send(Unit.value)
    }
    
}
