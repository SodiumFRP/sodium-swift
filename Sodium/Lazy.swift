/**
 #  Lazy.swift
##  Sodium

 - Author: Andrew Bradnan
 - Date: 5/4/16
 - Copyright: © 2016 Whirlygig Ventures. All rights reserved.
*/

/**
 A representation for a value that may not be available until the current transaction is closed.
 */
open class Lazy<A> {

    public init(f: @escaping () -> A) { self.f = f; }
    public init(a: A) { self.f = { a } }
    fileprivate let f: () -> A
    
    /**
     Get the value if available, throwing an exception if not.  In the general case this should only be used in subsequent transactions to when the Lazy was obtained.
    */
    public final func get() -> A {
        return f()
    }
    
    /**
     Map the lazy value according to the specified function, so the returned Lazy reflects the value of the function applied to the input Lazy's value.
     - Parameter f: Function to apply to the contained value. It must be **referentially transparent**.
    */
    public final func map<B>(_ f: @escaping (A) -> B) -> Lazy<B> {
        return Lazy<B>(f: { f(self.get()) })
    }
    
    /**
     Lift a binary function into lazy values, so the returned Lazy reflects the value of the function applied to the input Lazys' values.
    */
    public final func lift <B,C>(_ b: Lazy<B>, f: @escaping (A,B) -> C) -> Lazy<C> {
        return Lazy<C>(f: { f(self.get(), b.get()) })
    }
    
    /**
     Lift a ternary function into lazy values, so the returned Lazy reflects the value of the function applied to the input Lazys' values.
    */
    public final func lift<B,C,D>(_ b: Lazy<B>, c: Lazy<C>, f: @escaping (A,B,C) ->D) -> Lazy<D>
    {
        return Lazy<D>(f: { f(self.get(), b.get(), c.get()) } )
    }
    
    /**
    * Lift a quaternary function into lazy values, so the returned Lazy reflects
    * the value of the function applied to the input Lazys' values.
    */
    public final func lift<B,C,D,E>(_ b: Lazy<B>, c: Lazy<C>, d: Lazy<D>, f: @escaping (A,B,C,D) -> E) -> Lazy<E> {
        return Lazy<E>(f: { f(self.get(), b.get(), c.get(), d.get()) } )
    }
}

