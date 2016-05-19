/**
 # Unit
 A class representing the unit type (similar to *void*).
 */
public final class Unit: Equatable
{
    /// The singleton value of type `Unit`.
    public static let value = Unit()

    private init() {
    }

    var hashValue : Int { return 1 }
}

public func ==(lhs: Unit, rhs: Unit) -> Bool {
    return rhs === lhs
}
