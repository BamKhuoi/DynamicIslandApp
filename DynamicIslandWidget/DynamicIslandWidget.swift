import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents

struct IslandIconView: View {
    let state: MyIslandAttributes.ContentState
    let font: Font

    var body: some View {
        if state.useEmoji {
            Text(state.emojiText.isEmpty ? "✨" : state.emojiText)
                .font(font)
        } else {
            Image(systemName: state.iconName)
                .font(font)
                .foregroundColor(Color(hex: state.iconColorHex))
        }
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
                    IslandIconView(state: state, font: .title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.expandedTitle)
                            .font(.system(.headline, design: state.fontStyle.design))
                            .foregroundColor(textColor)
                            .lineLimit(1)
                        Text(state.expandedSubtitle)
                            .font(.system(.caption, design: state.fontStyle.design))
                            .foregroundColor(.gray)
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

                if state.showCounter || (state.showLauncher && !state.shortcuts.isEmpty) {
                    HStack(spacing: 8) {
                        if state.showCounter {
                            if #available(iOS 17.0, *) {
                                HStack(spacing: 8) {
                                    Button(intent: CounterIntent(delta: -1)) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.gray)
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
                                .background(Color.white.opacity(0.1))
                                .clipShape(Capsule())
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
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.9))

        } dynamicIsland: { context in
            let state = context.state
            let iconColor = Color(hex: state.iconColorHex)
            let textColor = Color(hex: state.textColorHex)
            let keylineColor: Color? = state.useKeyline ? Color(hex: state.keylineColorHex) : nil

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IslandIconView(state: state, font: .title2)
                        .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
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
                    VStack(spacing: 8) {
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

                        HStack(spacing: 8) {
                            if state.showCounter {
                                if #available(iOS 17.0, *) {
                                    HStack(spacing: 8) {
                                        Button(intent: CounterIntent(delta: -1)) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.callout)
                                                .foregroundColor(.gray)
                                        }
                                        .buttonStyle(.plain)

                                        Text("\(state.counter)")
                                            .font(.system(.subheadline, design: .monospaced).bold())
                                            .foregroundColor(textColor)
                                            .frame(minWidth: 18)

                                        Button(intent: CounterIntent(delta: 1)) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.callout)
                                                .foregroundColor(iconColor)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }

                            if state.showLauncher && !state.shortcuts.isEmpty {
                                HStack(spacing: 6) {
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
                                                .background(Color.white.opacity(0.08))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
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
                IslandIconView(state: state, font: .caption)
            } compactTrailing: {
                IslandMetricView(state: state, compact: true)
            } minimal: {
                IslandIconView(state: state, font: .caption)
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