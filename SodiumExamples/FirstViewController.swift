//
//  FirstViewController.swift
//  Example 2.1
//
//  Created by Andrew Bradnan on 5/20/16.
//  Copyright © 2016 Whirlygig Ventures. All rights reserved.
//

import UIKit
import SodiumCocoa

class FirstViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue(), {
            self.presentViewController(Example21(), animated: true, completion: nil)
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

