//
//  SodiumCocoaTests.swift
//  SodiumCocoaTests
//
//  Created by Andrew Bradnan on 5/20/16.
//  Copyright © 2016 Whirlygig Ventures. All rights reserved.
//

import XCTest
import Sodium
import SodiumCocoa

class SodiumCocoaTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testRefs() {
        let refs = MemReferences()
        doTest(refs)
        
        sleep(100)
        XCTAssert(refs.count() == 0, "refs is still \(refs.count())")
    }

    func doTest(refs: MemReferences) {
        let clear = NAButton("Clear", refs: refs)
        clear.frame = CGRectMake(50,30,100,30)
        clear.setTitle("clear", forState: .Normal)
        clear.setTitleColor(UIColor.blueColor(), forState: .Normal)
        
        let sClearIt = clear.clicked.map { _ in "" }
        //let sClearIt = Stream<String>()
        let text = NATextField(s: sClearIt, text: "Hello", refs: refs)
        text.text = "Hello2"
        text.frame = CGRectMake(10,50,100,20)
    }
}
