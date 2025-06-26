import SwiftUI

extension Font {
    static let theme = TypographyTheme()
}

struct TypographyTheme {
    // Display
    let displayLarge = Font.system(size: 57, weight: .bold, design: .rounded)
    let displayMedium = Font.system(size: 45, weight: .bold, design: .rounded)
    let displaySmall = Font.system(size: 36, weight: .bold, design: .rounded)
    
    // Headline
    let headlineLarge = Font.system(size: 32, weight: .semibold, design: .rounded)
    let headlineMedium = Font.system(size: 28, weight: .semibold, design: .rounded)
    let headlineSmall = Font.system(size: 24, weight: .semibold, design: .rounded)
    
    // Title
    let titleLarge = Font.system(size: 22, weight: .medium, design: .default)
    let titleMedium = Font.system(size: 16, weight: .medium, design: .default)
    let titleSmall = Font.system(size: 14, weight: .medium, design: .default)
    
    // Body
    let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // Label
    let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
}

// Text Style Modifiers
extension Text {
    func displayLarge(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.displayLarge)
            .foregroundColor(color)
    }
    
    func headlineLarge(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.headlineLarge)
            .foregroundColor(color)
    }
    
    func headlineMedium(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.headlineMedium)
            .foregroundColor(color)
    }
    
    func titleLarge(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.titleLarge)
            .foregroundColor(color)
    }
    
    func titleMedium(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.titleMedium)
            .foregroundColor(color)
    }
    
    func bodyLarge(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.bodyLarge)
            .foregroundColor(color)
    }
    
    func bodyMedium(_ color: Color = Color.theme.textSecondary) -> some View {
        self.font(.theme.bodyMedium)
            .foregroundColor(color)
    }
    
    func labelMedium(_ color: Color = Color.theme.textSecondary) -> some View {
        self.font(.theme.labelMedium)
            .foregroundColor(color)
    }
    
    func displayMedium(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.displayMedium)
            .foregroundColor(color)
    }
}

// View Style Modifiers (for any View type)
extension View {
    func displayLargeStyle(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.displayLarge)
            .foregroundColor(color)
    }
    
    func displayMediumStyle(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.displayMedium)
            .foregroundColor(color)
    }
    
    func headlineLargeStyle(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.headlineLarge)
            .foregroundColor(color)
    }
    
    func headlineMediumStyle(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.headlineMedium)
            .foregroundColor(color)
    }
    
    func titleLargeStyle(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.titleLarge)
            .foregroundColor(color)
    }
    
    func titleMediumStyle(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.titleMedium)
            .foregroundColor(color)
    }
    
    func bodyLargeStyle(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.bodyLarge)
            .foregroundColor(color)
    }
    
    func bodyMediumStyle(_ color: Color = Color.theme.textSecondary) -> some View {
        self.font(.theme.bodyMedium)
            .foregroundColor(color)
    }
    
    func labelMediumStyle(_ color: Color = Color.theme.textSecondary) -> some View {
        self.font(.theme.labelMedium)
            .foregroundColor(color)
    }
}

// Button Style Modifiers
extension Button where Label == Text {
    func displayLarge(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.displayLarge)
            .foregroundColor(color)
    }
    
    func headlineLarge(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.headlineLarge)
            .foregroundColor(color)
    }
    
    func headlineMedium(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.headlineMedium)
            .foregroundColor(color)
    }
    
    func titleLarge(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.titleLarge)
            .foregroundColor(color)
    }
    
    func titleMedium(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.titleMedium)
            .foregroundColor(color)
    }
    
    func bodyLarge(_ color: Color = Color.theme.textPrimary) -> some View {
        self.font(.theme.bodyLarge)
            .foregroundColor(color)
    }
    
    func bodyMedium(_ color: Color = Color.theme.textSecondary) -> some View {
        self.font(.theme.bodyMedium)
            .foregroundColor(color)
    }
    
    func labelMedium(_ color: Color = Color.theme.textSecondary) -> some View {
        self.font(.theme.labelMedium)
            .foregroundColor(color)
    }
}