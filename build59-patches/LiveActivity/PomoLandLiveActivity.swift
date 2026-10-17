import ActivityKit
import SwiftUI
import UIKit
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
                    HStack(spacing: 5) {
                        dynamicIslandCategoryImage(context.state, size: 28)
                        Text("PomoLand")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    timerText(context.state)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.kind == "break" ? "Break" : displayCategory(context.state.category))
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(categoryColor(context.state))
                        timerProgress(context.state)
                            .tint(categoryColor(context.state))
                    }
                }
            } compactLeading: {
                dynamicIslandCategoryImage(context.state, size: 20)
                    .accessibilityLabel(displayCategory(context.state.category))
            } compactTrailing: {
                timerText(context.state)
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(width: 34, alignment: .trailing)
                    .accessibilityLabel(timerAccessibility(context.state))
            } minimal: {
                dynamicIslandCategoryImage(context.state, size: 18)
                    .accessibilityLabel("PomoLand timer")
            }
            .widgetURL(URL(string: "pomoland://timer"))
            .keylineTint(categoryColor(context.state))
        }
    }

    @ViewBuilder
    private func lockScreen(_ context: ActivityViewContext<PomoActivityAttributes>) -> some View {
        HStack(alignment: .center, spacing: 9) {
            categoryImage(context.state)
                .frame(width: 82, height: 82)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("PomoLand")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(ink)
                        .lineLimit(1)

                    Text(context.state.kind == "break" ? "Break" : displayCategory(context.state.category))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(categoryColor(context.state))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(categoryColor(context.state).opacity(0.12), in: Capsule())
                        .lineLimit(1)
                }

                timerText(context.state)
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(categoryColor(context.state))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .layoutPriority(1)

                timerProgress(context.state)
                    .tint(categoryColor(context.state))
                    .scaleEffect(x: 1, y: 1.08, anchor: .center)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 92)
        .padding(.vertical, 3)
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func categoryImage(_ state: PomoActivityAttributes.ContentState) -> some View {
        if let image = rawWidgetImage(named: categoryImageName(state)) {
            Image(uiImage: image.withRenderingMode(.alwaysOriginal))
                .renderingMode(.original)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
        } else {
            Text(categoryFallbackGlyph(state))
                .font(.system(size: 42))
                .minimumScaleFactor(0.4)
        }
    }

    @ViewBuilder
    private func dynamicIslandCategoryImage(_ state: PomoActivityAttributes.ContentState, size: CGFloat) -> some View {
        if let image = rawWidgetImage(named: categoryImageName(state)) {
            if #available(iOS 18.0, *) {
                Image(uiImage: image.withRenderingMode(.alwaysOriginal))
                    .renderingMode(.original)
                    .resizable()
                    .widgetAccentedRenderingMode(.fullColor)
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .fixedSize()
            } else {
                Image(uiImage: image.withRenderingMode(.alwaysOriginal))
                    .renderingMode(.original)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .fixedSize()
            }
        } else {
            Text(categoryFallbackGlyph(state))
                .font(.system(size: size * 0.9))
                .frame(width: size, height: size)
        }
    }

    private func rawWidgetImage(named name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        return image
    }

    private func categoryFallbackGlyph(_ state: PomoActivityAttributes.ContentState) -> String {
        if state.kind == "break" { return "🌼" }
        switch state.category {
        case "news": return "🌼"
        case "reading": return "🌳"
        case "philosophy": return "🌲"
        case "vocabulary": return "🫐"
        case "studying": return "🍄"
        default: return "🌱"
        }
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
            ProgressView(value: total - remaining, total: total).labelsHidden()
        } else {
            ProgressView(timerInterval: state.startDate...state.endDate, countsDown: false).labelsHidden()
        }
    }

    private func categoryImageName(_ state: PomoActivityAttributes.ContentState) -> String {
        if state.kind == "break" { return "News52" }
        switch state.category {
        case "news": return "News52"
        case "reading": return "Reading52"
        case "philosophy": return "Philosophy52"
        case "vocabulary": return "Vocabulary52"
        case "studying": return "Studying52"
        default: return "News52"
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
        state.isPaused ? "Paused with \(state.remainingSeconds) seconds remaining" : "PomoLand timer running"
    }

    private func format(seconds: Int) -> String {
        let value = max(0, seconds)
        return String(format: "%02d:%02d", value / 60, value % 60)
    }
}
