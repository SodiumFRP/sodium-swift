/**
 #  Memory.swift
##  Sodium

 - Author: Andrew Bradnan
 - Date: 5/20/16
 - Copyright: © 2016 Whirlygig Ventures. All rights reserved.
*/

open class MemReferences {
    var _count: Int
    public init() {
        self._count = 0
    }
    
    open func count() -> Int { return self._count }
    
    open func addRef() {
        self._count += 1
    }
    open func release() {
        self._count -= 1
    }
}
