import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    let isEnabled: Bool
    let style: ButtonStyle
    
    init(
        _ title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.textColor))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(.theme.titleMedium)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(style.textColor)
            .frame(maxWidth: .infinity)
            .frame(height: .spacing.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: isEnabled ? style.backgroundColors : style.disabledColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: style.shadowColor.opacity(isEnabled ? 0.3 : 0.1),
                        radius: isEnabled ? 8 : 4,
                        x: 0,
                        y: isEnabled ? 4 : 2
                    )
            )
            .scaleEffect(isEnabled ? 1.0 : 0.98)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Button Styles
extension PrimaryButton {
    enum ButtonStyle {
        case primary
        case secondary
        case success
        case destructive
        case ghost
        
        var backgroundColors: [Color] {
            switch self {
            case .primary:
                return [Color.theme.primary, Color.theme.primaryDark]
            case .secondary:
                return [Color.theme.secondary, Color.theme.secondaryDark]
            case .success:
                return [Color.theme.success, Color.theme.success.opacity(0.8)]
            case .destructive:
                return [Color.theme.error, Color.theme.error.opacity(0.8)]
            case .ghost:
                return [Color.clear]
            }
        }
        
        var disabledColors: [Color] {
            return [Color.theme.textTertiary, Color.theme.textTertiary]
        }
        
        var textColor: Color {
            switch self {
            case .primary, .secondary, .success, .destructive:
                return Color.theme.textOnPrimary
            case .ghost:
                return Color.theme.primary
            }
        }
        
        var shadowColor: Color {
            switch self {
            case .primary:
                return Color.theme.primary
            case .secondary:
                return Color.theme.secondary
            case .success:
                return Color.theme.success
            case .destructive:
                return Color.theme.error
            case .ghost:
                return Color.clear
            }
        }
    }
}

// MARK: - Pressable Button Style
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: .spacing.md) {
        PrimaryButton("Sign In", style: .primary) { }
        PrimaryButton("Create Account", style: .secondary) { }
        PrimaryButton("Analyze Food", style: .success) { }
        PrimaryButton("Delete", style: .destructive) { }
        PrimaryButton("Loading...", isLoading: true) { }
        PrimaryButton("Disabled", isEnabled: false) { }
    }
    .containerPadding()
}