/**
    An interface representing an stream event listener.  This may be used to stop listening on a stream by either disposing it or calling `Unlisten`.
 
    - Remarks: Disposing of the listener has the same effect as calling `unlisten`.  Only one or the other needs to be called to cause the listener to stop listening.  Otherwise, objects implementing this interface do not need to be disposed.
*/
public protocol ListenerType: Hashable
{
    func unlisten()
}
