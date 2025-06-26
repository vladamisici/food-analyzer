import SwiftUI

extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    // Primary Colors
    let primary = Color(hex: "6C5CE7")
    let primaryDark = Color(hex: "5B4BD6")
    let primaryLight = Color(hex: "A29BFE")
    
    // Secondary Colors
    let secondary = Color(hex: "00B894")
    let secondaryDark = Color(hex: "00A085")
    let secondaryLight = Color(hex: "55EFC4")
    
    // Accent Colors
    let accent = Color(hex: "FD79A8")
    let warning = Color(hex: "FDCB6E")
    let error = Color(hex: "E84393")
    let success = Color(hex: "00B894")
    
    // Neutral Colors
    let background = Color(hex: "FFEAA7").opacity(0.1)
    let backgroundSecondary = Color(hex: "F8F9FA")
    let surface = Color.white
    let surfaceSecondary = Color(hex: "F1F3F4")
    
    // Text Colors
    let textPrimary = Color(hex: "2D3436")
    let textSecondary = Color(hex: "636E72")
    let textTertiary = Color(hex: "B2BEC3")
    let textOnPrimary = Color.white
    
    // Dark Mode Colors
    let backgroundDark = Color(hex: "1A1A1A")
    let surfaceDark = Color(hex: "2D2D2D")
    let textPrimaryDark = Color(hex: "FFFFFF")
    let textSecondaryDark = Color(hex: "B0B0B0")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
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