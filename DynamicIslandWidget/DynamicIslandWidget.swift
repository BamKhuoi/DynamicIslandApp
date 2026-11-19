import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents
import UIKit

struct IslandIconView: View {
    let state: MyIslandAttributes.ContentState
    let size: CGFloat

    var body: some View {
        switch state.iconSource {
        case .photo:
            if let data = state.customImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(state.photoIsCircle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: size * 0.25)))
            } else {
                Image(systemName: "photo.fill")
                    .font(.system(size: size * 0.7))
                    .foregroundColor(Color(hex: state.iconColorHex))
            }
        case .emoji:
            Text(state.emojiText.isEmpty ? "✨" : state.emojiText)
                .font(.system(size: size * 0.85))
        case .symbol:
            Image(systemName: state.iconName)
                .font(.system(size: size * 0.78))
                .foregroundColor(Color(hex: state.iconColorHex))
        }
    }
}

struct BatteryGaugeView: View {
    let level: Int
    let isCharging: Bool
    let compact: Bool

    var ringColor: Color {
        if isCharging { return .green }
        if level <= 20 { return .red }
        if level <= 40 { return .yellow }
        return .green
    }

    var body: some View {
        Gauge(value: Double(level), in: 0...100) {
            EmptyView()
        } currentValueLabel: {
            if isCharging && compact {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.green)
            } else {
                Text("\(level)")
                    .font(.system(size: compact ? 8 : 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(ringColor)
        .scaleEffect(compact ? 0.52 : 0.72)
        .frame(width: compact ? 26 : 36, height: compact ? 26 : 36)
    }
}

struct IslandMetricView: View {
    let state: MyIslandAttributes.ContentState
    let compact: Bool

    var body: some View {
        let textColor = Color(hex: state.textColorHex)
        let design = state.fontStyle.design
        let baseFont: Font = compact
            ? .system(.caption2, design: design).bold()
            : .system(.subheadline, design: design).bold()

        switch state.mode {
        case .text:
            Text(state.compactText)
                .font(baseFont)
                .foregroundColor(textColor)
                .lineLimit(1)
        case .clock:
            Text(Calendar.current.startOfDay(for: Date()), style: .timer)
                .font(.system(compact ? .caption2 : .subheadline, design: design).monospacedDigit().bold())
                .foregroundColor(textColor)
                .frame(maxWidth: compact ? 58 : 74, alignment: .trailing)
        case .weather:
            Text(state.weatherInfo)
                .font(baseFont)
                .foregroundColor(textColor)
                .lineLimit(1)
        case .countdown:
            Text(timerInterval: state.safeCountdownRange, countsDown: true)
                .font(.system(compact ? .caption2 : .subheadline, design: design).monospacedDigit().bold())
                .foregroundColor(textColor)
                .frame(maxWidth: compact ? 54 : 70, alignment: .trailing)
        case .stopwatch:
            Text(state.stopwatchStart, style: .timer)
                .font(.system(compact ? .caption2 : .subheadline, design: design).monospacedDigit().bold())
                .foregroundColor(textColor)
                .frame(maxWidth: compact ? 54 : 70, alignment: .trailing)
        case .battery:
            HStack(spacing: 3) {
                if !compact && state.isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                BatteryGaugeView(level: state.batteryLevel, isCharging: state.isCharging, compact: compact)
            }
        }
    }
}

struct IslandBackgroundFill: View {
    let state: MyIslandAttributes.ContentState

    var body: some View {
        switch state.bgStyle {
        case .solid:
            Color(hex: state.bgColorHex)
        case .gradient:
            LinearGradient(
                colors: [Color(hex: state.bgColorHex), Color(hex: state.bgColor2Hex)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .glass:
            Color(hex: state.bgColorHex).opacity(0.28)
        }
    }
}

struct DynamicIslandWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MyIslandAttributes.self) { context in
            let state = context.state
            let iconColor = Color(hex: state.iconColorHex)
            let textColor = Color(hex: state.textColorHex)

            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    IslandIconView(state: state, size: 34)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.expandedTitle)
                            .font(.system(.headline, design: state.fontStyle.design))
                            .foregroundColor(textColor)
                            .lineLimit(1)
                        Text(state.expandedSubtitle)
                            .font(.system(.caption, design: state.fontStyle.design))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }

                    Spacer()
                    IslandMetricView(state: state, compact: false)
                }

                if state.mode == .countdown {
                    ProgressView(
                        timerInterval: state.safeCountdownRange,
                        countsDown: true,
                        label: { EmptyView() },
                        currentValueLabel: { EmptyView() }
                    )
                    .tint(iconColor)
                }

                if state.showTodos {
                    let activeTodos = state.todos.filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
                    if !activeTodos.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(activeTodos.prefix(3)) { todo in
                                if #available(iOS 17.0, *) {
                                    Button(intent: ToggleTodoIntent(todoId: todo.id)) {
                                        HStack(spacing: 8) {
                                            Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                                                .font(.caption)
                                                .foregroundColor(todo.isDone ? iconColor : .white.opacity(0.6))
                                            Text(todo.title)
                                                .font(.system(.caption, design: state.fontStyle.design))
                                                .strikethrough(todo.isDone)
                                                .foregroundColor(todo.isDone ? .white.opacity(0.45) : .white)
                                                .lineLimit(1)
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                HStack(spacing: 8) {
                    if state.showCounter {
                        if #available(iOS 17.0, *) {
                            HStack(spacing: 8) {
                                Button(intent: CounterIntent(delta: -1)) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.white.opacity(0.65))
                                }
                                .buttonStyle(.plain)

                                Text("\(state.counter)")
                                    .font(.system(.subheadline, design: .monospaced).bold())
                                    .foregroundColor(textColor)
                                    .frame(minWidth: 20)

                                Button(intent: CounterIntent(delta: 1)) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(iconColor)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }

                    if state.mode == .stopwatch {
                        if #available(iOS 17.0, *) {
                            Button(intent: ResetStopwatchIntent()) {
                                Label("Reset", systemImage: "arrow.counterclockwise")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(iconColor.opacity(0.28))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if state.mode == .battery {
                        if #available(iOS 17.0, *) {
                            Button(intent: RefreshBatteryIntent()) {
                                Label("Cập nhật Pin", systemImage: "arrow.clockwise")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.green.opacity(0.28))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()

                    if #available(iOS 17.0, *) {
                        Button(intent: CycleModeIntent()) {
                            Label(state.mode.rawValue, systemImage: "arrow.triangle.2.circlepath")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.14))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .background(IslandBackgroundFill(state: state))
            .activityBackgroundTint(
                state.bgStyle == .glass
                ? Color(hex: state.bgColorHex).opacity(0.35)
                : Color(hex: state.bgColorHex)
            )

        } dynamicIsland: { context in
            let state = context.state
            let iconColor = Color(hex: state.iconColorHex)
            let textColor = Color(hex: state.textColorHex)
            let keylineColor: Color? = state.useKeyline ? Color(hex: state.keylineColorHex) : nil

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IslandIconView(state: state, size: 32)
                        .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 6) {
                        if state.mode == .stopwatch {
                            if #available(iOS 17.0, *) {
                                Button(intent: ResetStopwatchIntent()) {
                                    Image(systemName: "arrow.counterclockwise.circle.fill")
                                        .font(.callout)
                                        .foregroundColor(iconColor)
                                }
                                .buttonStyle(.plain)
                            }
                        } else if state.mode == .battery {
                            if #available(iOS 17.0, *) {
                                Button(intent: RefreshBatteryIntent()) {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .font(.callout)
                                        .foregroundColor(.green)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        VStack(alignment: .trailing, spacing: 3) {
                            IslandMetricView(state: state, compact: false)

                            if #available(iOS 17.0, *) {
                                Button(intent: CycleModeIntent()) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(state.expandedTitle)
                            .font(.system(.headline, design: state.fontStyle.design))
                            .foregroundColor(textColor)
                            .lineLimit(1)
                        Text(state.expandedSubtitle)
                            .font(.system(.caption2, design: state.fontStyle.design))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        if state.mode == .countdown {
                            ProgressView(
                                timerInterval: state.safeCountdownRange,
                                countsDown: true,
                                label: { EmptyView() },
                                currentValueLabel: { EmptyView() }
                            )
                            .tint(iconColor)
                            .padding(.horizontal, 4)
                        }

                        if state.showTodos {
                            let activeTodos = state.todos.filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
                            if !activeTodos.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(activeTodos.prefix(3)) { todo in
                                        if #available(iOS 17.0, *) {
                                            Button(intent: ToggleTodoIntent(todoId: todo.id)) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                                                        .font(.caption2)
                                                        .foregroundColor(todo.isDone ? iconColor : .gray)
                                                    Text(todo.title)
                                                        .font(.system(.caption2, design: state.fontStyle.design))
                                                        .strikethrough(todo.isDone)
                                                        .foregroundColor(todo.isDone ? .gray : .white)
                                                        .lineLimit(1)
                                                    Spacer()
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(IslandBackgroundFill(state: state).opacity(0.65))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }

                        if state.showCounter || (state.showLauncher && !state.shortcuts.isEmpty) {
                            HStack(spacing: 6) {
                                if state.showCounter {
                                    if #available(iOS 17.0, *) {
                                        HStack(spacing: 6) {
                                            Button(intent: CounterIntent(delta: -1)) {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.callout)
                                                    .foregroundColor(.gray)
                                            }
                                            .buttonStyle(.plain)

                                            Text("\(state.counter)")
                                                .font(.system(.subheadline, design: .monospaced).bold())
                                                .foregroundColor(textColor)
                                                .frame(minWidth: 16)

                                            Button(intent: CounterIntent(delta: 1)) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.callout)
                                                    .foregroundColor(iconColor)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(IslandBackgroundFill(state: state).opacity(0.75))
                                        .clipShape(Capsule())
                                    }
                                }

                                if state.showLauncher && !state.shortcuts.isEmpty {
                                    HStack(spacing: 5) {
                                        ForEach(state.shortcuts.prefix(4)) { item in
                                            if let url = URL(string: item.urlString) {
                                                Link(destination: url) {
                                                    VStack(spacing: 2) {
                                                        Image(systemName: item.icon)
                                                            .font(.caption)
                                                            .foregroundColor(iconColor)
                                                        Text(item.name)
                                                            .font(.system(size: 9))
                                                            .foregroundColor(.white.opacity(0.85))
                                                            .lineLimit(1)
                                                    }
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 5)
                                                    .background(IslandBackgroundFill(state: state).opacity(0.75))
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            } compactLeading: {
                IslandIconView(state: state, size: 20)
            } compactTrailing: {
                IslandMetricView(state: state, compact: true)
            } minimal: {
                IslandIconView(state: state, size: 20)
            }
            .keylineTint(keylineColor)
        }
    }
}

@main
struct DynamicIslandWidgetBundle: WidgetBundle {
    var body: some Widget {
        DynamicIslandWidgetLiveActivity()
    }
}