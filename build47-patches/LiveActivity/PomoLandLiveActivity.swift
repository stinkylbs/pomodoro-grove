import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct PomoLandLiveActivity: Widget {
    private let ink = Color(red: 0.48, green: 0.36, blue: 0.54)
    private let paper = Color(red: 1.00, green: 0.97, blue: 0.88)
    private let statusGreen = Color(red: 0.33, green: 0.64, blue: 0.49)

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
                        HStack {
                            Text(context.state.kind == "break" ? "Break" : displayCategory(context.state.category))
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(categoryColor(context.state))
                            Spacer()
                            Text(context.state.isPaused ? "Paused" : statusCopy(context.state))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        timerProgress(context.state)
                            .tint(categoryColor(context.state))
                    }
                    .foregroundStyle(.white)
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

            VStack(alignment: .leading, spacing: 5) {
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

                HStack(spacing: 7) {
                    Circle()
                        .fill(statusGreen)
                        .frame(width: 8, height: 8)
                    Text(context.state.isPaused ? "Paused" : statusCopy(context.state))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(ink.opacity(0.72))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 13)
    }

    @ViewBuilder
    private func categoryImage(_ state: PomoActivityAttributes.ContentState) -> some View {
        if state.kind != "break" && state.category == "studying" {
            PomoMushroomIcon()
        } else {
            Image(categoryImageName(state))
                .resizable()
                .scaledToFit()
        }
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
        } else {
            ProgressView(timerInterval: state.startDate...state.endDate, countsDown: false)
        }
    }

    private func categoryImageName(_ state: PomoActivityAttributes.ContentState) -> String {
        if state.kind == "break" { return "News" }
        switch state.category {
        case "news": return "News"
        case "reading": return "Reading"
        case "philosophy": return "Philosophy"
        case "vocabulary": return "Vocabulary"
        case "studying": return "Studying"
        default: return "News"
        }
    }

    private func categoryColor(_ state: PomoActivityAttributes.ContentState) -> Color {
        if state.kind == "break" { return statusGreen }
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

    private func statusCopy(_ state: PomoActivityAttributes.ContentState) -> String {
        state.kind == "break" ? "Break in progress" : "Focus session in progress"
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

@available(iOS 16.2, *)
private struct PomoMushroomIcon: View {
    private let outline = Color(red: 0.32, green: 0.14, blue: 0.10)
    private let cap = Color(red: 0.64, green: 0.55, blue: 0.90)
    private let cream = Color(red: 1.00, green: 0.91, blue: 0.72)

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                RoundedRectangle(cornerRadius: min(w, h) * 0.12)
                    .fill(.clear)

                Capsule()
                    .fill(cream)
                    .overlay(Capsule().stroke(outline, lineWidth: max(1.5, w * 0.025)))
                    .frame(width: w * 0.42, height: h * 0.43)
                    .offset(y: h * 0.20)

                ZStack {
                    Ellipse()
                        .fill(cap)
                        .overlay(Ellipse().stroke(outline, lineWidth: max(1.8, w * 0.028)))
                    Circle().fill(cream.opacity(0.95)).frame(width: w * 0.13).offset(x: -w * 0.20, y: -h * 0.03)
                    Circle().fill(cream.opacity(0.95)).frame(width: w * 0.10).offset(x: w * 0.18, y: -h * 0.10)
                    Circle().fill(cream.opacity(0.95)).frame(width: w * 0.085).offset(x: w * 0.03, y: h * 0.06)
                }
                .frame(width: w * 0.82, height: h * 0.50)
                .offset(y: -h * 0.12)

                HStack(spacing: w * 0.08) {
                    Capsule().fill(outline).frame(width: w * 0.035, height: h * 0.055)
                    Capsule().fill(outline).frame(width: w * 0.035, height: h * 0.055)
                }
                .offset(y: h * 0.20)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
