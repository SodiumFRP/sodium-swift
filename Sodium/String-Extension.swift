/**
 # String-Extension.swift
 
 - Author: Andrew Bradnan
 - Date: 5/6/16
 - Copyright: © 2016 Whirlygig Ventures. All rights reserved.
*/
extension String {
    var isUpperCase: Bool {
        return self == self.uppercaseString
    }
    var isLowerCase: Bool {
        return self == self.lowercaseString
    }
}