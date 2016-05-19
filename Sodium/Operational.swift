class Operational
{
    /**
     A stream that gives the updates/steps for a cell.

    - Parameter T: The type of the values in the cell.
     - Parameter c: 
     - Returns:
     - Remarks: This is an **OPERATIONAL** primitive, which is not part of the main Sodium API.  It breaks the property of non-detectability of cell steps/updates.  The rule with this primitive is that you should only use it in functions that do not allow the caller to detect the cell updates.
     */
    static func updates<T>(c: Cell<T>) -> Stream<T> {
        return Transaction.apply(c.updates)
    }

    /**
     A stream that is guaranteed to fire once upon listening, giving the current value of a cell, and thereafter gives the updates/steps for the cell.

     - Parameter C.Element: The type of the values in the cell.
     - Parameter c: Cell
     - Returns:
     - Remarks: This is an **OPERATIONAL** primitive, which is not part of the main Sodium API.  It breaks the property of non-detectability of cell steps/updates.  The rule with this primitive is that you should only use it in functions that do not allow the caller to detect the cell updates.
     */
    static func value<C:CellType>(c: C) -> Stream<C.Element> {
        return Transaction.apply(c.value)
    }

    /**
     Push each stream event onto a new transaction guaranteed to come before the next externally initiated transaction.  Same as `Split{T, TCollection}(Stream{TCollection})` but it works on a single value.

     - Parameter T: The type of the stream to defer.
     - Parameter s: The stream to defer.
     - Returns: A stream firing the deferred event firings.
    */
    static func Defer<T>(s: Stream<T>) -> Stream<T>
    {
        return split(s.map{ [$0] })
    }

    /**
     Push each stream event in the list of streams onto a newly created transaction guaranteed to come before the next externally initiated transaction.  Note that the semantics are such that two different invocations of this method can put stream events into the same new transaction, so the resulting stream's events could be simultaneous with events output by split<T,TCollection>(Stream<TCollection>) or Defer<T>(Stream<T>)invoked elsewhere in the code.

     - Parameter T: The collection item type of the stream to split.
     - Parameter S: The collection type of the stream to split.
     - Parameter s: The stream to split.
     - Returns: A stream firing the split event firings.
     */
    static func split<T, S: SequenceType where S.Generator.Element == T>(s: Stream<S>) -> Stream<T>
    {
        let out = Stream<T>(keepListenersAlive: s.keepListenersAlive)
        let l1 = s.listen(out.node, action: { (trans, aa, dbg) in
            var childIx = 0
            for a in aa {
                trans.post(childIx, action: { trans1 in out.send(trans1!, a: a) })
                childIx += 1
            }
        })
        return out.unsafeAddCleanup(l1)
    }
}
