import Capacitor

@objc(PomoBridgeViewController)
final class PomoBridgeViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(PomoLiveActivityPlugin())
    }
}
