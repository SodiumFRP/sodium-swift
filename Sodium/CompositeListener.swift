open class CompositeListener : Listener
{
    // TODO: MemReferences
    fileprivate var listeners: [Listener]

    public convenience init()
    {
        self.init(listeners: nil)
    }

    public init(listeners: [Listener]?)
    {
        self.listeners = listeners ?? []
        super.init(unlisten: {}, refs: nil)
    }

    open func add(_ l: Listener) {
        self.listeners.append(l)
    }

    open func addRange<S : Sequence>(_ ls: S) where S.Iterator.Element == Listener {
        self.listeners.append(contentsOf: ls)
    }

    open override func unlisten() {
        for l in self.listeners {
            l.unlisten()
        }
    }
}
