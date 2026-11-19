import AppIntents
import ActivityKit
import UIKit

@available(iOS 17.0, *)
struct CounterIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Cập nhật bộ đếm"

    @Parameter(title: "Thay đổi")
    var delta: Int

    init() {
        self.delta = 0
    }

    init(delta: Int) {
        self.delta = delta
    }

    func perform() async throws -> some IntentResult {
        for activity in Activity<MyIslandAttributes>.activities {
            var newState = activity.content.state
            newState.counter = max(0, newState.counter + delta)
            let content = ActivityContent(state: newState, staleDate: nil)
            await activity.update(content)
        }
        return .result()
    }
}

@available(iOS 17.0, *)
struct CycleModeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Đổi chế độ hiển thị"

    init() {}

    func perform() async throws -> some IntentResult {
        let battery = BatteryHelper.currentStatus()
        for activity in Activity<MyIslandAttributes>.activities {
            var newState = activity.content.state
            newState.mode = newState.mode.next()
            newState.batteryLevel = battery.level
            newState.isCharging = battery.isCharging
            let content = ActivityContent(state: newState, staleDate: nil)
            await activity.update(content)
        }
        return .result()
    }
}

@available(iOS 17.0, *)
struct ResetStopwatchIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Đặt lại đồng hồ bấm giờ"

    init() {}

    func perform() async throws -> some IntentResult {
        for activity in Activity<MyIslandAttributes>.activities {
            var newState = activity.content.state
            newState.stopwatchStart = Date()
            let content = ActivityContent(state: newState, staleDate: nil)
            await activity.update(content)
        }
        return .result()
    }
}

@available(iOS 17.0, *)
struct ToggleTodoIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Đánh dấu việc cần làm"

    @Parameter(title: "Mã công việc")
    var todoId: String

    init() {
        self.todoId = ""
    }

    init(todoId: String) {
        self.todoId = todoId
    }

    func perform() async throws -> some IntentResult {
        for activity in Activity<MyIslandAttributes>.activities {
            var newState = activity.content.state
            if let index = newState.todos.firstIndex(where: { $0.id == todoId }) {
                newState.todos[index].isDone.toggle()
            }
            let content = ActivityContent(state: newState, staleDate: nil)
            await activity.update(content)
        }
        return .result()
    }
}

@available(iOS 17.0, *)
struct RefreshBatteryIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Làm mới phần trăm pin"

    init() {}

    func perform() async throws -> some IntentResult {
        let battery = BatteryHelper.currentStatus()
        for activity in Activity<MyIslandAttributes>.activities {
            var newState = activity.content.state
            newState.batteryLevel = battery.level
            newState.isCharging = battery.isCharging
            let content = ActivityContent(state: newState, staleDate: nil)
            await activity.update(content)
        }
        return .result()
    }
}