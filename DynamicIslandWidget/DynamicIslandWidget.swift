import WidgetKit
import SwiftUI
import ActivityKit

struct DynamicIslandWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MyIslandAttributes.self) { context in
            // Giao diện trên Màn hình khóa (Lock Screen)
            HStack(spacing: 14) {
                Image(systemName: context.state.iconName)
                    .font(.title2)
                    .foregroundColor(Color(hex: context.state.iconColorHex))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.expandedTitle)
                        .font(.headline)
                        .foregroundColor(Color(hex: context.state.textColorHex))
                    Text(context.state.expandedSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if context.state.mode == .clock {
                    Text(Calendar.current.startOfDay(for: Date()), style: .timer)
                        .font(.system(.title3, design: .monospaced))
                        .bold()
                        .foregroundColor(Color(hex: context.state.textColorHex))
                } else if context.state.mode == .weather {
                    Text(context.state.weatherInfo)
                        .font(.headline)
                        .foregroundColor(Color(hex: context.state.textColorHex))
                } else {
                    Text(context.state.compactText)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(Color(hex: context.state.textColorHex))
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.85))
            
        } dynamicIsland: { context in
            let iconColor = Color(hex: context.state.iconColorHex)
            let textColor = Color(hex: context.state.textColorHex)
            
            return DynamicIsland {
                // Giao diện khi NHẤN GIỮ mở rộng Đảo động
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.iconName)
                        .font(.title2)
                        .foregroundColor(iconColor)
                        .padding(.leading, 4)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.mode == .clock {
                        Text(Calendar.current.startOfDay(for: Date()), style: .timer)
                            .font(.system(.subheadline, design: .monospaced))
                            .bold()
                            .foregroundColor(textColor)
                            .frame(maxWidth: 72, alignment: .trailing)
                    } else if context.state.mode == .weather {
                        Text(context.state.weatherInfo)
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(textColor)
                    } else {
                        Text(context.state.compactText)
                            .font(.caption)
                            .bold()
                            .foregroundColor(textColor)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.expandedTitle)
                        .font(.headline)
                        .foregroundColor(textColor)
                        .lineLimit(1)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.expandedSubtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            } compactLeading: {
                // Góc TRÁI khi thu gọn
                Image(systemName: context.state.iconName)
                    .foregroundColor(iconColor)
            } compactTrailing: {
                // Góc PHẢI khi thu gọn
                switch context.state.mode {
                case .text:
                    Text(context.state.compactText)
                        .font(.caption2)
                        .bold()
                        .foregroundColor(textColor)
                        .lineLimit(1)
                case .clock:
                    Text(Calendar.current.startOfDay(for: Date()), style: .timer)
                        .font(.system(.caption2, design: .monospaced))
                        .bold()
                        .foregroundColor(textColor)
                        .frame(maxWidth: 56)
                case .weather:
                    Text(context.state.weatherInfo)
                        .font(.caption2)
                        .bold()
                        .foregroundColor(textColor)
                        .lineLimit(1)
                }
            } minimal: {
                // Khi có 2 app cùng dùng Đảo động
                Image(systemName: context.state.iconName)
                    .foregroundColor(iconColor)
            }
        }
    }
}

@main
struct DynamicIslandWidgetBundle: WidgetBundle {
    var body: some Widget {
        DynamicIslandWidgetLiveActivity()
    }
}