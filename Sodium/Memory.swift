//
//  Memory.swift
//  Sodium
//
//  Created by Andrew Bradnan on 5/20/16.
//  Copyright © 2016 Whirlygig Ventures. All rights reserved.
//

import Foundation

public class MemReferences {
    var _count: Int
    public init() {
        self._count = 0
    }
    
    public func count() -> Int { return self._count }
    
    public func addRef() {
        self._count += 1
    }
    public func release() {
        self._count -= 1
    }
}