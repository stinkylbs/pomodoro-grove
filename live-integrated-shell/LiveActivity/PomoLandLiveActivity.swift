import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct PomoLandLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomoLiveAttributes.self) { context in
            HStack(spacing: 12) {
                Image(systemName: symbol(for: context.state))
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(accent(for: context.state))
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 3) {
                    Text(context.state.kind == "break" ? "POMOLAND BREAK" : "POMOLAND · \(label(for: context.state.category).uppercased())")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(title(for: context.state))
                        .font(.headline)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                timer(for: context.state)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .activityBackgroundTint(Color(red: 0.98, green: 0.95, blue: 0.88))
            .activitySystemActionForegroundColor(Color(red: 0.27, green: 0.22, blue: 0.19))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: symbol(for: context.state))
                        Text(label(for: context.state.category))
                            .font(.caption.bold())
                    }
                    .foregroundStyle(accent(for: context.state))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    timer(for: context.state)
                        .font(.headline.bold())
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(title(for: context.state))
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        if context.state.isPaused {
                            Label("Paused", systemImage: "pause.fill")
                                .font(.caption.bold())
                        } else {
                            Text("A little focus. A lot of life.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: symbol(for: context.state))
                    .foregroundStyle(accent(for: context.state))
            } compactTrailing: {
                timer(for: context.state)
                    .font(.caption.bold())
                    .monospacedDigit()
            } minimal: {
                Image(systemName: symbol(for: context.state))
                    .foregroundStyle(accent(for: context.state))
            }
            .keylineTint(accent(for: context.state))
        }
    }

    @ViewBuilder
    private func timer(for state: PomoLiveAttributes.ContentState) -> some View {
        if state.isPaused {
            Text(format(seconds: state.remainingSeconds))
        } else {
            Text(state.endDate, style: .timer)
        }
    }

    private func label(for category: String) -> String {
        switch category {
        case "news": return "News"
        case "reading": return "Reading"
        case "philosophy": return "Philosophy"
        case "vocabulary": return "Vocabulary"
        default: return "Focus"
        }
    }

    private func title(for state: PomoLiveAttributes.ContentState) -> String {
        if state.kind == "break" { return state.isPaused ? "Break paused" : "A quiet five-minute break" }
        if !state.species.isEmpty { return state.species }
        return state.isPaused ? "Session paused" : "Focus session"
    }

    private func symbol(for state: PomoLiveAttributes.ContentState) -> String {
        if state.kind == "break" { return "cup.and.saucer.fill" }
        switch state.category {
        case "news": return "sparkles"
        case "reading": return "book.fill"
        case "philosophy": return "leaf.fill"
        case "vocabulary": return "text.book.closed.fill"
        default: return "leaf.fill"
        }
    }

    private func accent(for state: PomoLiveAttributes.ContentState) -> Color {
        if state.kind == "break" { return Color(red: 0.45, green: 0.54, blue: 0.72) }
        switch state.category {
        case "news": return Color(red: 0.55, green: 0.51, blue: 0.82)
        case "reading": return Color(red: 0.82, green: 0.54, blue: 0.25)
        case "philosophy": return Color(red: 0.31, green: 0.61, blue: 0.50)
        case "vocabulary": return Color(red: 0.78, green: 0.40, blue: 0.60)
        default: return Color(red: 0.45, green: 0.56, blue: 0.43)
        }
    }

    private func format(seconds: Int) -> String {
        let safe = max(0, seconds)
        return String(format: "%02d:%02d", safe / 60, safe % 60)
    }
}
