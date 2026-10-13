import SwiftUI
import WidgetKit

private struct RegistrationEntry: TimelineEntry {
    let date: Date
}

private struct RegistrationProvider: TimelineProvider {
    func placeholder(in context: Context) -> RegistrationEntry {
        RegistrationEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (RegistrationEntry) -> Void) {
        completion(RegistrationEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RegistrationEntry>) -> Void) {
        completion(Timeline(entries: [RegistrationEntry(date: Date())], policy: .never))
    }
}

private struct PomoLandRegistrationWidget: Widget {
    let kind = "PomoLandRegistrationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RegistrationProvider()) { _ in
            ZStack {
                Color(red: 0.95, green: 0.90, blue: 0.98)
                VStack(spacing: 8) {
                    Text("POMOLAND")
                        .font(.headline)
                    Text("WIDGET EXTENSION")
                        .font(.caption.bold())
                    Text("REGISTERED")
                        .font(.caption2.monospaced().bold())
                }
                .foregroundStyle(.black)
            }
            .containerBackground(for: .widget) {
                Color(red: 0.95, green: 0.90, blue: 0.98)
            }
        }
        .configurationDisplayName("PomoLand Registration Test")
        .description("Checks whether iOS registered the bundled WidgetKit extension.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct PomoLandStaticWidgetBundle: WidgetBundle {
    var body: some Widget {
        PomoLandRegistrationWidget()
        PomoLandStaticLiveActivity()
    }
}
