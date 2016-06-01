/**
 # Example22.swift
 ##  Sodium
 
 - Author: Andrew Bradnan
 - Date: 5/31/16
 - Copyright:   Copyright © 2016 Whirlygig Ventures. All rights reserved.
 */

import UIKit
import SodiumCocoa
import Sodium

class Example22 : UIViewController {
    
    var refs: MemReferences?

    override func viewDidLoad() {
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        let msg  = NATextField(text: "hello", refs: refs)
        msg.frame = CGRectMake(10,0,100,30)
        self.view.addSubview(msg)
        
        let reversed = msg.stext.map{ String($0.characters.reverse()) }
        
        let lbl = NALabel(txt: reversed, refs: refs)
        lbl.frame = CGRectMake(10,30,100,30)

        self.view.addSubview(lbl)
        
        let close = UIButton()
        close.frame = CGRectMake(50,130,100,30)
        close.setTitle("close", forState: .Normal)
        close.setTitleColor(UIColor.blueColor(), forState: .Normal)
        close.addTarget(self, action: #selector(doclose), forControlEvents: .TouchUpInside)
        self.view.addSubview(close)
    }

    func doclose() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}