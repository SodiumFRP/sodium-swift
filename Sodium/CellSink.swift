/**
 A cell that allows values to be pushed into it, acting as an interface between the world of I/O and the world of FRP.  Code that exports instances of `CellSink<T>` for read-only use should downcast to `Cell<T>`

 - Parameter T: The type of values in the cell.
 */
open class CellSink<T> : Cell<T>
{
    fileprivate let streamSink: StreamSink<T>

    /**
     Construct a writable cell that uses the last value if `send` is called more than once per transaction.

    - Parameter initialValue: The initial value of the cell.
    */
    public convenience init(_ initialValue: T, refs: MemReferences? = nil)
    {
        self.init(streamSink: StreamSink<T>(), initialValue: initialValue, refs: refs)
    }

    /**
     Construct a writable cell
     
     - Parameter coalesce: to combine values if `send` is called more than once per transaction.
     - Parameter initialValue: The initial value of the cell.
     - Parameter coalesce: Function to combine values when `send` is called more than once per transaction.
    */
    public convenience init(initialValue: T, coalesce: @escaping (T,T) -> T, refs: MemReferences? = nil)
    {
        self.init(streamSink: StreamSink<T>(fold: coalesce), initialValue: initialValue, refs: refs)
    }

    fileprivate init(streamSink: StreamSink<T>, initialValue: T, refs: MemReferences? = nil) {
        self.streamSink = streamSink
        super.init(stream: streamSink, initialValue: initialValue, refs: refs)
    }

    /**
     Send a value, modifying the value of the cell.  This method may not be called from inside handlers registered with `Stream<T>.listen(Action<T>)' or `Cell<T>.listen(Action<T>)`.  An exception will be thrown, because sinks are for interfacing I/O to FRP only.  They are not meant to be used to define new primitives.
     
     - Parameter a: The value to send.
    */
    open func send(_ a: T) { self.streamSink.send(a) }
}
