/**
 # PriorityQueue<T>
 
 - Author: Andrew Bradnan
 - Date: 1/21/16
 - Copyright: © 2016 Whirlygig Ventures. All rights reserved.
*/

class PriorityQueue<T> {
    var contents = [T]()
    var sorted = false
    let comparator: ((T,T)->Bool)
    
    
    init(comparator: @escaping (T,T)->Bool) {
        self.comparator = comparator
    }
    
    func min(_ before: (T,T) throws -> Bool) throws -> T? {
        return try contents.min(by: before)
    }
    
    func sort(_ cmp: ((T,T) -> Bool)? = nil) {
        contents.sort(by: cmp != nil ? cmp! : comparator)
        sorted = true
    }
    
    func find(_ predicate: (T) -> Bool) -> T? {
        if let idx = contents.index(where: predicate) {
            return contents[idx]
        }
        return nil
    }
    
    func push(_ o: T) {
        contents.append(o)
        sorted = false
    }
    
    func peek(_ index: Int? = nil) -> T {
        if !sorted { sort() }
        
        let idx = index ?? contents.count - 1
        return contents[idx]
    }
    
    func pop() -> T? {
        if !sorted { sort() }
        
        return contents.popLast()
    }
    
    var first: T? {
        get {
            if !sorted { sort() }
            
            return contents.first
        }
        set(value) {
            if contents.isEmpty {
                contents.append(value!)
            }
            else {
                contents[0] = value!
            }
            sorted = false
        }
    }
    
    var last: T? {
        get {
            if !sorted { sort() }
            
            return contents.last
        }
        set(value) {
            let idx = contents.count - 1
            if idx < 0 {
                contents.append(value!)
            }
            else {
                contents[idx] = value!
            }
            sorted = false
        }
    }
    
    func removeAll() { contents.removeAll() }
    
    var count: Int { return contents.count }
    var isEmpty: Bool { return contents.isEmpty }

    func map<U>(_ f: (T) -> U) -> [U] {
        return contents.map(f)
    }
}
