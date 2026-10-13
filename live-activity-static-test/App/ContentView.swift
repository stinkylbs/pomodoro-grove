import ActivityKit
import SwiftUI

struct ContentView: View {
    @StateObject private var live = StaticLiveActivityController()

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Spacer()

                Text("STATIC LIVE ACTIVITY TEST")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text("This build deliberately contains no countdown, progress view, images, or custom rendering logic in the Live Activity.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 8) {
                    Text(live.status)
                        .font(.headline)
                    Text("Live Activities enabled: \(activitiesEnabledText)")
                    Text("ActivityKit active count: \(live.activeCount)")
                    Text("Requested activity ID: \(live.activityID)")
                        .textSelection(.enabled)
                }
                .font(.system(.footnote, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))

                Button("Start STATIC Live Activity") {
                    live.start()
                }
                .buttonStyle(.borderedProminent)

                HStack {
                    Button("Refresh status") { live.refresh() }
                    Button("End") { live.end() }
                }
                .buttonStyle(.bordered)

                Text("After Start succeeds, lock the iPhone. The Lock Screen should literally say POMOLAND / LIVE ACTIVITY TEST / STATIC RENDER. Dynamic Island should show PL and TEST. If neither appears, the problem is below the timer UI layer.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
            .navigationTitle("Renderer Diagnostic")
            .onAppear { live.refresh() }
        }
    }

    private var activitiesEnabledText: String {
        if #available(iOS 16.2, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled ? "YES" : "NO"
        }
        return "UNAVAILABLE"
    }
}
