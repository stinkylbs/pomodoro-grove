import SwiftUI
import WidgetKit

@main
struct PomoLandWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.2, *) {
            PomoLandLiveActivity()
        }
        PomoLandHomeWidget()
    }
}

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

private struct PomoLandHomeWidget: Widget {
    let kind = "PomoLandHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PomoLandHomeProvider()) { _ in
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
            .containerBackground(for: .widget) {
                Color(red: 0.98, green: 0.95, blue: 0.88)
            }
        }
        .configurationDisplayName("PomoLand")
        .description("A small doorway back to your grove.")
        .supportedFamilies([.systemSmall])
    }
}
