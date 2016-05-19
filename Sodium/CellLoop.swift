/**
    A forward reference for a `Cell<T>` equivalent to the `Cell<T>` that is referenced.

 - Parameter T: The type of values in the cell.
*/
public class CellLoop<T> : LazyCell<T>
{
    private let streamLoop: StreamLoop<T>

    /**
     Create a `CellLoop<T>`.
     */
    init(streamLoop: StreamLoop<T>, @autoclosure(escaping) initialValue: () -> T)
    {
        self.streamLoop = streamLoop
        super.init(stream: streamLoop, initialValue: initialValue)
    }

    /**
     Resolve the loop to specify what the `CellLoop<T>` was a forward reference to.  This method must be called inside the same transaction as the one in which this `CellLoop<T>` instance was created and used.  This requires an explicit transaction to be created with `Transaction.run<T>(()->T)` or `Transaction.runVoid(Action)`.
 
     - Parameter c: The cell that was forward referenced.
    */
    public func loop(c: Cell<T>) {
        Transaction.apply { trans -> Unit in
            self.streamLoop.loop(c.stream())
            self.LazyInitialValue = c.sampleLazy(trans)
            return Unit.value
        }
    }

    override public func sampleNoTransaction() -> T {
        if !self.streamLoop.isAssigned {
            fatalError("CellLoop was sampled before it was looped.")
        }

        return super.sampleNoTransaction()
    }
}


