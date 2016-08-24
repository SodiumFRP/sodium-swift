
public class LazyCell<T> : CellType
{
    public let refs: MemReferences?
    internal var cleanup: Listener = Listener(unlisten: nop, refs: nil)
    internal let _stream: Stream<T>
    internal var LazyInitialValue: Lazy<T>
    internal lazy var _value: T = self.LazyInitialValue**
    internal var _valueUpdate: T?
    
    init(stream: Stream<T>, @autoclosure(escaping) initialValue: () -> T, refs: MemReferences? = nil)
    {
        self.refs = refs
        if let r = self.refs {
            r.addRef()
        }
        self.LazyInitialValue = Lazy<T>(f: initialValue)
        self._stream = stream
        self.cleanup = doListen(refs)
    }
    
    init(stream: Stream<T>, lazyInitialValue: () -> T, refs: MemReferences? = nil)
    {
        self.LazyInitialValue = Lazy<T>(f: lazyInitialValue)
        self._stream = stream
        self.refs = refs
        if let r = self.refs {
            r.addRef()
        }
        self.cleanup = doListen(refs)
    }

    public init(stream: Stream<T>, lazyInitialValue: Lazy<T>, refs: MemReferences? = nil)
    {
        self.LazyInitialValue = lazyInitialValue
        self._stream = stream
        self.refs = refs
        if let r = self.refs {
            r.addRef()
        }
        self.cleanup = doListen(refs)
    }
    
    private func doListen(refs: MemReferences?) -> Listener {
        return Transaction.apply { trans1 in
            self.stream().listen(Node<Element>.Null, trans: trans1, action: { [weak self] (trans2, a) in
                if self!._valueUpdate == nil {
                    trans2.last({
                        self!._value = self!._valueUpdate!
                        self!._valueUpdate = nil
                    })
                }
                self!._valueUpdate = a
                }, suppressEarlierFirings: false,
                refs: refs)
        }
    }
    

    public func stream() -> Stream<T> {
        return self._stream
    }
    public func sample() -> T {
        return self._value
    }
    public func sampleLazy(trans: Transaction) -> Lazy<T> {
        return self.LazyInitialValue
    }
   
    public func value(trans: Transaction) -> Stream<T> {
        let spark = Stream<Unit>(keepListenersAlive: self._stream.keepListenersAlive)
        trans.prioritized(spark.node, action: { trans2 in spark.send(trans2, a: Unit.value)})
        let initial = spark.snapshot(self)
        return initial.merge(self._stream, f: { $1 })
    }

    public func sampleNoTransaction() -> T {
        return self._value
    }
}

postfix operator ** { }
postfix func **<T>(l: Lazy<T>) -> T { return l.get() }
