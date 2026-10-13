import Capacitor

@objc(PomoBridgeViewController)
final class PomoBridgeViewController: CAPBridgeViewController {
    override public func capacitorDidLoad() {
        bridge?.registerPluginInstance(PomoLiveActivityPlugin())
    }
}
