import Foundation
import ActivityKit

final class PomoLiveActivityManager {
    static let shared = PomoLiveActivityManager()

    private var lastStatus = "No Live Activity sync has run yet."
    private var lastError: String?
    private var lastLiveID: String?

    private init() {}

    @available(iOS 16.2, *)
    private func activity(for liveID: String) -> Activity<PomoActivityAttributes>? {
        Activity<PomoActivityAttributes>.activities.first {
            $0.attributes.liveID == liveID
        }
    }

    func diagnostics() -> [String: Any] {
        guard #available(iOS 16.2, *) else {
            return [
                "supported": false,
                "enabled": false,
                "activeCount": 0,
                "status": "This iOS version does not support Live Activities.",
                "error": ""
            ]
        }

        let activities = Activity<PomoActivityAttributes>.activities
        return [
            "supported": true,
            "enabled": ActivityAuthorizationInfo().areActivitiesEnabled,
            "activeCount": activities.count,
            "activeIDs": activities.map { $0.id },
            "activeLiveIDs": activities.map { $0.attributes.liveID },
            "status": lastStatus,
            "error": lastError ?? "",
            "lastLiveID": lastLiveID ?? ""
        ]
    }

    func sync(active: [String: Any]?) {
        guard #available(iOS 16.2, *) else {
            lastStatus = "Sync skipped: iOS does not support Live Activities."
            return
        }

        Task {
            guard let active else {
                lastStatus = "Sync received no active timer; ending PomoLand Live Activities."
                lastError = nil
                lastLiveID = nil
                await endAll()
                return
            }

            if (active["preview"] as? Bool) == true {
                lastStatus = "Preview timer received; Live Activity intentionally not started."
                lastError = nil
                await endAll()
                return
            }

            // Normal focus timers in the original PomoLand web app do not carry a
            // `kind` field; breaks do. Treat a missing kind as focus instead of
            // rejecting the timer state. This was the main reason diagnostic Live
            // Activities worked while real Pomodoros did not.
            let phase = (active["phase"] as? String) ?? ""
            let isOvertime = phase == "spillover"
            let isWaiting = phase == "spillover-prompt"
            let kind = isOvertime ? "spillover" : (isWaiting ? "spillover-ready" : ((active["kind"] as? String) ?? "focus"))

            guard
                let liveID = active["liveID"] as? String,
                let durationMs = number(active["durationMs"]),
                let remainingMs = number(active["remainingMs"])
            else {
                lastStatus = "Timer state reached native code but required Live Activity fields were missing."
                lastError = "Required fields: liveID, durationMs, remainingMs"
                await endAll()
                return
            }

            lastLiveID = liveID
            let paused = (active["paused"] as? Bool) ?? false
            let now = Date()
            let durationSeconds = max(1, Int((durationMs / 1000.0).rounded()))
            let remainingSeconds: Int
            let endDate: Date

            if isOvertime {
                // Count up from the beginning of the current uninterrupted segment,
                // including previously accrued time from earlier pause/resume cycles.
                let previousMs = max(0, number(active["spilloverElapsedMs"]) ?? 0)
                let beganMs = number(active["spilloverStartedAt"]) ?? now.timeIntervalSince1970 * 1000
                let additionalMs = paused ? 0 : max(0, now.timeIntervalSince1970 * 1000 - beganMs)
                remainingSeconds = max(0, Int((previousMs + additionalMs) / 1000))
                endDate = now.addingTimeInterval(86400)
            } else if isWaiting {
                remainingSeconds = 0
                endDate = now
            } else if paused {
                remainingSeconds = max(0, Int((remainingMs / 1000.0).rounded(.up)))
                endDate = now.addingTimeInterval(TimeInterval(remainingSeconds))
            } else if let endsAt = number(active["endsAt"]) {
                endDate = Date(timeIntervalSince1970: endsAt / 1000.0)
                remainingSeconds = max(0, Int(endDate.timeIntervalSince(now).rounded(.up)))
            } else {
                remainingSeconds = max(0, Int((remainingMs / 1000.0).rounded(.up)))
                endDate = now.addingTimeInterval(TimeInterval(remainingSeconds))
            }

            if !paused && !isOvertime && remainingSeconds <= 0 {
                lastStatus = "Timer reached native code but was already expired; ending Live Activity."
                lastError = nil
                await endAll()
                return
            }

            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                lastStatus = "Timer reached native code, but iOS reports Live Activities disabled for PomoLand."
                lastError = "ActivityAuthorizationInfo.areActivitiesEnabled = false"
                return
            }

            let elapsed = isOvertime ? remainingSeconds : max(0, durationSeconds - remainingSeconds)
            let startDate = now.addingTimeInterval(TimeInterval(-elapsed))

            let state = PomoActivityAttributes.ContentState(
                kind: kind,
                category: (active["category"] as? String) ?? "",
                species: (active["species"] as? String) ?? "",
                startDate: startDate,
                endDate: endDate,
                remainingSeconds: remainingSeconds,
                durationSeconds: durationSeconds,
                isPaused: paused
            )

            for existing in Activity<PomoActivityAttributes>.activities
            where existing.attributes.liveID != liveID {
                await existing.end(
                    ActivityContent(state: existing.content.state, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            }

            if let existing = activity(for: liveID) {
                await existing.update(
                    ActivityContent(
                        state: state,
                        staleDate: (paused || isOvertime || isWaiting) ? nil : endDate,
                        relevanceScore: kind == "break" ? 0.7 : 1.0
                    )
                )
                lastStatus = "Updated existing timer Live Activity."
                lastError = nil
            } else {
                do {
                    let requested = try Activity<PomoActivityAttributes>.request(
                        attributes: PomoActivityAttributes(liveID: liveID),
                        content: ActivityContent(
                            state: state,
                            staleDate: paused ? nil : endDate,
                            relevanceScore: kind == "break" ? 0.7 : 1.0
                        ),
                        pushType: nil
                    )
                    lastStatus = "Timer Activity.request succeeded. Activity id: \(requested.id)"
                    lastError = nil
                } catch {
                    lastStatus = "Timer Activity.request failed."
                    lastError = String(describing: error)
                    print("PomoLand Live Activity start failed: \(error)")
                }
            }
        }
    }

    func startDiagnosticActivity() async -> [String: Any] {
        guard #available(iOS 16.2, *) else { return diagnostics() }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            lastStatus = "Diagnostic test stopped because iOS reports Live Activities disabled."
            lastError = "ActivityAuthorizationInfo.areActivitiesEnabled = false"
            return diagnostics()
        }

        await endAll()

        let now = Date()
        let endDate = now.addingTimeInterval(300)
        let liveID = "diagnostic-\(Int(now.timeIntervalSince1970 * 1000))"
        lastLiveID = liveID
        let state = PomoActivityAttributes.ContentState(
            kind: "focus",
            category: "diagnostic",
            species: "test",
            startDate: now,
            endDate: endDate,
            remainingSeconds: 300,
            durationSeconds: 300,
            isPaused: false
        )

        do {
            let requested = try Activity<PomoActivityAttributes>.request(
                attributes: PomoActivityAttributes(liveID: liveID),
                content: ActivityContent(
                    state: state,
                    staleDate: endDate,
                    relevanceScore: 1.0
                ),
                pushType: nil
            )
            lastStatus = "Diagnostic Activity.request succeeded. Lock the phone now. Activity id: \(requested.id)"
            lastError = nil
        } catch {
            lastStatus = "Diagnostic Activity.request failed."
            lastError = String(describing: error)
        }

        return diagnostics()
    }

    func endDiagnosticActivities() async -> [String: Any] {
        guard #available(iOS 16.2, *) else { return diagnostics() }
        await endAll()
        lastStatus = "Ended all PomoLand Live Activities."
        lastError = nil
        lastLiveID = nil
        return diagnostics()
    }

    @available(iOS 16.2, *)
    private func endAll() async {
        for activity in Activity<PomoActivityAttributes>.activities {
            let final = activity.content.state
            await activity.end(
                ActivityContent(state: final, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
    }

    private func number(_ value: Any?) -> Double? {
        if let n = value as? NSNumber { return n.doubleValue }
        if let n = value as? Double { return n }
        if let n = value as? Int { return Double(n) }
        return nil
    }
}
