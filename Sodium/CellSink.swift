/**
 A cell that allows values to be pushed into it, acting as an interface between the world of I/O and the world of FRP.  Code that exports instances of `CellSink<T>` for read-only use should downcast to `Cell<T>`

 - Parameter T: The type of values in the cell.
 */
public class CellSink<T> : Cell<T>
{
    private let streamSink: StreamSink<T>

    /**
     Construct a writable cell that uses the last value if `send` is called more than once per transaction.

    - Parameter initialValue: The initial value of the cell.
    */
    convenience init(_ initialValue: T)
    {
        self.init(streamSink: StreamSink<T>(), initialValue: initialValue)
    }

    /**
     Construct a writable cell
     
     - Parameter coalesce: to combine values if `send` is called more than once per transaction.
     - Parameter initialValue: The initial value of the cell.
     - Parameter coalesce: Function to combine values when `send` is called more than once per transaction.
    */
    public convenience init(initialValue: T, coalesce: (T,T) -> T)
    {
        self.init(streamSink: StreamSink<T>(fold: coalesce), initialValue: initialValue)
    }

    private init(streamSink: StreamSink<T>, initialValue: T) {
        self.streamSink = streamSink
        super.init(stream: streamSink, initialValue: initialValue)
    }

    /**
     Send a value, modifying the value of the cell.  This method may not be called from inside handlers registered with `Stream<T>.listen(Action<T>)' or `Cell<T>.listen(Action<T>)`.  An exception will be thrown, because sinks are for interfacing I/O to FRP only.  They are not meant to be used to define new primitives.
     
     - Parameter a: The value to send.
    */
    public func send(a: T) { self.streamSink.send(a) }
}
