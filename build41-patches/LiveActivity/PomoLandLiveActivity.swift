import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct PomoLandLiveActivity: Widget {
    private let ink = Color(red: 0.47, green: 0.34, blue: 0.53)
    private let paper = Color(red: 1.00, green: 0.97, blue: 0.88)
    private let green = Color(red: 0.35, green: 0.63, blue: 0.40)
    private let gold = Color(red: 0.90, green: 0.67, blue: 0.27)

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
                        legacyFlower(size: 28)
                        Text("PomoLand")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
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
                    VStack(spacing: 7) {
                        HStack(spacing: 8) {
                            categoryPill(context.state)
                            Spacer(minLength: 8)
                            Text(context.state.isPaused ? "Paused" : statusCopy(context.state))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.74))
                                .lineLimit(1)
                        }
                        timerProgress(context.state)
                            .tint(context.state.kind == "break" ? green : gold)
                            .labelsHidden()
                    }
                }
            } compactLeading: {
                legacyFlower(size: 20)
                    .accessibilityLabel("PomoLand")
            } compactTrailing: {
                timerText(context.state)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .frame(width: 46, alignment: .trailing)
                    .accessibilityLabel(timerAccessibility(context.state))
            } minimal: {
                legacyFlower(size: 20)
                    .accessibilityLabel("PomoLand timer")
            }
            .widgetURL(URL(string: "pomoland://timer"))
            .keylineTint(green)
        }
    }

    @ViewBuilder
    private func lockScreen(_ context: ActivityViewContext<PomoActivityAttributes>) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                legacyFlower(size: 39)

                VStack(alignment: .leading, spacing: 1) {
                    Text("PomoLand")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(ink)

                    Text(context.state.kind == "break" ? "Break" : displayCategory(context.state.category))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(ink.opacity(0.70))
                }

                Spacer(minLength: 8)

                timerText(context.state)
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            timerProgress(context.state)
                .tint(context.state.kind == "break" ? green : gold)
                .labelsHidden()

            HStack(spacing: 7) {
                Circle()
                    .fill(context.state.isPaused ? gold : green)
                    .frame(width: 6, height: 6)

                Text(context.state.isPaused ? "Paused" : compactStatusCopy(context.state))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(ink.opacity(0.70))
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 13)
    }

    @ViewBuilder
    private func legacyFlower(size: CGFloat) -> some View {
        Image("Flower")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: size, height: size)
    }

    @ViewBuilder
    private func categoryPill(_ state: PomoActivityAttributes.ContentState) -> some View {
        Text(state.kind == "break" ? "Break" : displayCategory(state.category))
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(.white.opacity(0.14), in: Capsule())
    }

    @ViewBuilder
    private func timerText(_ state: PomoActivityAttributes.ContentState) -> some View {
        if state.isPaused {
            Text(format(seconds: state.remainingSeconds))
        } else {
            Text(timerInterval: state.startDate...state.endDate, countsDown: true, showsHours: false)
        }
    }

    @ViewBuilder
    private func timerProgress(_ state: PomoActivityAttributes.ContentState) -> some View {
        if state.isPaused {
            let remaining = Double(max(0, state.remainingSeconds))
            let total = Double(max(1, state.durationSeconds))
            ProgressView(value: total - remaining, total: total)
                .progressViewStyle(.linear)
        } else {
            ProgressView(timerInterval: state.startDate...state.endDate, countsDown: false)
                .progressViewStyle(.linear)
        }
    }

    private func displayCategory(_ raw: String) -> String {
        switch raw {
        case "news": return "News"
        case "reading": return "Casual Reading"
        case "philosophy": return "Philosophy"
        case "vocabulary": return "Vocabulary"
        case "studying": return "Studying"
        default: return "Focus"
        }
    }

    private func statusCopy(_ state: PomoActivityAttributes.ContentState) -> String {
        state.kind == "break" ? "Break time" : "Focus in progress"
    }

    private func compactStatusCopy(_ state: PomoActivityAttributes.ContentState) -> String {
        state.kind == "break" ? "Take a small break" : "Focus session in progress"
    }

    private func timerAccessibility(_ state: PomoActivityAttributes.ContentState) -> String {
        state.isPaused ? "Paused with \(state.remainingSeconds) seconds remaining" : "PomoLand timer running"
    }

    private func format(seconds: Int) -> String {
        let value = max(0, seconds)
        return String(format: "%02d:%02d", value / 60, value % 60)
    }
}
