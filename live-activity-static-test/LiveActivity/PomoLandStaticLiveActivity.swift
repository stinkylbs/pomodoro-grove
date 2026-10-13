import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct PomoLandStaticLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomoStaticAttributes.self) { _ in
            VStack(spacing: 6) {
                Text("POMOLAND")
                    .font(.headline.bold())
                Text("LIVE ACTIVITY TEST")
                    .font(.title2.bold())
                Text("STATIC RENDER")
                    .font(.caption.monospaced())
            }
            .frame(maxWidth: .infinity)
            .padding()
        } dynamicIsland: { _ in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("PL")
                        .font(.headline.bold())
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("LIVE ACTIVITY TEST")
                        .font(.caption.bold())
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("TEST")
                        .font(.caption.monospaced())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("STATIC RENDER")
                        .font(.caption2.monospaced())
                }
            } compactLeading: {
                Text("PL")
                    .font(.caption2.bold())
            } compactTrailing: {
                Text("TEST")
                    .font(.caption2.bold())
            } minimal: {
                Text("P")
                    .font(.caption2.bold())
            }
        }
    }
}
