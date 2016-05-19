import Foundation
/**
 A listener which runs the specified action when it is unlistened.
 */
public class Listener : NSObject, ListenerType
{
    private let _unlisten: Block

    /**
     Creates a listener which runs the specified action when it is disposed.
     - Parameter unlisten: The action to run when this listener should stop listening.
    */
    init(unlisten: Block)
    {
        self._unlisten = unlisten
    }

    public override var hashValue: Int { return super.hashValue }

    public func unlisten() {
        self._unlisten()
    }
}

public func ==(lhs: Listener, rhs: Listener) -> Bool {
    return lhs.hashValue == rhs.hashValue
}