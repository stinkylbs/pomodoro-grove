import SwiftUI
import WidgetKit

private struct PomoLandRegistrationEntry: TimelineEntry {
    let date: Date
}

private struct PomoLandRegistrationProvider: TimelineProvider {
    func placeholder(in context: Context) -> PomoLandRegistrationEntry {
        PomoLandRegistrationEntry(date: Date())
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (PomoLandRegistrationEntry) -> Void
    ) {
        completion(PomoLandRegistrationEntry(date: Date()))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<PomoLandRegistrationEntry>) -> Void
    ) {
        completion(
            Timeline(
                entries: [PomoLandRegistrationEntry(date: Date())],
                policy: .never
            )
        )
    }
}

private struct PomoLandRegistrationWidgetView: View {
    var body: some View {
        Group {
            if #available(iOSApplicationExtension 17.0, *) {
                content
                    .containerBackground(
                        Color(red: 1.00, green: 0.97, blue: 0.88),
                        for: .widget
                    )
            } else {
                content
                    .background(Color(red: 1.00, green: 0.97, blue: 0.88))
            }
        }
    }

    private var content: some View {
        VStack(spacing: 8) {
            Image("Flower")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 52)

            Text("PomoLand")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(Color(red: 0.48, green: 0.36, blue: 0.54))

            Text("Timer companion")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(Color(red: 0.48, green: 0.36, blue: 0.54).opacity(0.72))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
    }
}

/// A tiny ordinary WidgetKit widget intentionally shipped beside the Live Activity.
/// The sideloaded registration test that rendered correctly used this architecture,
/// while the integrated Build 37 extension contained only ActivityConfiguration.
struct PomoLandRegistrationWidget: Widget {
    private let kind = "PomoLandRegistrationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: PomoLandRegistrationProvider()
        ) { _ in
            PomoLandRegistrationWidgetView()
        }
        .configurationDisplayName("PomoLand")
        .description("Companion widget for the PomoLand focus timer.")
        .supportedFamilies([.systemSmall])
    }
}
