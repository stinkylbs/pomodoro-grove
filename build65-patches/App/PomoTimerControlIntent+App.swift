import Foundation

@available(iOS 17.0, *)
extension PomoTimerControlIntent {
    @MainActor
    func togglePomoTimer() async {
        guard let raw = PomoNativeCoordinator.shared.savedState(),
              let data = raw.data(using: .utf8),
              let decoded = try? JSONSerialization.jsonObject(with: data),
              var state = decoded as? [String: Any],
              var active = state["active"] as? [String: Any],
              let existingID = active["liveID"] as? String,
              existingID == liveID else { return }

        let nowMs = Date().timeIntervalSince1970 * 1000.0
        let paused = (active["paused"] as? Bool) ?? false
        if (active["phase"] as? String) == "spillover" {
            let elapsed = (active["spilloverElapsedMs"] as? NSNumber)?.doubleValue ?? 0
            if paused {
                active["spilloverStartedAt"] = nowMs
                active["paused"] = false
            } else {
                let started = (active["spilloverStartedAt"] as? NSNumber)?.doubleValue ?? nowMs
                active["spilloverElapsedMs"] = max(0, elapsed + max(0, nowMs - started))
                active["paused"] = true
            }
        } else {
            if paused {
                guard let remaining = (active["remainingMs"] as? NSNumber)?.doubleValue,
                      remaining > 0 else { return }
                active["endsAt"] = nowMs + remaining
                active["paused"] = false
            } else {
                guard let endMs = (active["endsAt"] as? NSNumber)?.doubleValue else { return }
                let remaining = max(0, endMs - nowMs)
                guard remaining > 0 else { return }
                active["remainingMs"] = remaining
                active["paused"] = true
            }
        }
        state["active"] = active
        state["savedAt"] = nowMs
        PomoNativeCoordinator.shared.persistAndSync(state: state)
        NotificationCenter.default.post(name: Notification.Name("pomoland.nativeTimerUpdated"), object: nil)
    }
}
