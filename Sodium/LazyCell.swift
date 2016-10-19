
open class LazyCell<T> : CellType
{
    open let refs: MemReferences?
    internal var cleanup: Listener = Listener(unlisten: nop, refs: nil)
    internal let _stream: Stream<T>
    internal var LazyInitialValue: Lazy<T>
    internal lazy var _value: T = self.LazyInitialValue**
    internal var _valueUpdate: T?
    
    init(stream: Stream<T>, initialValue: @autoclosure @escaping () -> T, refs: MemReferences? = nil)
    {
        self.refs = refs
        if let r = self.refs {
            r.addRef()
        }
        self.LazyInitialValue = Lazy<T>(f: initialValue)
        self._stream = stream
        self.cleanup = doListen(refs)
    }
    
    init(stream: Stream<T>, lazyInitialValue: @escaping () -> T, refs: MemReferences? = nil)
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
    
    fileprivate func doListen(_ refs: MemReferences?) -> Listener {
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
    

    open func stream() -> Stream<T> {
        return self._stream
    }
    open func sample() -> T {
        return self._value
    }
    open func sampleLazy(_ trans: Transaction) -> Lazy<T> {
        return self.LazyInitialValue
    }
   
    open func value(_ trans: Transaction) -> Stream<T> {
        let spark = Stream<Unit>(keepListenersAlive: self._stream.keepListenersAlive)
        trans.prioritized(spark.node, action: { trans2 in spark.send(trans2, a: Unit.value)})
        let initial = spark.snapshot(self)
        return initial.merge(self._stream, f: { $1 })
    }

    open func sampleNoTransaction() -> T {
        return self._value
    }
}

postfix operator **
postfix func **<T>(l: Lazy<T>) -> T { return l.get() }
