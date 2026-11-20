import ActivityKit
import SwiftUI
import UIKit

enum IslandDisplayMode: String, Codable, CaseIterable, Hashable {
    case text = "Chữ"
    case clock = "Đồng hồ"
    case weather = "Thời tiết"
    case countdown = "Đếm ngược"
    case stopwatch = "Bấm giờ"
    case battery = "Pin"

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

enum IslandIconSource: String, Codable, CaseIterable, Hashable {
    case symbol = "SF Symbol"
    case emoji = "Emoji"
    case photo = "Ảnh máy"
}

enum IslandBackgroundStyle: String, Codable, CaseIterable, Hashable {
    case solid = "Màu đơn"
    case gradient = "Gradient"
    case glass = "Kính mờ"
}

struct QuickShortcut: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var icon: String
    var urlString: String

    enum CodingKeys: String, CodingKey {
        case id = "i"
        case name = "n"
        case icon = "c"
        case urlString = "u"
    }
}

struct TodoItem: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var isDone: Bool = false

    enum CodingKeys: String, CodingKey {
        case id = "i"
        case title = "t"
        case isDone = "d"
    }
}

enum BatteryHelper {
    static func currentStatus() -> (level: Int, isCharging: Bool) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let raw = UIDevice.current.batteryLevel
        let level = raw < 0 ? 100 : Int(round(raw * 100))
        let state = UIDevice.current.batteryState
        let isCharging = (state == .charging || state == .full)
        return (level, isCharging)
    }
}

enum ImageCompressor {
    /// Tạo bản ảnh gốc 240x240 sắc nét để lưu trong app, dùng nén lại tự động khi thay đổi Checklist/Phím tắt
    static func prepareMasterImage(_ uiImage: UIImage) -> Data? {
        let resized = renderSquare(uiImage, side: 240)
        return resized.jpegData(compressionQuality: 0.88)
    }

    /// Nén ảnh tối đa độ nét (ưu tiên 112px/96px chất lượng cao, loại bỏ ICC Display P3 để tiết kiệm ~500B)
    static func compressForIsland(_ uiImage: UIImage, maxBytes: Int) -> (data: Data, side: Int)? {
        let ladders: [(side: CGFloat, qualities: [CGFloat])] = [
            (112, [0.85, 0.78, 0.70, 0.62, 0.55]),
            (96,  [0.85, 0.78, 0.70, 0.62, 0.55, 0.48]),
            (80,  [0.82, 0.74, 0.65, 0.56, 0.46]),
            (64,  [0.78, 0.68, 0.58, 0.48, 0.38, 0.28]),
            (48,  [0.65, 0.50, 0.35, 0.22, 0.14])
        ]

        for step in ladders {
            let resized = renderSquare(uiImage, side: step.side)
            for q in step.qualities {
                if let data = resized.jpegData(compressionQuality: q), data.count <= maxBytes {
                    return (data, Int(step.side))
                }
            }
        }

        let tiny = renderSquare(uiImage, side: 32)
        if let fallback = tiny.jpegData(compressionQuality: 0.15) {
            return (fallback, 32)
        }
        return nil
    }

    static func compressForIsland(_ uiImage: UIImage) -> Data? {
        compressForIsland(uiImage, maxBytes: 1800)?.data
    }

    private static func renderSquare(_ uiImage: UIImage, side: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        format.preferredRange = .standard

        let targetSize = CGSize(width: side, height: side)
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { ctx in
            ctx.cgContext.interpolationQuality = .high
            let aspect = max(targetSize.width / uiImage.size.width, targetSize.height / uiImage.size.height)
            let w = uiImage.size.width * aspect
            let h = uiImage.size.height * aspect
            let rect = CGRect(
                x: (targetSize.width - w) / 2,
                y: (targetSize.height - h) / 2,
                width: w,
                height: h
            )
            uiImage.draw(in: rect)
        }
    }
}

struct MyIslandAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var compactText: String
        var expandedTitle: String
        var expandedSubtitle: String

        var iconSource: IslandIconSource
        var iconName: String
        var emojiText: String
        var customImageData: Data?
        var photoIsCircle: Bool

        var iconColorHex: String
        var textColorHex: String
        var keylineColorHex: String
        var useKeyline: Bool

        var bgStyle: IslandBackgroundStyle
        var bgColorHex: String
        var bgColor2Hex: String

        var fontStyle: IslandFontStyle
        var mode: IslandDisplayMode
        var weatherInfo: String

        var countdownStart: Date
        var countdownEnd: Date
        var stopwatchStart: Date

        var batteryLevel: Int
        var isCharging: Bool

        var counter: Int
        var showCounter: Bool

        var showTodos: Bool
        var todos: [TodoItem]

        var showLauncher: Bool
        var shortcuts: [QuickShortcut]

        enum CodingKeys: String, CodingKey {
            case compactText = "a"
            case expandedTitle = "b"
            case expandedSubtitle = "c"
            case iconSource = "d"
            case iconName = "e"
            case emojiText = "f"
            case customImageData = "g"
            case photoIsCircle = "h"
            case iconColorHex = "i"
            case textColorHex = "j"
            case keylineColorHex = "k"
            case useKeyline = "l"
            case bgStyle = "m"
            case bgColorHex = "n"
            case bgColor2Hex = "o"
            case fontStyle = "p"
            case mode = "q"
            case weatherInfo = "r"
            case countdownStart = "s"
            case countdownEnd = "t"
            case stopwatchStart = "u"
            case batteryLevel = "v"
            case isCharging = "w"
            case counter = "x"
            case showCounter = "y"
            case showTodos = "z"
            case todos = "td"
            case showLauncher = "sl"
            case shortcuts = "sc"
        }

        var safeCountdownRange: ClosedRange<Date> {
            let safeEnd = max(countdownEnd, countdownStart.addingTimeInterval(1))
            return countdownStart...safeEnd
        }

        /// Tự động cắt dữ liệu các mục đang tắt và phân bổ toàn bộ dung lượng trống cho ảnh sắc nét nhất
        func optimizedForLiveActivity(masterImageData: Data?) -> (state: ContentState, payloadBytes: Int, imageBytes: Int, imageSide: Int) {
            var slim = self

            if !slim.showTodos {
                slim.todos = []
            } else {
                slim.todos = slim.todos
                    .filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .prefix(3)
                    .enumerated()
                    .map { idx, item in
                        TodoItem(id: "t\(idx + 1)", title: item.title, isDone: item.isDone)
                    }
                if slim.todos.isEmpty {
                    slim.showTodos = false
                }
            }

            if !slim.showLauncher {
                slim.shortcuts = []
            } else {
                slim.shortcuts = slim.shortcuts
                    .filter { !$0.urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .prefix(4)
                    .enumerated()
                    .map { idx, item in
                        QuickShortcut(id: "s\(idx + 1)", name: item.name, icon: item.icon, urlString: item.urlString)
                    }
            }

            if slim.mode != .text { slim.compactText = "" }
            if slim.mode != .weather { slim.weatherInfo = "" }
            if slim.iconSource != .symbol { slim.iconName = "" }
            if slim.iconSource != .emoji { slim.emojiText = "" }

            slim.customImageData = nil
            let encoder = JSONEncoder()
            let baseBytes = (try? encoder.encode(slim).count) ?? 650

            var finalImageBytes = 0
            var finalImageSide = 0

            if slim.iconSource == .photo {
                // Giữ trần tổng JSON ở 3,600 bytes (dư ~500 bytes an toàn dưới ngưỡng 4,096 bytes của iOS)
                let targetTotalJSON = 3600
                let availableBase64 = max(800, targetTotalJSON - baseBytes)
                let maxRawImageBytes = max(600, (availableBase64 * 3) / 4 - 16)

                if let sourceData = masterImageData ?? self.customImageData,
                   let uiImage = UIImage(data: sourceData),
                   let compressed = ImageCompressor.compressForIsland(uiImage, maxBytes: maxRawImageBytes) {
                    slim.customImageData = compressed.data
                    finalImageBytes = compressed.data.count
                    finalImageSide = compressed.side
                }
            }

            let totalPayload = (try? encoder.encode(slim).count) ?? baseBytes
            return (slim, totalPayload, finalImageBytes, finalImageSide)
        }

        static let defaultShortcuts: [QuickShortcut] = [
            QuickShortcut(id: "s1", name: "YouTube", icon: "play.rectangle.fill", urlString: "youtube://"),
            QuickShortcut(id: "s2", name: "Messenger", icon: "message.fill", urlString: "fb-messenger://"),
            QuickShortcut(id: "s3", name: "Spotify", icon: "music.note", urlString: "spotify://"),
            QuickShortcut(id: "s4", name: "Zalo", icon: "bubble.left.fill", urlString: "zalo://")
        ]

        static let defaultTodos: [TodoItem] = [
            TodoItem(id: "t1", title: "Hoàn thành bài tập", isDone: false),
            TodoItem(id: "t2", title: "Tập gym 45 phút", isDone: false),
            TodoItem(id: "t3", title: "Uống đủ 2L nước", isDone: false)
        ]

        static let `default` = ContentState(
            compactText: "DEV",
            expandedTitle: "Island Studio",
            expandedSubtitle: "Chạm giữ để tương tác",
            iconSource: .symbol,
            iconName: "terminal.fill",
            emojiText: "🔥",
            customImageData: nil,
            photoIsCircle: true,
            iconColorHex: "00FF9C",
            textColorHex: "00E5FF",
            keylineColorHex: "00E5FF",
            useKeyline: true,
            bgStyle: .gradient,
            bgColorHex: "0B132B",
            bgColor2Hex: "1C2541",
            fontStyle: .monospaced,
            mode: .text,
            weatherInfo: "26°C",
            countdownStart: Date(),
            countdownEnd: Date().addingTimeInterval(25 * 60),
            stopwatchStart: Date(),
            batteryLevel: 85,
            isCharging: false,
            counter: 0,
            showCounter: true,
            showTodos: true,
            todos: defaultTodos,
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
                iconSource: .symbol,
                iconName: "flame.fill",
                emojiText: "🍅",
                customImageData: nil,
                photoIsCircle: true,
                iconColorHex: "FF5E3A",
                textColorHex: "FFD60A",
                keylineColorHex: "FF5E3A",
                useKeyline: true,
                bgStyle: .gradient,
                bgColorHex: "2B0A0A",
                bgColor2Hex: "0F0F12",
                fontStyle: .rounded,
                mode: .countdown,
                weatherInfo: "26°C",
                countdownStart: Date(),
                countdownEnd: Date().addingTimeInterval(25 * 60),
                stopwatchStart: Date(),
                batteryLevel: 85,
                isCharging: false,
                counter: 1,
                showCounter: true,
                showTodos: true,
                todos: MyIslandAttributes.ContentState.defaultTodos,
                showLauncher: false,
                shortcuts: MyIslandAttributes.ContentState.defaultShortcuts
            ),
            countdownMinutes: 25,
            countdownSeconds: 0,
            cityName: "Hanoi",
            isBuiltIn: true
        ),
        IslandPreset(
            id: "builtin-stopwatch",
            name: "Bấm giờ Gym",
            state: MyIslandAttributes.ContentState(
                compactText: "GYM",
                expandedTitle: "Đang tập luyện",
                expandedSubtitle: "Bấm Reset để tính hiệp mới",
                iconSource: .symbol,
                iconName: "dumbbell.fill",
                emojiText: "💪",
                customImageData: nil,
                photoIsCircle: true,
                iconColorHex: "32D74B",
                textColorHex: "FFFFFF",
                keylineColorHex: "32D74B",
                useKeyline: true,
                bgStyle: .solid,
                bgColorHex: "0D1F12",
                bgColor2Hex: "09120C",
                fontStyle: .rounded,
                mode: .stopwatch,
                weatherInfo: "26°C",
                countdownStart: Date(),
                countdownEnd: Date().addingTimeInterval(90),
                stopwatchStart: Date(),
                batteryLevel: 85,
                isCharging: false,
                counter: 1,
                showCounter: true,
                showTodos: false,
                todos: MyIslandAttributes.ContentState.defaultTodos,
                showLauncher: true,
                shortcuts: MyIslandAttributes.ContentState.defaultShortcuts
            ),
            countdownMinutes: 1,
            countdownSeconds: 30,
            cityName: "Hanoi",
            isBuiltIn: true
        ),
        IslandPreset(
            id: "builtin-battery",
            name: "Theo dõi Pin",
            state: MyIslandAttributes.ContentState(
                compactText: "BAT",
                expandedTitle: "Trạng thái Pin",
                expandedSubtitle: "Bấm biểu tượng làm mới để cập nhật",
                iconSource: .symbol,
                iconName: "bolt.fill",
                emojiText: "🔋",
                customImageData: nil,
                photoIsCircle: true,
                iconColorHex: "30D158",
                textColorHex: "FFFFFF",
                keylineColorHex: "30D158",
                useKeyline: true,
                bgStyle: .glass,
                bgColorHex: "111827",
                bgColor2Hex: "000000",
                fontStyle: .monospaced,
                mode: .battery,
                weatherInfo: "26°C",
                countdownStart: Date(),
                countdownEnd: Date().addingTimeInterval(600),
                stopwatchStart: Date(),
                batteryLevel: 85,
                isCharging: false,
                counter: 0,
                showCounter: false,
                showTodos: false,
                todos: MyIslandAttributes.ContentState.defaultTodos,
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