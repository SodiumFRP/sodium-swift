import Foundation

/**
 A forward reference for a `Stream<T>` equivalent to the `Stream<T>` that is referenced.
 - Parameter T: The type of values fired by the stream.
 */
open class StreamLoop<T> : Stream<T>
{
    fileprivate let isAssignedLock = NSObject()
    fileprivate var _isAssigned = false

    /**
     Create an `StreamLoop<T>`.  This must be called from within a transaction.
     */
    public override init(refs: MemReferences? = nil)
    {
        if (!Transaction.hasCurrentTransaction())
        {
            fatalError("StreamLoop and CellLoop must be used within an explicit transaction")
        }
        super.init(refs: refs)
    }

    internal var isAssigned: Bool
    {
        get
        {
            objc_sync_enter(self.isAssignedLock)
            defer { objc_sync_exit(self.isAssignedLock) }

            return self._isAssigned
        }
    }

    /**
     Resolve the loop to specify what the `StreamLoop<T>` was a forward reference to.  This method must be called inside the same transaction as the one in which this `StreamLoop<T>` instance was created and used.  This requires an explicit transaction to be created with `Transaction.run<T>(Func<T>)` or `Transaction.runVoid(Action)`.
 
     - Parameter stream: The stream that was forward referenced.
    */
    open func loop(_ stream: Stream<T>) {
        objc_sync_enter(self.isAssignedLock)
        defer { objc_sync_exit(self.isAssignedLock) }

        if (self.isAssigned) {
            fatalError("StreamLoop was looped more than once.")
        }

        self._isAssigned = true

        Transaction.runVoid {
            let _ = self.unsafeAddCleanup(stream.listen(self.node, action: self.send))
            stream.keepListenersAlive.use(self.keepListenersAlive)
        }
    }
}
