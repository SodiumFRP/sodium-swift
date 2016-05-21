//
//  Example2.1.swift
//  Sodium
//
//  Created by Andrew Bradnan on 5/20/16.
//  Copyright © 2016 Whirlygig Ventures. All rights reserved.
//

import UIKit
import Sodium
import SodiumCocoa

class Example21 : UIViewController {
 
    deinit {
        print ("Example21 deinit")
    }
    
    override func viewDidLoad() {
        let clear = NAButton("Clear")
        clear.frame = CGRectMake(50,30,100,30)
        clear.setTitle("clear", forState: .Normal)
        clear.setTitleColor(UIColor.blueColor(), forState: .Normal)
        self.view.addSubview(clear)
        
        let sClearIt = clear.clicked.map { _ in "" }
        //let sClearIt = Stream<String>()
        let text = NATextField(s: sClearIt, text: "Hello")
        text.text = "Hello2"
        text.frame = CGRectMake(10,50,100,20)
        
        self.view.addSubview(text)
        
        
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