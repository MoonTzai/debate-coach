import SwiftUI

enum DebateTheme {
    static let canvas = Color(hex: "F3F1EC")
    static let canvasSecondary = Color(hex: "ECE8E1")
    static let panel = Color(hex: "FBFAF7")
    static let panelSoft = Color(hex: "F7F4EE")
    static let bubbleAI = Color(hex: "F6F3ED")
    static let bubbleSystem = Color(hex: "F3E5E1")
    static let ink = Color(hex: "171717")
    static let inkSoft = Color(hex: "6E6A64")
    static let inkMuted = Color(hex: "98928A")
    static let accent = Color(hex: "1447D4")
    static let danger = Color(hex: "8C3D34")

    static let pageGradient = LinearGradient(
        colors: [canvas, canvasSecondary],
        startPoint: .top,
        endPoint: .bottom
    )

    static let userBubbleGradient = LinearGradient(
        colors: [Color(hex: "E2EAFF"), Color(hex: "D4E0FF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [Color(hex: "1B4FDC"), Color(hex: "0F2F8A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum DebateSpacing {
    static let page: CGFloat = 20
    static let section: CGFloat = 18
}

enum DebateRadius {
    static let xl: CGFloat = 30
    static let lg: CGFloat = 24
    static let md: CGFloat = 18
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
