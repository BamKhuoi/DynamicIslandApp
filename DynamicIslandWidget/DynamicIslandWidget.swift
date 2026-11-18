import WidgetKit
import SwiftUI
import ActivityKit

struct DynamicIslandWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MyIslandAttributes.self) { context in
            // Giao diện hiện trên màn hình khóa
            VStack {
                Text(context.state.customText)
            }
        } dynamicIsland: { context in
            // Giao diện hiện trên Đảo động
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.customText).font(.title3).foregroundColor(.cyan)
                }
            } compactLeading: {
                Image(systemName: "terminal.fill").foregroundColor(.green)
            } compactTrailing: {
                Text("Dev")
            } minimal: {
                Image(systemName: "terminal.fill").foregroundColor(.green)
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