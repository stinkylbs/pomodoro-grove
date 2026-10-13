import ActivityKit
import Foundation

@MainActor
final class StaticLiveActivityController: ObservableObject {
    @Published var status = "Ready"
    @Published var activityID = "—"
    @Published var activeCount = 0

    private var activity: Activity<PomoStaticAttributes>?

    func refresh() {
        guard #available(iOS 16.2, *) else {
            status = "Requires iOS 16.2+"
            return
        }
        activeCount = Activity<PomoStaticAttributes>.activities.count
        if let first = Activity<PomoStaticAttributes>.activities.first {
            activity = first
            activityID = first.id
        }
    }

    func start() {
        guard #available(iOS 16.2, *) else {
            status = "Requires iOS 16.2+"
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            status = "Live Activities disabled in Settings"
            return
        }

        Task {
            await endCurrent()
            do {
                let requested = try Activity.request(
                    attributes: PomoStaticAttributes(testID: UUID().uuidString),
                    content: ActivityContent(
                        state: PomoStaticAttributes.ContentState(message: "STATIC RENDER"),
                        staleDate: nil,
                        relevanceScore: 100
                    ),
                    pushType: nil
                )
                activity = requested
                activityID = requested.id
                activeCount = Activity<PomoStaticAttributes>.activities.count
                status = "REQUEST SUCCEEDED · lock phone now"
            } catch {
                status = "REQUEST FAILED · \(error.localizedDescription)"
                refresh()
            }
        }
    }

    func end() {
        Task { await endCurrent() }
    }

    private func endCurrent() async {
        guard #available(iOS 16.2, *) else { return }
        let activities = Activity<PomoStaticAttributes>.activities
        for item in activities {
            await item.end(
                ActivityContent(
                    state: PomoStaticAttributes.ContentState(message: "ENDED"),
                    staleDate: nil
                ),
                dismissalPolicy: .immediate
            )
        }
        activity = nil
        activityID = "—"
        activeCount = 0
        status = "Ready"
    }
}
