import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct PomoLandLiveActivity: Widget {
    private let ink = Color(red: 0.47, green: 0.34, blue: 0.53)
    private let paper = Color(red: 1.00, green: 0.97, blue: 0.88)
    private let paperDeep = Color(red: 0.97, green: 0.91, blue: 0.79)
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
                        PomoFlowerMark(size: 27)
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
                    VStack(spacing: 8) {
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
                    .padding(.top, 1)
                }
            } compactLeading: {
                PomoFlowerMark(size: 19)
                    .accessibilityLabel("PomoLand")
            } compactTrailing: {
                timerText(context.state)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .frame(width: 46, alignment: .trailing)
                    .accessibilityLabel(timerAccessibility(context.state))
            } minimal: {
                PomoFlowerMark(size: 19)
                    .accessibilityLabel("PomoLand timer")
            }
            .widgetURL(URL(string: "pomoland://timer"))
            .keylineTint(green)
        }
    }

    @ViewBuilder
    private func lockScreen(_ context: ActivityViewContext<PomoActivityAttributes>) -> some View {
        VStack(spacing: 9) {
            HStack(spacing: 11) {
                PomoFlowerMark(size: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("PomoLand")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(ink)

                    Text(context.state.kind == "break"
                         ? "Break"
                         : displayCategory(context.state.category))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(ink.opacity(0.72))
                }

                Spacer(minLength: 10)

                timerText(context.state)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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
private struct PomoFlowerMark: View {
    let size: CGFloat

    private let petal = Color(red: 1.00, green: 0.98, blue: 0.88)
    private let petalEdge = Color(red: 0.45, green: 0.31, blue: 0.23)
    private let center = Color(red: 0.98, green: 0.73, blue: 0.24)
    private let cheek = Color(red: 0.95, green: 0.49, blue: 0.38)
    private let leaf = Color(red: 0.42, green: 0.67, blue: 0.32)
    private let dark = Color(red: 0.20, green: 0.17, blue: 0.12)

    var body: some View {
        ZStack {
            Capsule()
                .fill(leaf)
                .frame(width: size * 0.12, height: size * 0.36)
                .offset(y: size * 0.24)

            ForEach(0..<6, id: \.self) { index in
                RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                    .fill(petal)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                            .stroke(petalEdge.opacity(0.65), lineWidth: max(0.8, size * 0.035))
                    )
                    .frame(width: size * 0.35, height: size * 0.47)
                    .offset(y: -size * 0.29)
                    .rotationEffect(.degrees(Double(index) * 60))
            }

            Circle()
                .fill(center)
                .overlay(Circle().stroke(petalEdge.opacity(0.75), lineWidth: max(0.8, size * 0.035)))
                .frame(width: size * 0.54, height: size * 0.54)

            HStack(spacing: size * 0.16) {
                Circle().fill(dark).frame(width: size * 0.065, height: size * 0.10)
                Circle().fill(dark).frame(width: size * 0.065, height: size * 0.10)
            }
            .offset(y: -size * 0.035)

            HStack(spacing: size * 0.31) {
                Circle().fill(cheek.opacity(0.8)).frame(width: size * 0.09, height: size * 0.06)
                Circle().fill(cheek.opacity(0.8)).frame(width: size * 0.09, height: size * 0.06)
            }
            .offset(y: size * 0.075)

            Capsule()
                .fill(dark)
                .frame(width: size * 0.13, height: max(1.1, size * 0.035))
                .offset(y: size * 0.12)
        }
        .frame(width: size, height: size)
    }
}
