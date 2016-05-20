/**
 # Cell
 Represents a value that changes over time.
*/
public protocol CellType {
    associatedtype Element
    func stream() -> Stream<Element>
    func sample() -> Element
    func sampleLazy(trans: Transaction) -> Lazy<Element>
    func sampleNoTransaction() -> Element
    func value(trans: Transaction) -> Stream<Element>
}


public struct AnyCell<T>: CellType {
    private let _stream: () -> Stream<T>
    private let _sample: () -> T
    private let _sampleLazy: (Transaction)->Lazy<T>
    private let _sampleNoTransaction: () -> T
    private let _value: (Transaction) -> Stream<T>
    
    init<Base: CellType where T == Base.Element>(_ base: Base) {
        _stream = base.stream
        _sample = base.sample
        _sampleLazy = base.sampleLazy
        _sampleNoTransaction = base.sampleNoTransaction
        _value = base.value
    }
    
    public func stream() -> Stream<T> {
        return _stream()
    }
    public func sample() -> T {
        return _sample()
    }
    public func sampleLazy(trans: Transaction) -> Lazy<T> {
        return _sampleLazy(trans)
    }
    public func sampleNoTransaction() -> T {
        return _sampleNoTransaction()
    }
    public func value(trans: Transaction) -> Stream<T> {
        return _value(trans)
    }
}

/**
    Represents a value that changes over time.

    - Parameter T: The type of the value.
 */
public class CellBase<T> : CellType {
    internal let _stream: Stream<T>
    private var _value: T
    private var _valueUpdate: T?
    
    /**
        Creates a cell with a constant value.

        - Parameters:
            - T: The type of the value of the cell.
            - value: The value of the cell.
 
        - Returns: A cell with a constant value.
     */
    public static func constant<T>(value: T) -> Cell<T> {
        return Cell<T>(value: value)
    }
    
    /**
        Creates a cell with a lazily computed constant value.

        - Parameter TResult: The type of the value of the cell.
        - Parameter value: The lazily computed value of the cell.
 
        - Returns: A cell with a lazily computed constant value.
    */
    public static func constantLazy<TResult>(@autoclosure(escaping) value: () -> TResult) -> AnyCell<TResult>
    {
        return Stream<TResult>.never().holdLazy(value)
    }

    /**
        Creates a cell with a constant value.
 
        - Parameter value: The constant value of the cell.
     */
    internal init(value: T)
    {
        self._stream = Stream<T>()
        self._value = value
    }
    
 
    internal init(stream: Stream<T>, initialValue: T) {
        self._stream = stream
        self._value = initialValue
    }

    internal var keepListenersAlive: IKeepListenersAlive { return self._stream.keepListenersAlive }

    var ValueProperty: T
    {
        get {
            return _value
        }
        set(value)
        {
            self._value = value
        }
    }

    /**
        Sample the current value of the cell.

        - Returns: the current value of the cell.
        
        - Remarks:
            This method may be used inside the functions passed to primitives that apply them to streams, including
            `Stream<T>.map<TResult>(Func<T, TResult>)` in which case it is equivalent to snapshotting the cell,
            `Stream<T>.snapshot<T2, TResult>(Cell<T2>, Func<T, T2, TResult>)`, `Stream<T>.filter(Func{T, bool})`, 
            and 'Stream<T>.merge(Stream<T>, Func{T, T, T})`
     
            It should generally be avoided in favor of `Listen(Action<T>)` so updates aren't missed, but in many
            circumstances it makes sense.
     
            It can be best to use this method inside an explicit transaction (using `Transaction.run<T>(Func<T>)`
            or `Transaction.runVoid(Action)`).
     
            For example, a b.Sample() inside an explicit transaction along with a b.Updates().Listen(...) will 
            capture the current value and any updates without risk of missing any in between.
     */
    public func sample() -> T {
        return  Transaction.apply{ trans in self.sampleNoTransaction() }
    }
    public func stream() -> Stream<T> {
        return self._stream
    }

    /**
        Sample the current value of the cell.
     
        - Returns: A lazy which may be used to get the current value of the cell.
        - Remarks: This is a variant of `sample` that works with the `CellLoop<T>` class when the cell loop has not yet been looped.  It should be used in any code that is general enough that it may be passed a `CellLoop<T>`.
     
        - SeeAlso: `Stream<T>.HoldLazy(Lazy<T>)`
     */
    public func sampleLazy(trans: Transaction) -> Lazy<T> {
        let s = LazySample(cell: self)
        trans.last(
            {
                s.value = self._valueUpdate ?? self.sampleNoTransaction()
                //s.cell = nil
        })
        return Lazy(f: { s.value ?? s.cell.sample() })
    }

    public func sampleNoTransaction() -> T
    {
        let t = self.ValueProperty
        return t
    }

    internal func updates(trans: Transaction?) -> Stream<T> { return self.stream() }

    /**
     Listen for updates to the value of this cell.  The returned `Listener` may be disposed to stop listening, or it will automatically stop listening when it is garbage collected.
     
     - Note: This is an OPERATIONAL mechanism for interfacing between the world of I/O and FRP.
     
     - Parameter handler: The handler to execute for each value.
     - Returns: An `Listener` which may be disposed to stop listening.
     - Remarks:
     No assumptions should be made about what thread the handler is called on and it should not block.  Neither `StreamSink<T>.send` nor `CellSink<T>.send` may be called from the handler. They will throw an exception because this method is not meant to be used to create new primitives.
     
     If the `Listener` is not disposed, it will continue to listen until this cell is either disposed or garbage collected or the listener itself is garbage collected.
     */
    public func listenWeak(handler: (T) -> Void) -> Listener {
        return Transaction.apply { trans in self.value(trans).listenWeak(handler)}
    }




/*
    /*
     *      Return a cell whose stream only receives events which have a different value than the previous event.
     */
     - Returns:A cell whose stream only receives events which have a different value than the previous event.
    public func calm() -> Cell<T>
    {
        return self.Calm(EqualityComparer<T>.Default)
    }

    /*
     *      Return a cell whose stream only receives events which have a different value than the previous event.
     */
     - Parameter comparer: The equality comparer to use to determine if two items are equal.
     - Returns:A cell whose stream only receives events which have a different value than the previous event.
    public func calm(comparer: IEqualityComparer<T>) -> Cell<T>
    {
        let initA = self.SampleLazy()
        let mInitA = initA.Map(Maybe.Just)
        return Transaction.Apply { trans in self.Updates(trans).Calm(mInitA, comparer).HoldLazy(initA) }
    }
*/
}

private class LazySample<C:CellType>
{
    let cell: C
    var value: C.Element?
    
    init(cell: C)
    {
        self.cell = cell
    }
}


/**
 The class hierarchy comes because you can create a closure that uses an uninitialized self.
 CellBase<> has all the data, and we just have the cleanup closure to take care of.
 */
public class Cell<T>: CellBase<T> {
    private var cleanup: Listener = Listener(unlisten: nop)

    internal override init(value: T) {
        super.init (value: value)
        self.cleanup = doListen()
    }

    internal override init(stream: Stream<T>, initialValue: T) {
        super.init(stream: stream, initialValue: initialValue)
        self.cleanup = doListen()
    }
    
    private func doListen() -> Listener {
        return Transaction.apply { trans1 in
            self._stream.listen(Node<T>.Null, trans: trans1, action: { (trans2, a, dbg) in
                if self._valueUpdate == nil {
                    trans2.last({
                        self._value = self._valueUpdate!
                        self._valueUpdate = nil
                    })
                }
                self._valueUpdate = a
                }, suppressEarlierFirings: false)
        }
    }
    
    deinit {
        self.cleanup.unlisten()
    }
}

extension CellType {
   
    /**
     Lift a binary function into cells, so the returned Cell always reflects the specified function applied to the input cells' values.
     
     - Parameter C: The type of second cell.
     - Parameter TResult: The type of the result.
     - Parameter f: The binary function to lift into the cells.
     - Parameter c2: The second cell.
     - Returns: A cell containing values resulting from the binary function applied to the input cells' values.
     */
    public func lift<C:CellType, TResult>(c2: C, f: (Element,C.Element) -> TResult) -> AnyCell<TResult> {
        let ffa = { a in { b in f(a,b) }}
        return c2.apply(self.map(ffa))
    }
    
    /**
     Lift a ternary function into cells, so the returned cell always reflects the specified function applied to the input cells' values.

     - Parameter C2: The type of second cell.
     - Parameter C3: The type of third cell.
     - Parameter TResult: The type of the result.
     - Parameter f: The binary function to lift into the cells.
     - Parameter c2: The second cell.
     - Parameter c3: The third cell.
     
     - Returns: A cell containing values resulting from the ternary function applied to the input cells' values.
     */
    public func lift<C2:CellType, C3: CellType, TResult>(c2: C2, c3: C3, f: (Element,C2.Element,C3.Element) -> TResult) -> AnyCell<TResult>
    {
        let ffa = { a in { b in { c in f(a,b,c) }}}
        return c3.apply(c2.apply(self.map(ffa)))
    }
    
    /**
     Lift a quaternary function into cells, so the returned cell always reflects the specified function applied to the input cells' values.
     
     - Parameter C2: The type of second cell.
     - Parameter C3: The type of third cell.
     - Parameter C4: The type of fourth cell.
     - Parameter TResult: The type of the result.
     - Parameter f: The binary function to lift into the cells.
     - Parameter c2: The second cell.
     - Parameter c3: The third cell.
     - Parameter c4: The fourth cell.
     - Returns: A cell containing values resulting from the quaternary function applied to the input cells' values.
     */
    public func lift<C2:CellType, C3:CellType, C4:CellType, TResult>(c2: C2, c3: C3, c4: C4, f: (Element,C2.Element,C3.Element,C4.Element) -> TResult) -> AnyCell<TResult>
    {
        let ffa = { a in { b in { c in { d in f(a,b,c,d) }}}}
        return c4.apply(c3.apply(c2.apply(self.map(ffa))))
    }
    
    /**
     Lift a 5-argument function into cells, so the returned cell always reflects the specified function applied to the input cells' values.
     
     - Parameter C2: The type of second cell.
     - Parameter C3: The type of third cell.
     - Parameter C4: The type of fourth cell.
     - Parameter C5: The type of fifth cell.
     - Parameter TResult: The type of the result.
     - Parameter f: The binary function to lift into the cells.
     - Parameter c2: The second cell.
     - Parameter c3: The third cell.
     - Parameter c4: The fourth cell.
     - Parameter c5: The fifth cell.
     - Returns: A cell containing values resulting from the 5-argument function applied to the input cells' values.
     */
    public func lift<C2:CellType, C3:CellType, C4:CellType, C5:CellType, TResult>(c2: C2, c3: C3, c4: C4, c5: C5, f: (Element,C2.Element,C3.Element,C4.Element,C5.Element)->TResult) -> AnyCell<TResult>
    {
        let ffa = { a in { b in { c in { d in { e in f(a,b,c,d,e) }}}}}
        return c5.apply(c4.apply(c3.apply(c2.apply(self.map(ffa)))))
    }
    
    /**
     Lift a 6-argument function into cells, so the returned cell always reflects the specified function applied to the input cells' values.

     - Parameter C2: The type of second cell.
     - Parameter C3: The type of third cell.
     - Parameter C4: The type of fourth cell.
     - Parameter C5: The type of fifth cell.
     - Parameter C6: The type of sixth cell.
     - Parameter TResult: The type of the result.
     - Parameter f: The binary function to lift into the cells.
     - Parameter c2: The second cell.
     - Parameter c3: The third cell.
     - Parameter c4: The fourth cell.
     - Parameter c5: The fifth cell.
     - Parameter c6: The sixth cell.
     - Returns: A cell containing values resulting from the 6-argument function applied to the input cells' values.
     */
    public func lift<C2:CellType, C3:CellType, C4:CellType, C5:CellType, C6:CellType, TResult>(c2: C2, c3: C3, c4: C4, c5: C5, c6: C6, f: (Element,C2.Element,C3.Element,C4.Element,C5.Element,C6.Element)->TResult) -> AnyCell<TResult>
    {
        let ffa = { a in { b in { c in { d in { e in { _f in f(a,b,c,d,e,_f) }}}}}}
        return c6.apply(c5.apply(c4.apply(c3.apply(c2.apply(self.map(ffa))))))
    }
    
    /**
     Apply a value inside a cell to a function inside a cell.  This is the primitive for all function lifting.

     - Parameter TResult: The type of the result.
     - Parameter C: The current CellType.
     - Parameter bf: The cell containing the function to apply the value to.
     - Returns: A cell whose value is the result of applying the current function in cell `bf` to this cell's current value.
     */
    public func apply<TResult, C:CellType where C.Element == Element->TResult>(bf: C) -> AnyCell<TResult> {
        return Transaction.apply{ trans0 in
            let out = Stream<TResult>(keepListenersAlive: self.stream().keepListenersAlive)
            
            let outTarget = out.node
            let inTarget = Node<TResult>(rank: 0)
            let nodeTarget = inTarget.link({ (t, v, dbg) in }, target: outTarget).1
            
            var f: ((Element)->TResult)?
            var a: Element?
            
            let h = { (trans1: Transaction) -> Void in
                trans1.prioritized(out.node as INode) { trans2 throws -> Void in out.send(trans2, a: f!(a!))}}
            
            let l1 = bf.value(trans0).listen(inTarget, action: {(trans1, ff, dbg) in
                f = ff
                if a != nil {
                    h(trans1)
                }
            })
            let l2 = self.value(trans0).listen(inTarget, action: { (trans1, aa, dbg) in
                a = aa
                if f != nil {
                    h(trans1)
                }
            })
            return out.lastFiringOnly(trans0).unsafeAddCleanup([l1,l2,
                Listener(unlisten: { inTarget.unlink(nodeTarget) })]).holdLazy({ bf.sampleNoTransaction()(self.sampleNoTransaction()) })
        }
    }

    /**
     Listen for updates to the value of this cell.  The returned Listener may be disposed to stop listening.
     
     - Note: This is an **OPERATIONAL** mechanism for interfacing between the world of I/O and FRP.
     
     - Parameter handler: The handler to execute for each value.
     - Returns: `Listener` which may be disposed to stop listening.
     
     - Remarks: No assumptions should be made about what thread the handler is called on and it should not block.  Neither StreamSink<T>.send nor CellSink<T>.send may be called from the handler.  They will throw an exception because this method is not meant to be used to create new primitives.
     
     If the Listener is not disposed, it will continue to listen until this cell is disposed.
     */
  
    public func listen(handler: (Element) -> Void) -> Listener {
        return Transaction.apply{trans in self.value(trans).listen(handler)}!
    }

    /**
     Transform the cell values according to the supplied function, so the returned cell's values reflect the value of the function applied to the input cell's values.
     
     - Parameter TResult: The type of values fired by the returned cell.
     - Parameter f: Function to apply to convert the values.  It must be a pure function.
    
     - Returns: An cell which fires values transformed by f() for each value fired by this cell.
     */
    public func map<TResult>(f: (Element) -> TResult) -> Cell<TResult>
    {
        let rt = Transaction.apply{ (trans: Transaction) in
            self.stream().map(f).hold(f(self.sample())) }

        return rt
    }
    
    public func value(trans1: Transaction) -> Stream<Element> {
        let spark = Stream<Unit>(keepListenersAlive: self.stream().keepListenersAlive)
        trans1.prioritized(spark.node) { trans2 in spark.send(trans2, a: Unit.value)}
        let initial = spark.snapshot(self)
        //return initial.merge(self.updates(trans1), f: { $1 })
        return initial.merge(self.stream(), f: { $1 })
    }
}