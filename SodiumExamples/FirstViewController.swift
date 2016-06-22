//
//  FirstViewController.swift
//  Example 2.1
//
//  Created by Andrew Bradnan on 5/20/16.
//  Copyright © 2016 Whirlygig Ventures. All rights reserved.
//

import UIKit
import Sodium
import SodiumCocoa

class FirstViewController: UIViewController {
    
    let refs = MemReferences()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //let vc = Example21()
        let vc = Example24()
        vc.refs = self.refs
        dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue(), {
            self.presentViewController(vc, animated: true, completion: nil)
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

