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
                if state.photoIsCircle {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay {
                            if state.bgStyle == .glass {
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [.white.opacity(0.8), .white.opacity(0.15), .white.opacity(0.45)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.9
                                    )
                            }
                        }
                } else {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.25, style: .continuous))
                        .overlay {
                            if state.bgStyle == .glass {
                                RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [.white.opacity(0.8), .white.opacity(0.15), .white.opacity(0.45)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.9
                                    )
                            }
                        }
                }
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
        let c1 = Color(hex: state.bgColorHex)
        let c2 = Color(hex: state.bgColor2Hex)

        switch state.bgStyle {
        case .solid:
            c1
        case .gradient:
            LinearGradient(
                colors: [c1, c2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .glass:
            ZStack {
                LinearGradient(
                    colors: [c1.opacity(0.32), c2.opacity(0.22)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.24),
                        Color.white.opacity(0.05),
                        Color.clear,
                        Color.white.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

struct ExpandedGlassPanelSurface: View {
    let state: MyIslandAttributes.ContentState
    var cornerRadius: CGFloat = 20

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let c1 = Color(hex: state.bgColorHex)
        let c2 = Color(hex: state.bgColor2Hex)

        switch state.bgStyle {
        case .solid:
            ZStack {
                shape.fill(c1)
                shape.strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
            }
        case .gradient:
            ZStack {
                shape.fill(
                    LinearGradient(
                        colors: [c1, c2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                shape.strokeBorder(Color.white.opacity(0.22), lineWidth: 0.8)
            }
        case .glass:
            ZStack {
                shape.fill(
                    LinearGradient(
                        colors: [c1.opacity(0.54), c2.opacity(0.34)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                shape.fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.28), c1.opacity(0.22), .clear],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 200
                    )
                )

                shape.fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.30),
                            Color.white.opacity(0.06),
                            Color.clear,
                            c2.opacity(0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.78),
                            c1.opacity(0.55),
                            Color.white.opacity(0.10),
                            Color.white.opacity(0.48)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
            }
        }
    }
}

struct IslandCardSurface<S: InsettableShape>: View {
    let state: MyIslandAttributes.ContentState
    let shape: S
    var isOuterPill: Bool = false

    var body: some View {
        let c1 = Color(hex: state.bgColorHex)
        let c2 = Color(hex: state.bgColor2Hex)

        switch state.bgStyle {
        case .glass:
            ZStack {
                shape.fill(
                    LinearGradient(
                        colors: [
                            c1.opacity(isOuterPill ? 0.48 : 0.28),
                            c2.opacity(isOuterPill ? 0.30 : 0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                shape.fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isOuterPill ? 0.30 : 0.22),
                            Color.white.opacity(0.04),
                            Color.clear,
                            Color.white.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.72),
                            Color.white.opacity(0.14),
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.40)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.85
                )
            }
        case .solid:
            if isOuterPill {
                ZStack {
                    shape.fill(c1.opacity(0.92))
                    shape.strokeBorder(Color.white.opacity(0.22), lineWidth: 0.7)
                }
            } else {
                shape.fill(Color.black.opacity(0.22))
            }
        case .gradient:
            if isOuterPill {
                ZStack {
                    shape.fill(LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing))
                    shape.strokeBorder(Color.white.opacity(0.22), lineWidth: 0.7)
                }
            } else {
                shape.fill(Color.black.opacity(0.22))
            }
        }
    }
}

struct DynamicIslandWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MyIslandAttributes.self) { context in
            let state = context.state
            let iconColor = Color(hex: state.iconColorHex)
            let textColor = Color(hex: state.textColorHex)

            // Giao diện Màn hình khóa (Lock Screen)
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
                            .foregroundColor(.white.opacity(0.82))
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
                                                .foregroundColor(todo.isDone ? iconColor : .white.opacity(0.75))
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
                        .padding(9)
                        .background(
                            IslandCardSurface(
                                state: state,
                                shape: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                        )
                    }
                }

                HStack(spacing: 8) {
                    if state.showCounter {
                        if #available(iOS 17.0, *) {
                            HStack(spacing: 8) {
                                Button(intent: CounterIntent(delta: -1)) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.white.opacity(0.75))
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
                            .background(IslandCardSurface(state: state, shape: Capsule()))
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
                                    .background(IslandCardSurface(state: state, shape: Capsule()))
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
                                    .background(IslandCardSurface(state: state, shape: Capsule()))
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
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(IslandCardSurface(state: state, shape: Capsule()))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .background(IslandBackgroundFill(state: state))
            .overlay {
                if state.bgStyle == .glass {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.55),
                                    Color(hex: state.bgColorHex).opacity(0.35),
                                    Color.clear,
                                    Color.white.opacity(0.28)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                }
            }
            .activityBackgroundTint(
                state.bgStyle == .glass
                ? Color(hex: state.bgColorHex).opacity(0.16)
                : Color(hex: state.bgColorHex)
            )

        } dynamicIsland: { context in
            let state = context.state
            let iconColor = Color(hex: state.iconColorHex)
            let textColor = Color(hex: state.textColorHex)
            let keylineColor: Color? = state.useKeyline
                ? Color(hex: state.keylineColorHex)
                : Color(hex: state.bgColorHex).opacity(0.85)

            return DynamicIsland {
                // Cụm TRÁI camera: Khung vuông bo góc đồng tâm khi chọn ảnh vuông, tròn khi chọn Avatar/Icon
                DynamicIslandExpandedRegion(.leading) {
                    IslandIconView(state: state, size: 28)
                        .padding(3)
                        .background {
                            if state.iconSource == .photo && !state.photoIsCircle {
                                IslandCardSurface(
                                    state: state,
                                    shape: RoundedRectangle(cornerRadius: 10, style: .continuous),
                                    isOuterPill: true
                                )
                            } else {
                                IslandCardSurface(state: state, shape: Capsule(), isOuterPill: true)
                            }
                        }
                        .padding(.leading, 2)
                }

                // Cụm PHẢI camera: Gọn chiều cao để nhường tối đa không gian cho phần dưới
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 5) {
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

                        IslandMetricView(state: state, compact: false)

                        if #available(iOS 17.0, *) {
                            Button(intent: CycleModeIntent()) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(IslandCardSurface(state: state, shape: Capsule(), isOuterPill: true))
                    .padding(.trailing, 2)
                }

                // Thân Đảo mở rộng: Tự động co gọn bố cục khi bật Phím tắt App / Checklist để không bị cắt tên
                DynamicIslandExpandedRegion(.bottom) {
                    let hasTitle = !state.expandedTitle.trimmingCharacters(in: .whitespaces).isEmpty
                    let hasSubtitle = !state.expandedSubtitle.trimmingCharacters(in: .whitespaces).isEmpty
                    let activeTodos = state.showTodos
                        ? state.todos.filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
                        : []
                    let hasBottomRow = state.showCounter || (state.showLauncher && !state.shortcuts.isEmpty)
                    let isDense = hasBottomRow || !activeTodos.isEmpty || state.mode == .countdown
                    let isUltraDense = hasBottomRow && !activeTodos.isEmpty

                    VStack(spacing: isDense ? 5 : 7) {
                        if hasTitle || hasSubtitle {
                            if isUltraDense && hasTitle && hasSubtitle {
                                // Gộp 1 dòng gọn gàng nếu bật cả Checklist lẫn Phím tắt cùng lúc
                                HStack(spacing: 5) {
                                    Text(state.expandedTitle)
                                        .font(.system(.caption, design: state.fontStyle.design).bold())
                                        .foregroundColor(textColor)
                                        .lineLimit(1)
                                    Text("•")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.5))
                                    Text(state.expandedSubtitle)
                                        .font(.system(.caption2, design: state.fontStyle.design))
                                        .foregroundColor(.white.opacity(0.82))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                VStack(spacing: isDense ? 0 : 2) {
                                    if hasTitle {
                                        Text(state.expandedTitle)
                                            .font(.system(isDense ? .subheadline : .headline, design: state.fontStyle.design).bold())
                                            .foregroundColor(textColor)
                                            .lineLimit(1)
                                    }
                                    if hasSubtitle {
                                        Text(state.expandedSubtitle)
                                            .font(.system(isDense ? .caption2 : .caption, design: state.fontStyle.design))
                                            .foregroundColor(.white.opacity(0.82))
                                            .lineLimit(1)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }

                        if state.mode == .countdown {
                            ProgressView(
                                timerInterval: state.safeCountdownRange,
                                countsDown: true,
                                label: { EmptyView() },
                                currentValueLabel: { EmptyView() }
                            )
                            .tint(iconColor)
                            .padding(.horizontal, 2)
                        }

                        if !activeTodos.isEmpty {
                            VStack(alignment: .leading, spacing: 3) {
                                ForEach(activeTodos.prefix(isUltraDense ? 2 : 3)) { todo in
                                    if #available(iOS 17.0, *) {
                                        Button(intent: ToggleTodoIntent(todoId: todo.id)) {
                                            HStack(spacing: 6) {
                                                Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                                                    .font(.caption2)
                                                    .foregroundColor(todo.isDone ? iconColor : .white.opacity(0.75))
                                                Text(todo.title)
                                                    .font(.system(.caption2, design: state.fontStyle.design))
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
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                IslandCardSurface(
                                    state: state,
                                    shape: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                            )
                        }

                        if hasBottomRow {
                            HStack(spacing: 5) {
                                if state.showCounter {
                                    if #available(iOS 17.0, *) {
                                        HStack(spacing: 5) {
                                            Button(intent: CounterIntent(delta: -1)) {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.75))
                                            }
                                            .buttonStyle(.plain)

                                            Text("\(state.counter)")
                                                .font(.system(.caption, design: .monospaced).bold())
                                                .foregroundColor(textColor)
                                                .frame(minWidth: 14)

                                            Button(intent: CounterIntent(delta: 1)) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.caption)
                                                    .foregroundColor(iconColor)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(IslandCardSurface(state: state, shape: Capsule()))
                                    }
                                }

                                if state.showLauncher && !state.shortcuts.isEmpty {
                                    HStack(spacing: 5) {
                                        ForEach(state.shortcuts.prefix(4)) { item in
                                            if let url = URL(string: item.urlString) {
                                                Link(destination: url) {
                                                    VStack(spacing: 2) {
                                                        Image(systemName: item.icon)
                                                            .font(.system(size: 11, weight: .semibold))
                                                            .foregroundColor(iconColor)
                                                        Text(item.name)
                                                            .font(.system(size: 9, weight: .medium))
                                                            .foregroundColor(.white.opacity(0.95))
                                                            .lineLimit(1)
                                                            .minimumScaleFactor(0.75)
                                                    }
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.horizontal, 2)
                                                    .padding(.vertical, 4)
                                                    .background(
                                                        IslandCardSurface(
                                                            state: state,
                                                            shape: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        )
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, isDense ? 6 : 10)
                    .frame(maxWidth: .infinity)
                    .background(ExpandedGlassPanelSurface(state: state, cornerRadius: 18))
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