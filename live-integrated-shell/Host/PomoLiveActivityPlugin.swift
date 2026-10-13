import ActivityKit
import Capacitor
import Foundation

@objc(PomoLiveActivityPlugin)
public class PomoLiveActivityPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "PomoLiveActivityPlugin"
    public let jsName = "PomoLiveActivity"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "sync", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "status", returnType: CAPPluginReturnPromise)
    ]

    @objc func status(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else {
            call.resolve(["supported": false, "enabled": false, "activeCount": 0])
            return
        }
        call.resolve([
            "supported": true,
            "enabled": ActivityAuthorizationInfo().areActivitiesEnabled,
            "activeCount": Activity<PomoLiveAttributes>.activities.count
        ])
    }

    @objc func sync(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else {
            call.resolve(["supported": false, "enabled": false, "activeCount": 0])
            return
        }

        let enabled = ActivityAuthorizationInfo().areActivitiesEnabled
        guard enabled else {
            call.resolve(["supported": true, "enabled": false, "activeCount": Activity<PomoLiveAttributes>.activities.count])
            return
        }

        let hasActive = call.getBool("hasActive") ?? false
        let sessionID = call.getString("sessionID") ?? ""
        let kind = call.getString("kind") ?? "focus"
        let category = call.getString("category") ?? ""
        let species = call.getString("species") ?? ""
        let endsAtMs = call.getDouble("endsAt") ?? 0
        let remainingMs = call.getDouble("remainingMs") ?? 0
        let paused = call.getBool("paused") ?? false

        Task { @MainActor in
            do {
                if !hasActive || sessionID.isEmpty || remainingMs <= 0 {
                    await self.endAllActivities()
                    call.resolve(["supported": true, "enabled": true, "activeCount": 0, "state": "ended"])
                    return
                }

                let endDate = Date(timeIntervalSince1970: endsAtMs / 1000)
                let contentState = PomoLiveAttributes.ContentState(
                    kind: kind,
                    category: category,
                    species: species,
                    endDate: endDate,
                    remainingSeconds: max(0, Int(ceil(remainingMs / 1000))),
                    isPaused: paused
                )
                let content = ActivityContent(
                    state: contentState,
                    staleDate: paused ? nil : endDate.addingTimeInterval(60),
                    relevanceScore: 100
                )

                if let existing = Activity<PomoLiveAttributes>.activities.first(where: { $0.attributes.sessionID == sessionID }) {
                    for other in Activity<PomoLiveAttributes>.activities where other.id != existing.id {
                        await self.end(other)
                    }
                    await existing.update(content)
                    call.resolve([
                        "supported": true,
                        "enabled": true,
                        "activeCount": Activity<PomoLiveAttributes>.activities.count,
                        "activityID": existing.id,
                        "state": paused ? "paused" : "active"
                    ])
                    return
                }

                await self.endAllActivities()
                let activity = try Activity.request(
                    attributes: PomoLiveAttributes(sessionID: sessionID),
                    content: content,
                    pushType: nil
                )
                call.resolve([
                    "supported": true,
                    "enabled": true,
                    "activeCount": Activity<PomoLiveAttributes>.activities.count,
                    "activityID": activity.id,
                    "state": paused ? "paused" : "active"
                ])
            } catch {
                call.reject("Live Activity sync failed: \(error.localizedDescription)", nil, error)
            }
        }
    }

    @available(iOS 16.2, *)
    @MainActor
    private func endAllActivities() async {
        for activity in Activity<PomoLiveAttributes>.activities {
            await end(activity)
        }
    }

    @available(iOS 16.2, *)
    @MainActor
    private func end(_ activity: Activity<PomoLiveAttributes>) async {
        let state = activity.content.state
        await activity.end(
            ActivityContent(state: state, staleDate: nil),
            dismissalPolicy: .immediate
        )
    }
}
