import SwiftUI

extension CGFloat {
    static let spacing = SpacingTheme()
}

struct SpacingTheme {
    // Base spacing unit (4pt)
    let unit: CGFloat = 4
    
    // Semantic spacing
    let xs: CGFloat = 4      // 1 unit
    let sm: CGFloat = 8      // 2 units  
    let md: CGFloat = 16     // 4 units
    let lg: CGFloat = 24     // 6 units
    let xl: CGFloat = 32     // 8 units
    let xxl: CGFloat = 48    // 12 units
    let xxxl: CGFloat = 64   // 16 units
    
    // Layout spacing
    let containerPadding: CGFloat = 20
    let cardPadding: CGFloat = 16
    let buttonHeight: CGFloat = 56
    let inputHeight: CGFloat = 48
    let cornerRadius: CGFloat = 12
    let cornerRadiusSmall: CGFloat = 8
    let cornerRadiusLarge: CGFloat = 20
    
    // Icon sizes
    let iconXS: CGFloat = 16
    let iconSM: CGFloat = 20
    let iconMD: CGFloat = 24
    let iconLG: CGFloat = 32
    let iconXL: CGFloat = 48
}

// Convenient padding modifiers
extension View {
    func paddingXS() -> some View {
        padding(.spacing.xs)
    }
    
    func paddingSM() -> some View {
        padding(.spacing.sm)
    }
    
    func paddingMD() -> some View {
        padding(.spacing.md)
    }
    
    func paddingLG() -> some View {
        padding(.spacing.lg)
    }
    
    func paddingXL() -> some View {
        padding(.spacing.xl)
    }
    
    func containerPadding() -> some View {
        padding(.spacing.containerPadding)
    }
    
    func cardPadding() -> some View {
        padding(.spacing.cardPadding)
    }
}