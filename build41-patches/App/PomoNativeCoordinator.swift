import Foundation
import UserNotifications

final class PomoNativeCoordinator {
    static let shared = PomoNativeCoordinator()

    static let saveKey = "little-grove-v1"
    private let notificationID = "pomoland.session.complete"
    private var lastState: [String: Any]?

    private init() {}

    func savedState() -> String? {
        if let raw = UserDefaults.standard.string(forKey: Self.saveKey) {
            return raw
        }
        if let raw = UserDefaults.standard.string(forKey: "CapacitorStorage.\(Self.saveKey)") {
            return raw
        }
        if let legacy = UserDefaults(suiteName: "CapacitorStorage"),
           let raw = legacy.string(forKey: Self.saveKey) {
            return raw
        }
        return nil
    }

    func restoreTimerState() {
        guard
            let raw = savedState(),
            let data = raw.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data),
            let state = json as? [String: Any]
        else {
            return
        }

        lastState = state
        syncTimers(from: state)
    }

    func prepareNotifications() {
        // The web timer saves its freshly-created active state immediately after this
        // request. Do not re-sync the previous state from this asynchronous callback:
        // doing so can race the new timer and immediately end its Live Activity.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func persistAndSync(state: [String: Any]) {
        lastState = state

        if JSONSerialization.isValidJSONObject(state),
           let data = try? JSONSerialization.data(withJSONObject: state),
           let raw = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(raw, forKey: Self.saveKey)
        }

        syncTimers(from: state)
    }

    private func syncTimers(from state: [String: Any]) {
        let active = state["active"] as? [String: Any]
        scheduleCompletionNotification(active: active)
        PomoLiveActivityManager.shared.sync(active: active)
    }

    private func scheduleCompletionNotification(active: [String: Any]?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])

        guard
            let active,
            (active["preview"] as? Bool) != true,
            (active["paused"] as? Bool) != true,
            let endsAtMs = number(active["endsAt"])
        else { return }

        let fireDate = Date(timeIntervalSince1970: endsAtMs / 1000.0)
        guard fireDate > Date() else { return }

        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else { return }

            let content = UNMutableNotificationContent()
            let isBreak = (active["kind"] as? String) == "break"
            content.title = isBreak ? "A little time to grow." : "A little more life."
            content.body = isBreak
                ? "Your five-minute break is complete. Ready when you are."
                : "Your focus session is complete. Come see what grew."
            content.sound = .default

            let delay = max(1, fireDate.timeIntervalSinceNow)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let request = UNNotificationRequest(
                identifier: self.notificationID,
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    private func number(_ value: Any?) -> Double? {
        if let n = value as? NSNumber { return n.doubleValue }
        if let n = value as? Double { return n }
        if let n = value as? Int { return Double(n) }
        return nil
    }
}
