/**
 # Array-Extension.swift
 
 - Author: Andrew Bradnan
 - Date: 5/2/16
 - Copyright: © 2016 Whirlygig Ventures. All rights reserved.
 */

extension Array {
    func indexOf(_ includedElement: (Element) -> Bool) -> Int? {
        for (idx, element) in self.enumerated() {
            if includedElement(element) {
                return idx
            }
        }
        return nil
    }
}

extension Array where Element : Equatable {

    func indexOf(_ e: Element) -> Int? {
        for (idx, element) in self.enumerated() {
            if element == e {
                return idx
            }
        }
        return nil
    }
    
    mutating func remove(_ e: Element) -> Bool {
        if let idx = self.indexOf(e) {
            self.remove(at: idx)
            return true
        }
        return false
    }
    
}
