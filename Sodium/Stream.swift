import Foundation

/**
 Represents a stream of discrete events/firings.

 - Parameter T: The type of values fired by the stream.
 */
public class Stream<T>
{
    public typealias Handler = T -> Void
    typealias Action = (Transaction, T) -> Void
    
    internal let refs: MemReferences?
    internal let node: Node<T>
    private var disposables: Array<Listener>
    private var firings: Array<T>
    internal let keepListenersAlive: IKeepListenersAlive
    internal let lock = NSObject()
    
    /**
     Creates a stream that never fires.

     - Parameter T: The type of the values that would be fired by the stream if it did fire values.
     - Returns: A stream that never fires.
    */
    public static func never() -> Stream<T> { return Stream<T>() }

    deinit {
        if let r = self.refs { r.release() }
        print("Stream<> deinit")
    }
    
    public init(refs: MemReferences? = nil) {
        self.refs = refs
        
        if let r = self.refs {
            r.addRef()
        }
        self.keepListenersAlive = KeepListenersAliveImplementation()
        self.node = Node<T>(rank: 0)
        self.disposables = []
        self.firings = []
    }

    internal convenience init(keepListenersAlive: IKeepListenersAlive, refs: MemReferences? = nil)
    {
        self.init(keepListenersAlive: keepListenersAlive, node: Node<T>(rank: 0), disposables: [Listener](), firings: [T](), refs: refs)
    }

    private init(keepListenersAlive: IKeepListenersAlive, node: Node<T>, disposables: [Listener], firings: [T], refs: MemReferences? = nil)
    {
        self.refs = refs
        if let r = self.refs {
            r.addRef()
        }
        self.keepListenersAlive = keepListenersAlive
        self.node = node
        self.disposables = disposables
        self.firings = firings
    }

    /**
     Listen for events/firings on this stream.  The returned `Listener` may be disposed to stop listening.  This is an **OPERATIONAL** mechanism for interfacing between the world of I/O and FRP.

     - Parameter handler: The handler to execute for values fired by the stream.
     - Returns:An `IListener` which may be disposed to stop listening.
     - Remarks:
     No assumptions should be made about what thread the handler is called on and it should not block.  Neither `StreamSink<T>.send` nor `CellSink<T>.send` may be called from the handler.  They will throw an exception because this method is not meant to be used to create new primitives.

     If the `Listener` is not disposed, it will continue to listen until this stream is either disposed or garbage collected.
     
     To ensure this `Listener` is disposed as soon as the stream it is listening to is either disposed, pass the returned listener to this stream's `AddCleanup` method.
     */
    public func listen(refs: MemReferences? = nil, handler: Handler) -> Listener
    {
        var innerListener = self.listenWeak(handler)
        var ls = [Listener]()
        
        ls.append(Listener(
            unlisten: { [weak self, weak innerListener] in
                objc_sync_enter(self!.lock)
                defer { objc_sync_exit(self!.lock) }

                innerListener?.unlisten()

                if (ls.first != nil) {
                    self!.keepListenersAlive.stopKeepingListenerAlive(ls.first!)
                }
            }, refs: refs)
        )

        objc_sync_enter(self.lock)
        defer { objc_sync_exit(self.lock) }

        self.keepListenersAlive.keepListenerAlive(ls.first!)

        return ls.first!
    }

    /**
     Listen for events/firings on this stream.  The returned `Listener` may be disposed to stop listening, or it will automatically stop listening when it is garbage collected.  This is an **OPERATIONAL** mechanism for interfacing between the world of I/O and FRP.
 
     - Parameter handler: The handler to execute for values fired by the stream.
     - Returns: A `Listener` which may be disposed to stop listening.
     - Remarks:
     No assumptions should be made about what thread the handler is called on and it should not block.  Neither `StreamSink<T>.send` nor `CellSink<T>.send` may be called from the handler.  They will throw an exception because this method is not meant to be used to create new primitives.
     
     If the `Listener` is not disposed, it will continue to listen until this stream is either disposed or garbage collected.
     
     To ensure this `Listener` is disposed as soon as the stream it is listening to is either disposed, pass the returned listener to this stream's `AddCleanup` method.
     */
    func listenWeak(handler: Handler) -> Listener {
        return self.listen(INode.Null, action: {(trans2, a) in
            
            // T could really be U? so make sure we have a value using reflection
            let ref = Mirror(reflecting: a)
            
            // if a is not Optional, just call handler
            if ref.displayStyle != .Optional {
                handler(a)
            }
            else if ref.children.count > 0 {
                let (_, some) = ref.children.first!
                handler(some as! T)
            }
        })
    }

    /**
     Attach a listener to this stream so it gets disposed when this stream is disposed.
 
     - Parameter listener: The listener to dispose along with this stream.
     - Returns: A new stream equivalent to this stream which will dispose <paramref name="listener` when it is disposed.
    */
    public func addCleanup(listener: Listener) -> Stream<T> {
        return Transaction.noThrowRun({
            var fsNew = self.disposables
            fsNew.append(listener)
            return Stream<T>(keepListenersAlive: self.keepListenersAlive, node: self.node, disposables: fsNew, firings: self.firings)
        })
    }

    /**
     Handle the first event on this stream and then automatically unregister.
     
     - Parameter T: The type of values fired by the stream.
     - Parameter handler: The handler to execute for values fired by this stream.
     - Returns:
    */
    public func listenOnce(handler: (T)->Void) -> Listener? {
        var ls = [Listener]()
        
        ls.append(self.listen(self.refs) { a in
            handler(a)
            ls.first!.unlisten()
        })
        return ls.first!
    }

    /**
     *      Handle the first event on this stream and then automatically unregister.
     *
     - Parameter T: The type of values fired by the stream.
     - Returns:A task which completes when a value is fired by this stream.
    */
    /*
    public func listenOnce() -> Task<T> {
        return self.ListenOnce(CancellationToken.None)
    }
*/
    /**
     *      Handle the first event on this stream and then automatically unregister.
     *
     - Parameter T: The type of values fired by the stream.
     - Parameter token: The cancellation token.
     - Returns:A task which completes when a value is fired by this stream.
*/
    
    /*
    public func listenOnce(token: CancellationToken) -> Task<T> {
        let tcs = TaskCompletionSource<T>()

        let listener = self.Listen({ a in
            tcs.TrySetResult(a)
        })

        token.Register { tcs.TrySetCanceled() }

        return tcs.Task
    }
*/
    internal func listen(target: INode, action: Action, refs: MemReferences? = nil) -> Listener {
        return Transaction.apply { trans1 in self.listen(target, trans: trans1, action: action, suppressEarlierFirings: false, refs: refs) }
    }

    internal func listen(target: INode, trans: Transaction, action: Action, suppressEarlierFirings: Bool, refs: MemReferences? = nil) -> Listener {
        
        let t = self.node.link(action, target: target)
        let nodeTarget = t.1
        if (t.0)
        {
            trans.setNeedsRegenerating()
        }
        // ReSharper disable once LocalVariableHidesMember
        let firings = self.firings
        if (!suppressEarlierFirings && !firings.isEmpty)
        {
            trans.prioritized(target) { trans2 in
                // Anything sent already in this transaction must be sent now so that
                // there's no order dependency between send and listen.
                for a in firings {
                    Transaction.inCallback += 1
                    defer { Transaction.inCallback -= 1 }
                    // Don't allow transactions to interfere with Sodium internals.
                    action(trans2, a)
                }
            }
        }
        return ListenerImplementation(stream: self, action: action, target: nodeTarget, refs: refs)
    }

    /**
     Transform the stream values according to the supplied function, so the returned stream's values reflect the value of the function applied to the input stream's values.
 
     - Parameter TResult: The type of values fired by the returned stream.
     - Parameter f: Function to apply to convert the values.  It may construct FRP logic or use `Cell<T>.sample()`, in which case it is equivalent to calling `snapshot<TResult>(Cell<TResult>)` on the cell.  Other than this, the function must be a pure function.

     - Returns:A stream which fires values transformed by <paramref name="f` for each value fired by this stream.
    */
    public func map<TResult>(f: (T) -> TResult) -> Stream<TResult>
    {
        let out = Stream<TResult>(keepListenersAlive: self.keepListenersAlive)
        let l = self.listen(out.node, action: { /*[weak out]*/ (trans2, a) in out.send(trans2, a: f(a)) }, refs: self.refs )
        return out.unsafeAddCleanup(l)
    }

    /**
     Transform the stream values to the specified constant value.
 
     - Parameter TResult: The type of the constant value fired by the returned stream.
     - Parameter value: The constant value to return from this mapping.
     
     - Returns: A stream which fires the constant value for each value fired by this stream.
     */
    public func mapTo<TResult>(value: TResult) -> Stream<TResult> {
        return self.map({ _ in value })
    }

    /**
     Create a cell with the specified initial value, that is updated by this stream's values.
 
     - Parameter initialValue: The initial value of the cell.
     - Returns: A cell with the specified initial value, that is updated by this stream's values.
     - Remarks: There is an implicit delay state updates caused by stream event firings don't become  visible as the cell's current value as viewed by `Stream<T>.snapshot<0T2, TResult>(Cell<T2>, (T, T2) -> TResult)` until the following transaction. To put this another way, `Stream<T>.snapshot<T2, TResult>(Cell<T2>, (T, T2) -> TResult)` always sees the value of a cell as it was before any state changes from the current transaction.
     */
    public func hold(initialValue: T)  -> Cell<T> {
        return Transaction.apply{trans in Cell<T>(stream: self, initialValue: initialValue) }
    }

    /**
     Create a cell with the specified lazily initialized initial value, that is updated by this stream's values.
     
     - Parameter initialValue: The lazily initialized initial value of the cell.
     - Returns: A cell with the specified lazily initialized initial value, that is updated by this stream's values.
     */
    public func holdLazy(initialValue: () -> T) -> AnyCell<T> {
        return Transaction.apply {trans in self.holdLazy(trans, initialValue: initialValue)}
    }

    internal func holdLazy(trans: Transaction, lazy: Lazy<T>) -> AnyCell<T> {
        return AnyCell<T>(LazyCell<T>(stream: self, lazyInitialValue: lazy))
    }

    internal func holdLazy(trans: Transaction, initialValue: () -> T) -> AnyCell<T> {
        return AnyCell<T>(LazyCell<T>(stream: self, lazyInitialValue: initialValue))
    }

    /**
     Return a stream whose events are the values of the cell at the time of the stream event firing.
 
     - Parameter TResult: The return type.
     - Parameter c: The cell to combine with.
     - Returns:A stream whose events are the values of the cell at the time of the stream event firing.
    */
    public func snapshot<TResult, C:CellType where C.Element==TResult>(c: C) -> Stream<TResult>
    {
        return self.snapshot(c, f: { (a, b) in b })
    }

    /**
     Return a stream whose events are the result of the combination using the specified function of the input stream's value and the value of the cell at the time of the stream event firing.
 
     - Parameter T1: The type of the cell.
     - Parameter TResult: The return type.
     - Parameter c: The cell to combine with.
     - Parameter f: A function to convert the stream value and cell value into a return value.
     - Returns: A stream whose events are the result of the combination using the specified function of the input stream's value and the value of the cell at the time of the stream event firing.
     */
    public func snapshot<T1, TResult, C1 : CellType where C1.Element==T1>(c: C1, f: (T, T1) -> TResult) -> Stream<TResult> {
        let out = Stream<TResult>(keepListenersAlive: self.keepListenersAlive)
        let l = self.listen(out.node, action: { (trans2, a) in

            // T could really be U? so make sure we have a value using reflection
            let fa = f(a, c.sampleNoTransaction())
            let ref = Mirror(reflecting: fa)
            
            // if a is not Optional, just call handler
            if ref.displayStyle != .Optional {
                out.send(trans2, a: fa)
            }
            else if ref.children.count > 0 {
                let (_, some) = ref.children.first!
                out.send(trans2, a: some as! TResult)
            }

        })
        return out.unsafeAddCleanup(l)
    }


    /**
     Return a stream whose events are the result of the combination using the specified function of the input stream's value and the value of the cells at the time of the stream event firing.
 
     - Parameter T1: The type of the first cell.
     - Parameter T2: The type of the second cell.
     - Parameter TResult: The return type.
     - Parameter c1: The first cell to combine with.
     - Parameter c2: The second cell to combine with.
     - Parameter f: A function to convert the stream value and cell value into a return value.
     - Returns: A stream whose events are the result of the combination using the specified function of the input stream's value and the value of the cells at the time of the stream event firing.
     */
    public func snapshot<T1, T2, TResult>(c1: Cell<T1>, c2: Cell<T2>, f: (T, T1, T2) -> TResult) -> Stream<TResult> {
        let out = Stream<TResult>(keepListenersAlive: self.keepListenersAlive)
        let l = self.listen(out.node, action: { (trans2, a) in out.send(trans2, a: f(a, c1.sampleNoTransaction(), c2.sampleNoTransaction()))} )
        return out.unsafeAddCleanup(l)
    }

    /**
     Return a stream whose events are the result of the combination using the specified function of the input stream's value and the value of the cells at the time of the stream event firing.
 
     - Parameter T1: The type of the first cell.
     - Parameter T2: The type of the second cell.
     - Parameter T3: The type of the third cell.
     - Parameter TResult: The return type.
     - Parameter c1: The first cell to combine with.
     - Parameter c2: The second cell to combine with.
     - Parameter c3: The third cell to combine with.
     - Parameter f: A function to convert the stream value and cell value into a return value.
     - Returns: A stream whose events are the result of the combination using the specified function of the input stream's value and the value of the cells at the time of the stream event firing.
     */
    public func snapshot<T1, T2, T3, TResult>(c1: Cell<T1>, c2: Cell<T2>, c3: Cell<T3>, f: (T, T1, T2, T3) -> TResult) -> Stream<TResult> {
        let out = Stream<TResult>(keepListenersAlive: self.keepListenersAlive)
        let l = self.listen(out.node, action: { (trans2, a) in out.send(trans2, a: f(a, c1.sampleNoTransaction(), c2.sampleNoTransaction(), c3.sampleNoTransaction()))} )
        return out.unsafeAddCleanup(l)
    }

    /**
     Return a stream whose events are the result of the combination using the specified function of the input stream's value and the value of the cells at the time of the stream event firing.
 
     - Parameter T1: The type of the first cell.
     - Parameter T2: The type of the second cell.
     - Parameter T3: The type of the third cell.
     - Parameter T4: The type of the fourth cell.
     - Parameter TResult: The return type.
     - Parameter c1: The first cell to combine with.
     - Parameter c2: The second cell to combine with.
     - Parameter c3: The third cell to combine with.
     - Parameter c4: The fourth cell to combine with.
     - Parameter f: A function to convert the stream value and cell value into a return value.
     - Returns: A stream whose events are the result of the combination using the specified function of the input stream's value and the value of the cells at the time of the stream event firing.
     */
    public func snapshot<T1, T2, T3, T4, TResult>(c1: Cell<T1>, c2: Cell<T2>, c3: Cell<T3>, c4: Cell<T4>, f: (T, T1, T2, T3, T4) -> TResult) -> Stream<TResult> {
        let out = Stream<TResult>(keepListenersAlive: self.keepListenersAlive)
        let l = self.listen(out.node, action: { (trans2, a) in out.send(trans2, a: f(a, c1.sampleNoTransaction(), c2.sampleNoTransaction(), c3.sampleNoTransaction(), c4.sampleNoTransaction()))} )
        return out.unsafeAddCleanup(l)
    }

    /**
     Merges this stream with another stream and drops the other stream's value in the simultaneous case.
 
     - Parameter s: The stream to merge with.
     - Returns: A stream that is the result of merging this stream with another stream and dropping the other stream's value in the simultaneous case.
     - Remarks: In the case where two stream events are simultaneous (i.e. both within the same transaction), the event value from this stream will take precedence, and the event value from `s` will be dropped.
 
        To specify a custom combining function, use `Stream<T>.merge(Stream<T>, (T, T) -> T)`.   s1.orElse(s2) is equivalent to s1.merge(s2, { $0 }).

        The name orElse is used instead of merge to make it clear that care should be taken because stream events can be dropped.
     */
    public func orElse(s: Stream<T>) -> Stream<T> {
        return self.merge(s, f: { (left, right) in left })
    }

    private func merge(s: Stream<T>) -> Stream<T> {
        let out = Stream<T>(keepListenersAlive: self.keepListenersAlive)
        let left = Node<T>(rank: 0)
        let right = out.node
        let nodeTargets = [left.link( { (t, v) in }, target: right).1]
        let nodeTarget = nodeTargets.first!
        let h = out.send
        let l1 = self.listen(left, action: h)
        let l2 = s.listen(right, action: h)
        return out.unsafeAddCleanup([l1, l2, Listener(unlisten: { left.unlink(nodeTarget) }, refs: self.refs)])
    }

    /**
     Merge two streams of the same type into one, so that stream event values on either input appear on the returned stream.

     - Parameter s: The stream to merge this stream with.
     - Parameter f: Function to combine the values. It may construct FRP logic or use `Cell<T>.sample()`.  Apart from this the function must be pure.
     - Returns: A stream which is the combination of event values from this stream and stream `s`.

     - Remarks: If the events are simultaneous (that is, one event from this stream and one from `s` occurring in the same transaction), combine them into one using the specified combining function so that the returned stream is guaranteed only ever to have one event per transaction.  The event from this stream will appear at the left input of the combining function, and the event from 's` will appear at the right.
     */
    func merge(s: Stream<T>, f: (T, T) -> T) -> Stream<T> {
        return Transaction.apply { trans in self.merge(s).fold(trans, f: f) }
    }

    func fold(trans1: Transaction, f: (T, T) -> T) -> Stream<T> {
        let out = Stream<T>(keepListenersAlive: self.keepListenersAlive)
        let ch = CoalesceHandler<T>()
        let h = ch.create(f, out: out)
        let l = self.listen(out.node, trans: trans1, action: h, suppressEarlierFirings: false)
        return out.unsafeAddCleanup(l)
    }

    /**
     Clean up the output by discarding any firing other than the last one.

     - Parameter trans: The transaction to get the last firing from.
     - Returns:A stream containing only the last event firing from the specified transaction.
    */
    internal func lastFiringOnly(trans: Transaction) -> Stream<T>
    {
        return self.fold(trans, f: { (first, second) in second } )
    }

    /**
     Return a stream that only outputs events for which the predicate returns **true**.

     - Parameter predicate: The predicate used to filter the cell.
     - Returns:A stream that only outputs events for which the predicate returns **true**.
    */
    public func filter(predicate: (T)->Bool) -> Stream<T> {
        let out = Stream<T>(keepListenersAlive: self.keepListenersAlive)
        let l = self.listen(out.node, action: { (trans2, a) in
            if (predicate(a))
            {
                out.send(trans2, a: a)
            }
        })
        return out.unsafeAddCleanup(l)
    }

    /**
     Return a stream that only outputs events from the input stream when the specified cell's value is **true**.

     - Parameter c: The cell that acts as a gate.
     - Returns: A stream that only outputs events from the input stream when the specified cell's value is **true**.
    */
    public func gate<C : CellType where C.Element == Bool>(c: C) -> Stream<T?> {
        return self.snapshot(c, f: {(a: T, pred: Bool) -> T? in return pred ? a : nil })
    }

    /**
     Transform a stream with a generalized state loop (a Mealy machine).  The function is passed the input and the old state and returns the new state and output value.
 
     - Parameter TState: The type of the state of the Mealy machine.
     - Parameter TReturn: The type of the return value.
     - Parameter initialState: The initial state of the Mealy machine.
     - Parameter f: Function to apply to update the state.  It may construct FRP logic or use `Cell<T>.sample()`, in which case it is equivalent to snapshotting the cell with `Snapshot<TReturn>(Cell<TReturn>)`.  Apart from this, the function must be pure.

     - Returns: A stream resulting from the transformation of this stream by the Mealy machine.
    */
    public func collect<TState, TReturn>(initialState: TState , f: (T,TState)->(TReturn,TState)) -> Stream<TReturn> {
        return self.collectLazy(initialState, f: f)
    }

    /**
     Transform a stream with a generalized state loop (a Mealy machine) using a lazily evaluated initial state.  The function is passed the input and the old state and returns the new state and output value.

     - Parameter TState: The type of the state of the Mealy machine.
     - Parameter TReturn: The type of the return value.
     - Parameter initialState: The lazily evaluated initial state of the Mealy machine.
     - Parameter f: Function to apply to update the state.  It may construct FRP logic or use `Cell<T>.sample()`, in which case it is equivalent to snapshotting the cell with `Snapshot<TReturn>(Cell<TReturn>)`.  Apart from this, the function must be pure.

     - Returns: A stream resulting from the transformation of this stream by the Mealy machine.
    */
    public func collectLazy<TState, TReturn>(@autoclosure(escaping) initialState: () -> TState, f: (T,TState) -> (TReturn, TState)) -> Stream<TReturn> {
        return Transaction.noThrowRun({
            let es = StreamLoop<TState>()
            let s = es.holdLazy(initialState)
            let ebs = self.snapshot(s, f: f)
            let eb = ebs.map{ $0.0}
            let esOut = ebs.map{ $0.1}
            es.loop(esOut)
            return eb
        })
    }

    /**
     Accumulate on this stream, outputting the new state each time an event fires.
 
     - Parameter TReturn: The type of the accumulated state.
     - Parameter initialState: The initial state.
     - Parameter f:  Function to apply to update the state.  It may construct FRP logic or use `Cell<T>.sample()`, in which case it is equivalent to snapshotting the cell with `Snapshot{TReturn}(Cell{TReturn})`.  Apart from this, the function must be pure.
     
     - Returns:A cell holding the accumulated state of this stream.
    */
    public func accum(initialState: T, f: (T,T) -> T) -> AnyCell<T>
    { return self.accumLazy(initialState, f: f) }

    public func accumLazy<TReturn>(@autoclosure(escaping) initialState: () -> TReturn, f: (T,TReturn)->TReturn) -> AnyCell<TReturn> {
        return Transaction.noThrowRun(
        {
            let es = StreamLoop<TReturn>()
            let s = es.holdLazy(initialState)
            let esOut = self.snapshot(s, f: f)
            es.loop(esOut)
            return s // esOut.holdLazy(initialState)
        })
    }

    /**
     Return a stream that outputs only one value: the next event of the input stream starting from the transaction in which this method was invoked.

     - Returns: A stream that outputs only one value: the next event of the input stream starting from the transaction in which this method was invoked.
    */
    public func once() -> Stream<T>
    {
        // This is a bit long-winded but it's efficient because it unregisters the listener.
        let out = Stream<T>(keepListenersAlive: self.keepListenersAlive)
        var ls = [Listener]()

        ls.append(self.listen(out.node, action: { (trans, a) in
            out.send(trans, a: a)
            ls.first!.unlisten()
        }))
        
        return out.unsafeAddCleanup(ls.first!)
    }

    /**
     This is not thread-safe, so one of these two conditions must apply:
 
    - Precondition: We are within a transaction, since in the current implementation a transaction locks out all other threads.
    - Precondition: The object on which this is being called was created has not yet been returned from the method where it was created, so it can't be shared between threads.
    */
    internal func unsafeAddCleanup(cleanup: Listener) -> Stream<T>
    {
        self.disposables.append(cleanup)
        return self
    }
    
    internal func unlisten() {
        for d in self.disposables {
            d.unlisten()
        }
    }

    internal func unsafeAddCleanup(ls: [Listener]) -> Stream<T>
    {
        self.disposables.appendContentsOf(ls)
        return self
    }

    public func send(trans: Transaction, a: T)
    {
        if (self.firings.isEmpty)
        {
            trans.last({ self.firings.removeAll() })
        }
        self.firings.append(a)

        let targets = Set<NodeTarget<T>>(self.node.getListeners())
        for target in targets {
            trans.prioritized(target.node) { trans2 in
                Transaction.inCallback += 1
                defer { Transaction.inCallback -= 1 }
                // Don't allow transactions to interfere with Sodium internals.
                // Dereference the weak reference
                // If it hasn't been garbage collected, call it.
                target.action(trans2, a)
                //}
                //else
                //{
                    // If it has been garbage collected, remove it.
                //    self.node.RemoveListener(target)
                //}
            }
        }
    }
}

extension Stream where T:Equatable {
    /**
     Return a stream that only outputs events which have a different value than the previous event.
     
     - Returns:A stream that only outputs events which have a different value than the previous event.
     */
    public func calm() -> Stream<T> {
        return Stream.filterMaybe(self.collectLazy(nil, f: { (a, lastA) -> (T?, T?) in
            if (a == lastA) ?? false {
                return (nil, a) // same, don't collect
            }
            else {
                return (a, a)   // different (or nil lastA)
            }
        }))
    }

    /**
     Return a stream that only outputs events which have a different value than the previous event.
     
     - Returns:A stream that only outputs events which have a different value than the previous event.
     */
    public func calm(last: T) -> Stream<T> {
        return Stream.filterMaybe(self.collectLazy(last, f: { (a, lastA) -> (T?, T?) in
            if (a == lastA) ?? false {
                return (nil, a) // same, don't collect
            }
            else {
                return (a, a)   // different (or nil lastA)
            }
        }))
    }

    /*
     
     
     /*
     *      Return a stream that only outputs events which have a different value than the previous event.
     */
     - Parameter comparer: The equality comparer to use to determine if two items are equal.
     - Returns:A stream that only outputs events which have a different value than the previous event.
     public func calm(IEqualityComparer<T> comparer) -> Stream<T> {
     return self.Calm(Lazy<IMaybe<T>>(Maybe.Nothing<T>), comparer)
     }
     
     internal func calm(Lazy<IMaybe<T>> init, IEqualityComparer<T> comparer) -> Stream<T> {
     return self.CollectLazy(init, (a, lastA) =>
     {
     if (lastA.Match(v => comparer.Equals(v, a), () => false))
     {
     return Tuple.Create(Maybe.Nothing<T>(), lastA)
     }
     
     IMaybe<T> ma = Maybe.Just(a)
     return Tuple.Create(ma, ma)
     }).FilterMaybe()
     }
     */
    
    /// <summary>
    ///     Return a stream that only outputs events that have values, removing the <see cref="IMaybe{T}" /> wrapper, and
    ///     discarding <see cref="Maybe.Nothing{T}()" /> values.
    /// </summary>
    /// <param name="s">The stream of <see cref="IMaybe{T}" /> values to filter.</param>
    /// <returns>
    ///     A stream that only outputs events that have values, removing the <see cref="IMaybe{T}" /> wrapper, and
    ///     discarding <see cref="Maybe.Nothing{T}()" /> values.
    /// </returns>
    public static func filterMaybe<T>(s: Stream<T?>) -> Stream<T> {
        let out = Stream<T>(keepListenersAlive: s.keepListenersAlive)
        let l = s.listen(out.node, action: { (trans2, a) in
            if a != nil { out.send(trans2, a: a!)
            }})
        
        return out.unsafeAddCleanup(l)
    }

}

class ListenerImplementation<T> : Listener
{
    typealias Action = (Transaction, T) -> Void
    // It's essential that we keep the action alive, since the node uses a weak reference.
    private let action: Action
    // It's essential that we keep the listener alive while the caller holds the Listener, so that the garbage collector doesn't get triggered.
    private let stream: Stream<T>
    
    private let target: NodeTarget<T>
    
    init(stream: Stream<T>, action: Action, target: NodeTarget<T>, refs: MemReferences? = nil) {
        self.stream = stream
        self.action = action
        self.target = target
        super.init(unlisten: { }, refs: refs)
    }
    
    internal override func unlisten()
    {
        self.stream.node.unlink(self.target)
    }
}

private class KeepListenersAliveImplementation : IKeepListenersAlive
{
    private var listeners = Set<Listener>()
    private var childKeepListenersAliveList = Array<IKeepListenersAlive>()
    
    func keepListenerAlive(listener: Listener) {
        self.listeners.insert(listener)
    }
    
    func stopKeepingListenerAlive(listener: Listener) {
        self.listeners.remove(listener)
    }
    
    func use(childKeepListenersAlive: IKeepListenersAlive) {
        self.childKeepListenersAliveList.append(childKeepListenersAlive)
    }
}
