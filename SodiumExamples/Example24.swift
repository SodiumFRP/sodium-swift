/**
 # Example24.swift
## Sodium
 
 - Author: Andrew Bradnan
 - Date: 6/1/16
 - Copyright: Copyright © 2016 Whirlygig Ventures. All rights reserved.
 */


import Sodium
import SodiumCocoa
import UIKit

class Example24 : UIViewController {
    
    var refs: MemReferences?
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.whiteColor()

        let first = CGRectMake(10,0,100,30)
        let second = CGRectMake(10,30,100,30)
        
        let onegai = NAButton("Onegai shimasu")
        onegai.frame = first
        let thanks = NAButton("Thank you")
        thanks.frame = second
        let sOnegai = onegai.clicked.map{ _ in "Onegai shimasu" }
        let sThanks = thanks.clicked.map{ _ in "Thank you" }
        let sCanned = sOnegai.orElse(sThanks)
        let txt = NATextField(s: sCanned, text: "")
        
        self.view.addSubview(onegai)
        self.view.addSubview(thanks)
        self.view.addSubview(txt)
        
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