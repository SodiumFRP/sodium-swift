import Foundation

typealias Block = () -> Void
typealias Action = () throws -> Void
public typealias TV = (Transaction) throws -> Void
public typealias OTV = (Transaction?) throws -> Void

let nop: Block = {}

/**
 # Transaction
 A class for managing transactions.
 */
public final class Transaction
{
    // Coarse-grained lock that's held during the whole transaction.
    fileprivate static let transactionLock = NSObject()
    
    fileprivate static var currentTransaction: Transaction?
    fileprivate static var OnStartHooks = Array<Action>()
    fileprivate static var runningOnStartHooks: Bool = false

    fileprivate var entries = Set<Entry>()
    fileprivate var lastQueue = Array<Action>()
    fileprivate var postQueue = Dictionary<Int, OTV>()

    fileprivate let prioritizedQueue = PriorityQueue<Entry>(comparator: >)
    static var inCallback = 0
    
    // True if we need to re-generate the priority queue.
    fileprivate var toRegen = false

    init() {
    }
    
    /// - Returns: The current transaction as an option type.
    internal static func getCurrentTransaction() -> Transaction?
    {
        objc_sync_enter(transactionLock)
        defer { objc_sync_exit(transactionLock) }

        return currentTransaction
    }

    /// - Returns: whether or not there is a current transaction.
    internal static func hasCurrentTransaction() -> Bool
    {
        objc_sync_enter(transactionLock)
        defer { objc_sync_exit(transactionLock) }

        return currentTransaction != nil
    }

    /**
     Execute the specified action inside a single transaction.
     
     - Parameter action: The action to execute.
     
     - Remarks: In most cases this is not needed, because all primitives will create their own transaction automatically.  It is useful for running multiple reactive operations atomically.
     */
    internal static func runVoid(_ action: Action) {
        go { try action() }
    }

    public static func noThrowRun<T>(_ f: () -> T) -> T {
        return go { f() }!
    }
    
    public static func cantBeInSend() {
        if Transaction.inCallback > 0 {
            fatalError("Send() may not be called inside a Sodium callback.")
        }
    }
    
    /**
     Execute the specified function inside a single transaction.

     - Parameter T: The type of the value returned.
     - Parameter f: The function to execute.
     - Returns: The return value of `f`.
     - Remarks: In most cases this is not needed, because all primitives will create their own transaction automatically. It is useful for running multiple reactive operations atomically.
     */
    public static func run<T>(_ f: () throws -> T) -> T?
    {
        return go { try f() }
    }

    public static func run(_ code: TV) {
        go( { try code(startIfNecessary())})
    }

    static func go<R>(_ code: () throws -> R) -> R? {
        objc_sync_enter(transactionLock)
        defer { objc_sync_exit(transactionLock) }
        
        
        // If we are already inside a transaction (which must be on the same
        // thread otherwise we wouldn't have acquired transactionLock), then
        // keep using that same transaction.
        let transWas = currentTransaction
        startIfNecessary()
        
        defer
        {
            do
            {
                if (transWas == nil) {
                    try currentTransaction?.close()
                }
            }
            catch
            {
            }
            currentTransaction = transWas
        }

        do
        {
            return try code()
        }
        catch
        {
        }
        return nil
    }

    internal static func apply<T>(_ code: (Transaction) -> T) -> T {
        return go { code(startIfNecessary()) }!
    }

    internal static func apply<T>(_ code: (Transaction) throws -> T) -> T? {
        return go { try code(startIfNecessary()) }
    }

    /**
     Add an action that will be executed whenever a transaction is started.

     - Parameter action:
     - Remarks: The action may start transactions itself, which will not cause the hooks to execute recursively.  The main use case of this is for the implementation of a time/alarm system.
     */
    internal static func onStart(_ action: @escaping Action) {
        objc_sync_enter(transactionLock)
        defer { objc_sync_exit(transactionLock) }

        OnStartHooks.append(action)
    }

    fileprivate static func startIfNecessary() -> Transaction {
        if (currentTransaction == nil) {
            if (!runningOnStartHooks) {
                runningOnStartHooks = true
                do {
                    for action in OnStartHooks {
                        try action()
                    }
                }
                catch {
                }
                runningOnStartHooks = false
            }

            currentTransaction = Transaction()
        }
        return currentTransaction!
    }

    internal func prioritized(_ rank: INode, action: @escaping TV) {
        let e = Entry(rank: rank, action: action)
        self.prioritizedQueue.push(e)
        self.entries.insert(e)
    }

    /**
     Add an action to run after all prioritized actions.
 
     - Parameter action: The action to run after all prioritized actions.
    */
    internal func last(_ action: @escaping Action) {
        self.lastQueue.append(action)
    }

    /**
     Add an action to run after all last actions.

     - Parameter index: The order index in which to run the action.
     - Parameter action: The action to run after all last actions.
     */
    internal func post(_ index: Int, action: @escaping OTV) {
        // If an entry exists already, combine the old one with the new one.
        var a = action
        if let existing = self.postQueue[index] {
            a = { trans in
                try existing(trans)
                try action(trans)
            }
        }

        self.postQueue[index] = a
    }

    /**
     Execute an action after the current transaction is closed or immediately if there is no current transaction.

     - Parameter action: The action to run after the current transaction is closed or immediately if there is no current transaction.
     */
    public static func post(_ action: @escaping OTV) {
        // -1 will mean it runs before anything split/deferred, and will run outside a transaction context.
        // TODO: make enum for post
        self.run { trans in trans.post(-1, action: action) }
    }

    internal func setNeedsRegenerating() {
        self.toRegen = true
    }

    /// If the priority queue has entries in it when we modify any of the nodes' ranks, then we need to re-generate it to make sure it's up-to-date.
    fileprivate func checkRegen() {
        if (self.toRegen) {
            self.toRegen = false
            self.prioritizedQueue.removeAll()
            for e in self.entries {
                self.prioritizedQueue.push(e)
            }
        }
    }

    internal func close() throws {
        while true {
            self.checkRegen()

            if self.prioritizedQueue.isEmpty {
                break
            }

            let e = self.prioritizedQueue.pop()
            self.entries.remove(e!)
            try e!.action(self)
        }

        for action in self.lastQueue {
            try action()
        }
        self.lastQueue.removeAll()

        for pair in self.postQueue {
            let parent = Transaction.currentTransaction
            
            defer {
                do {
                    if (parent == nil) {
                        try Transaction.currentTransaction?.close()
                    }
                }
                catch {
                }
                Transaction.currentTransaction = parent
            }

            do
            {
                if (pair.0 < 0)
                {
                    Transaction.currentTransaction = nil
                    try pair.1(nil)
                }
                else
                {
                    let transaction = Transaction()
                    defer { do { try transaction.close() } catch {} }
                    
                    Transaction.currentTransaction = transaction
                    do { try pair.1(transaction) } catch {}
                }
            }
            catch {
            }
        }
        self.postQueue.removeAll()
    }

    class Entry : Comparable, Hashable, CustomStringConvertible
    {
        let rank: INode
        let action: TV
        let seq: Int64
        
        var hashValue: Int { return Int(seq) }

        init(rank: INode, action: @escaping TV) {
            self.rank = rank
            self.action = action
            self.seq = OSAtomicAdd64(1, &nextSeq)
        }
        
        var description: String { return rank.rank.description }
    }
}

func ==(lhs: Transaction.Entry, rhs: Transaction.Entry) -> Bool {
    return lhs.rank == rhs.rank && lhs.seq == rhs.seq
}
func <(lhs: Transaction.Entry, rhs: Transaction.Entry) -> Bool {
    if lhs.rank < rhs.rank { return true }
    if lhs.rank == rhs.rank && lhs.seq < rhs.seq { return true }
    return false
}
func <=(lhs: Transaction.Entry, rhs: Transaction.Entry) -> Bool {
    if lhs.rank < rhs.rank { return true }
    if lhs.rank == rhs.rank && lhs.seq <= rhs.seq { return true }
    return false
}
func >=(lhs: Transaction.Entry, rhs: Transaction.Entry) -> Bool {
    if lhs.rank > rhs.rank { return true }
    if lhs.rank == rhs.rank && lhs.seq >= rhs.seq { return true }
    return false
}
func >(lhs: Transaction.Entry, rhs: Transaction.Entry) -> Bool {
    if lhs.rank > rhs.rank { return true }
    if lhs.rank == rhs.rank && lhs.seq > rhs.seq { return true }
    return false
}

var nextSeq = Int64(0)
