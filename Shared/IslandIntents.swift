import AppIntents
import ActivityKit

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
        for activity in Activity<MyIslandAttributes>.activities {
            var newState = activity.content.state
            newState.mode = newState.mode.next()
            let content = ActivityContent(state: newState, staleDate: nil)
            await activity.update(content)
        }
        return .result()
    }
}