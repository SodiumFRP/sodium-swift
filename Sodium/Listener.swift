import Foundation
/**
 A listener which runs the specified action when it is unlistened.
 */
open class Listener : NSObject, ListenerType
{
    fileprivate let _unlisten: Block
    fileprivate let refs: MemReferences?
    
    /**
     Creates a listener which runs the specified action when it is disposed.
     - Parameter unlisten: The action to run when this listener should stop listening.
    */
    init(unlisten: @escaping Block, refs: MemReferences?)
    {
        self._unlisten = unlisten
        self.refs = refs
        if let r = self.refs {
            r.addRef()
        }
    }

    deinit {
        if let r = self.refs {
            r.release()
        }
    }
    
    open func unlisten() {
        self._unlisten()
    }
}

public func ==(lhs: Listener, rhs: Listener) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
