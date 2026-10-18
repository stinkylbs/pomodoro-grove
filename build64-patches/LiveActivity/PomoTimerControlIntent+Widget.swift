import Foundation

// LiveActivityIntent runs in the app process. This stub permits the widget
// target to reference the shared intent type without linking app-specific code.
@available(iOS 17.0, *)
extension PomoTimerControlIntent {
    @MainActor
    func togglePomoTimer() async {}
}
