import SwiftUI
import WidgetKit

private struct PomoLandHomeEntry: TimelineEntry {
    let date: Date
}

private struct PomoLandHomeProvider: TimelineProvider {
    func placeholder(in context: Context) -> PomoLandHomeEntry { PomoLandHomeEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (PomoLandHomeEntry) -> Void) { completion(PomoLandHomeEntry(date: Date())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PomoLandHomeEntry>) -> Void) {
        completion(Timeline(entries: [PomoLandHomeEntry(date: Date())], policy: .never))
    }
}

private struct PomoLandHomeWidgetView: View {
    private var content: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: "leaf.fill")
                .font(.title2)
            Text("PomoLand")
                .font(.headline.bold())
            Text("A little focus.\nA lot of life.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 17.0, *) {
            content
                .containerBackground(for: .widget) {
                    Color(red: 0.98, green: 0.95, blue: 0.88)
                }
        } else {
            content
                .background(Color(red: 0.98, green: 0.95, blue: 0.88))
        }
    }
}

private struct PomoLandHomeWidget: Widget {
    let kind = "PomoLandHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PomoLandHomeProvider()) { _ in
            PomoLandHomeWidgetView()
        }
        .configurationDisplayName("PomoLand")
        .description("A small doorway back to your grove.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct PomoLandWidgetBundle: WidgetBundle {
    var body: some Widget {
        PomoLandHomeWidget()
        if #available(iOS 16.2, *) {
            PomoLandLiveActivity()
        }
    }
}
