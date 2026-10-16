import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct PomoLandLiveActivity: Widget {
    private let ink = Color(red: 0.47, green: 0.34, blue: 0.53)
    private let paper = Color(red: 1.00, green: 0.97, blue: 0.88)
    private let green = Color(red: 0.35, green: 0.63, blue: 0.40)
    private let gold = Color(red: 0.90, green: 0.67, blue: 0.27)
    private let softPurple = Color(red: 0.47, green: 0.34, blue: 0.53).opacity(0.09)

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
                        PomoSpriteFlower(width: 23, height: 30)
                        Text("PomoLand")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    timerText(context.state)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
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
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(1)
                        }

                        timerProgress(context.state)
                            .tint(context.state.kind == "break" ? green : gold)
                            .labelsHidden()
                    }
                }
            } compactLeading: {
                PomoSpriteFlower(width: 15, height: 20)
                    .accessibilityLabel("PomoLand")
            } compactTrailing: {
                timerText(context.state)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .frame(width: 46, alignment: .trailing)
                    .accessibilityLabel(timerAccessibility(context.state))
            } minimal: {
                PomoSpriteFlower(width: 15, height: 20)
                    .accessibilityLabel("PomoLand timer")
            }
            .widgetURL(URL(string: "pomoland://timer"))
            .keylineTint(green)
        }
    }

    @ViewBuilder
    private func lockScreen(_ context: ActivityViewContext<PomoActivityAttributes>) -> some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 11) {
                PomoSpriteFlower(width: 36, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text("PomoLand")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(ink)

                    Text(context.state.kind == "break"
                         ? "Break"
                         : displayCategory(context.state.category))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(ink.opacity(0.78))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(softPurple, in: Capsule())
                }

                Spacer(minLength: 10)

                timerText(context.state)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
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
                    .foregroundStyle(ink.opacity(0.72))
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
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
        case "diagnostic": return "Focus"
        default: return "Focus"
        }
    }

    private func statusCopy(_ state: PomoActivityAttributes.ContentState) -> String {
        state.kind == "break" ? "Break time" : "Focus in progress"
    }

    private func compactStatusCopy(_ state: PomoActivityAttributes.ContentState) -> String {
        state.kind == "break" ? "A little time to rest" : "Focus session in progress"
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
private struct PomoSpriteFlower: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Image("Flower")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }
}
