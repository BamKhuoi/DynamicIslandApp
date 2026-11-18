import ActivityKit

struct MyIslandAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var customText: String
    }
}