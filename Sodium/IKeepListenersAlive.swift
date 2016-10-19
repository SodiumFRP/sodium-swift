internal protocol IKeepListenersAlive
{
    func keepListenerAlive(_ listener: Listener)
    func stopKeepingListenerAlive(_ listener : Listener)
    func use(_ childKeepListenersAlive: IKeepListenersAlive)
}
