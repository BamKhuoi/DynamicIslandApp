import ActivityKit
import SwiftUI
import UIKit

enum IslandDisplayMode: String, Codable, CaseIterable, Hashable {
    case text = "Chữ"
    case clock = "Đồng hồ"
    case weather = "Thời tiết"
    case countdown = "Đếm ngược"

    func next() -> IslandDisplayMode {
        let all = Self.allCases
        guard let idx = all.firstIndex(of: self) else { return .text }
        return all[(idx + 1) % all.count]
    }
}

enum IslandFontStyle: String, Codable, CaseIterable, Hashable {
    case standard = "Mặc định"
    case rounded = "Bo tròn"
    case monospaced = "Code"
    case serif = "Cổ điển"

    var design: Font.Design {
        switch self {
        case .standard: return .default
        case .rounded: return .rounded
        case .monospaced: return .monospaced
        case .serif: return .serif
        }
    }
}

struct QuickShortcut: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var icon: String
    var urlString: String
}

struct MyIslandAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var compactText: String
        var expandedTitle: String
        var expandedSubtitle: String
        var iconName: String
        var useEmoji: Bool
        var emojiText: String
        var iconColorHex: String
        var textColorHex: String
        var keylineColorHex: String
        var useKeyline: Bool
        var fontStyle: IslandFontStyle
        var mode: IslandDisplayMode
        var weatherInfo: String
        var countdownStart: Date
        var countdownEnd: Date
        var counter: Int
        var showCounter: Bool
        var showLauncher: Bool
        var shortcuts: [QuickShortcut]

        var safeCountdownRange: ClosedRange<Date> {
            let safeEnd = max(countdownEnd, countdownStart.addingTimeInterval(1))
            return countdownStart...safeEnd
        }

        static let defaultShortcuts: [QuickShortcut] = [
            QuickShortcut(name: "YouTube", icon: "play.rectangle.fill", urlString: "youtube://"),
            QuickShortcut(name: "Messenger", icon: "message.fill", urlString: "fb-messenger://"),
            QuickShortcut(name: "Spotify", icon: "music.note", urlString: "spotify://"),
            QuickShortcut(name: "Google", icon: "safari.fill", urlString: "https://google.com")
        ]

        static let `default` = ContentState(
            compactText: "DEV",
            expandedTitle: "Hoàng Linh",
            expandedSubtitle: "Đang tập trung code...",
            iconName: "terminal.fill",
            useEmoji: false,
            emojiText: "🔥",
            iconColorHex: "00FF9C",
            textColorHex: "00E5FF",
            keylineColorHex: "00E5FF",
            useKeyline: true,
            fontStyle: .monospaced,
            mode: .text,
            weatherInfo: "26°C",
            countdownStart: Date(),
            countdownEnd: Date().addingTimeInterval(25 * 60),
            counter: 0,
            showCounter: true,
            showLauncher: true,
            shortcuts: defaultShortcuts
        )
    }
}

struct IslandPreset: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var state: MyIslandAttributes.ContentState
    var countdownMinutes: Int
    var countdownSeconds: Int
    var cityName: String
    var isBuiltIn: Bool = false

    static let builtInPresets: [IslandPreset] = [
        IslandPreset(
            id: "builtin-cyber",
            name: "Cyber Dev",
            state: .default,
            countdownMinutes: 25,
            countdownSeconds: 0,
            cityName: "Hanoi",
            isBuiltIn: true
        ),
        IslandPreset(
            id: "builtin-pomodoro",
            name: "Pomodoro 25p",
            state: MyIslandAttributes.ContentState(
                compactText: "FOCUS",
                expandedTitle: "Tập trung học bài",
                expandedSubtitle: "Phiên Pomodoro 25 phút",
                iconName: "flame.fill",
                useEmoji: false,
                emojiText: "🍅",
                iconColorHex: "FF5E3A",
                textColorHex: "FFD60A",
                keylineColorHex: "FF5E3A",
                useKeyline: true,
                fontStyle: .rounded,
                mode: .countdown,
                weatherInfo: "26°C",
                countdownStart: Date(),
                countdownEnd: Date().addingTimeInterval(25 * 60),
                counter: 1,
                showCounter: true,
                showLauncher: false,
                shortcuts: MyIslandAttributes.ContentState.defaultShortcuts
            ),
            countdownMinutes: 25,
            countdownSeconds: 0,
            cityName: "Hanoi",
            isBuiltIn: true
        ),
        IslandPreset(
            id: "builtin-gym",
            name: "Nghỉ tập 90s",
            state: MyIslandAttributes.ContentState(
                compactText: "GYM",
                expandedTitle: "Nghỉ giữa hiệp",
                expandedSubtitle: "Bấm + để đếm số hiệp",
                iconName: "dumbbell.fill",
                useEmoji: false,
                emojiText: "💪",
                iconColorHex: "32D74B",
                textColorHex: "FFFFFF",
                keylineColorHex: "32D74B",
                useKeyline: true,
                fontStyle: .rounded,
                mode: .countdown,
                weatherInfo: "26°C",
                countdownStart: Date(),
                countdownEnd: Date().addingTimeInterval(90),
                counter: 1,
                showCounter: true,
                showLauncher: true,
                shortcuts: MyIslandAttributes.ContentState.defaultShortcuts
            ),
            countdownMinutes: 1,
            countdownSeconds: 30,
            cityName: "Hanoi",
            isBuiltIn: true
        ),
        IslandPreset(
            id: "builtin-minimal",
            name: "Đồng hồ Tối giản",
            state: MyIslandAttributes.ContentState(
                compactText: "LIVE",
                expandedTitle: "Thời gian thực",
                expandedSubtitle: "Chế độ tối giản",
                iconName: "clock.fill",
                useEmoji: false,
                emojiText: "⌚",
                iconColorHex: "BF5AF2",
                textColorHex: "FFFFFF",
                keylineColorHex: "BF5AF2",
                useKeyline: true,
                fontStyle: .monospaced,
                mode: .clock,
                weatherInfo: "26°C",
                countdownStart: Date(),
                countdownEnd: Date().addingTimeInterval(600),
                counter: 0,
                showCounter: false,
                showLauncher: true,
                shortcuts: MyIslandAttributes.ContentState.defaultShortcuts
            ),
            countdownMinutes: 10,
            countdownSeconds: 0,
            cityName: "Hanoi",
            isBuiltIn: true
        )
    ]
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 255, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }

    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return String(
                format: "%02X%02X%02X",
                Int(round(r * 255)),
                Int(round(g * 255)),
                Int(round(b * 255))
            )
        }
        var w: CGFloat = 1
        if uiColor.getWhite(&w, alpha: &a) {
            let v = Int(round(w * 255))
            return String(format: "%02X%02X%02X", v, v, v)
        }
        return "FFFFFF"
    }
}