import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct PomoLandLiveActivity: Widget {
    private let ink = Color(red: 0.48, green: 0.36, blue: 0.54)
    private let paper = Color(red: 1.00, green: 0.97, blue: 0.88)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomoActivityAttributes.self) { context in
            lockScreen(context)
                .activityBackgroundTint(paper)
                .activitySystemActionForegroundColor(ink)
                .widgetURL(URL(string: "pomoland://timer"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 7) {
                        categoryImage(context.state)
                            .frame(width: 31, height: 31)
                        Text("PomoLand")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    timerText(context.state)
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.kind == "break" ? "Break" : displayCategory(context.state.category))
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(categoryColor(context.state))
                        timerProgress(context.state)
                            .tint(categoryColor(context.state))
                    }
                }
            } compactLeading: {
                categoryImage(context.state)
                    .frame(width: 21, height: 21)
                    .accessibilityLabel(displayCategory(context.state.category))
            } compactTrailing: {
                timerText(context.state)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .frame(width: 46, alignment: .trailing)
                    .accessibilityLabel(timerAccessibility(context.state))
            } minimal: {
                categoryImage(context.state)
                    .frame(width: 21, height: 21)
                    .accessibilityLabel("PomoLand timer")
            }
            .widgetURL(URL(string: "pomoland://timer"))
            .keylineTint(categoryColor(context.state))
        }
    }

    @ViewBuilder
    private func lockScreen(_ context: ActivityViewContext<PomoActivityAttributes>) -> some View {
        HStack(alignment: .center, spacing: 12) {
            categoryImage(context.state)
                .frame(width: 120, height: 120)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Text("PomoLand")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(ink)
                        .lineLimit(1)

                    Text(context.state.kind == "break" ? "Break" : displayCategory(context.state.category))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(categoryColor(context.state))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(categoryColor(context.state).opacity(0.12), in: Capsule())
                        .lineLimit(1)
                }

                timerText(context.state)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(categoryColor(context.state))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .layoutPriority(1)

                timerProgress(context.state)
                    .tint(categoryColor(context.state))
                    .scaleEffect(x: 1, y: 1.35, anchor: .center)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 13)
    }

    @ViewBuilder
    private func categoryImage(_ state: PomoActivityAttributes.ContentState) -> some View {
        Image(categoryImageName(state))
            .resizable()
            .scaledToFit()
    }

    @ViewBuilder
    private func timerText(_ state: PomoActivityAttributes.ContentState) -> some View {
        if state.isPaused {
            Text(format(seconds: state.remainingSeconds))
        } else {
            Text(
                timerInterval: state.startDate...state.endDate,
                countsDown: true,
                showsHours: false
            )
        }
    }

    @ViewBuilder
    private func timerProgress(_ state: PomoActivityAttributes.ContentState) -> some View {
        if state.isPaused {
            let remaining = Double(max(0, state.remainingSeconds))
            let total = Double(max(1, state.durationSeconds))
            ProgressView(value: total - remaining, total: total)
                .labelsHidden()
        } else {
            ProgressView(timerInterval: state.startDate...state.endDate, countsDown: false)
                .labelsHidden()
        }
    }

    private func categoryImageName(_ state: PomoActivityAttributes.ContentState) -> String {
        if state.kind == "break" { return "News51" }
        switch state.category {
        case "news": return "News51"
        case "reading": return "Reading51"
        case "philosophy": return "Philosophy51"
        case "vocabulary": return "Vocabulary51"
        case "studying": return "Studying51"
        default: return "News51"
        }
    }

    private func categoryColor(_ state: PomoActivityAttributes.ContentState) -> Color {
        if state.kind == "break" { return Color(red: 0.33, green: 0.64, blue: 0.49) }
        switch state.category {
        case "news": return Color(red: 0.914, green: 0.471, blue: 0.490)
        case "reading": return Color(red: 0.910, green: 0.659, blue: 0.310)
        case "philosophy": return Color(red: 0.412, green: 0.733, blue: 0.635)
        case "vocabulary": return Color(red: 0.557, green: 0.635, blue: 0.918)
        case "studying": return Color(red: 0.714, green: 0.604, blue: 0.910)
        default: return ink
        }
    }

    private func displayCategory(_ raw: String) -> String {
        switch raw {
        case "news": return "News"
        case "reading": return "Reading"
        case "philosophy": return "Philosophy"
        case "vocabulary": return "Vocabulary"
        case "studying": return "Studying"
        default: return "Focus"
        }
    }

    private func timerAccessibility(_ state: PomoActivityAttributes.ContentState) -> String {
        state.isPaused
            ? "Paused with \(state.remainingSeconds) seconds remaining"
            : "PomoLand timer running"
    }

    private func format(seconds: Int) -> String {
        let value = max(0, seconds)
        return String(format: "%02d:%02d", value / 60, value % 60)
    }
}
