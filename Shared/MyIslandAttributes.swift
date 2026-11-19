import ActivityKit
import SwiftUI
import UIKit

enum IslandDisplayMode: String, Codable, CaseIterable, Hashable {
    case text = "Chữ"
    case clock = "Đồng hồ"
    case weather = "Thời tiết"
}

struct MyIslandAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var compactText: String
        var expandedTitle: String
        var expandedSubtitle: String
        var iconName: String
        var iconColorHex: String
        var textColorHex: String
        var mode: IslandDisplayMode
        var weatherInfo: String
    }
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
        var r: CGFloat = 1
        var g: CGFloat = 1
        var b: CGFloat = 1
        var a: CGFloat = 1
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(
            format: "%02X%02X%02X",
            Int(round(r * 255)),
            Int(round(g * 255)),
            Int(round(b * 255))
        )
    }
}