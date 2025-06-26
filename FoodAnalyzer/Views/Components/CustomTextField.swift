import SwiftUI

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    let isEnabled: Bool
    let errorMessage: String?
    let icon: String?
    
    @FocusState private var isFocused: Bool
    @State private var isSecureVisible = false
    
    init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        isEnabled: Bool = true,
        errorMessage: String? = nil,
        icon: String? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.isEnabled = isEnabled
        self.errorMessage = errorMessage
        self.icon = icon
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacing.xs) {
            // Title
            if !title.isEmpty {
                Text(title)
                    .labelMedium()
                    .foregroundColor(isFocused ? Color.theme.primary : Color.theme.textSecondary)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            }
            
            // Input Field
            HStack(spacing: .spacing.sm) {
                // Leading Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(isFocused ? Color.theme.primary : Color.theme.textSecondary)
                        .frame(width: .spacing.iconSM, height: .spacing.iconSM)
                        .animation(.easeInOut(duration: 0.2), value: isFocused)
                }
                
                // Text Field
                Group {
                    if isSecure && !isSecureVisible {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .focused($isFocused)
                .disabled(!isEnabled)
                .bodyLargeStyle()
                
                // Trailing Icon (for secure fields)
                if isSecure {
                    Button(action: { isSecureVisible.toggle() }) {
                        Image(systemName: isSecureVisible ? "eye.slash" : "eye")
                            .foregroundColor(Color.theme.textSecondary)
                            .frame(width: .spacing.iconSM, height: .spacing.iconSM)
                    }
                }
            }
            .padding(.horizontal, .spacing.md)
            .frame(height: .spacing.inputHeight)
            .background(
                RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
                    .background(
                        RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                            .fill(backgroundColor)
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .animation(.easeInOut(duration: 0.2), value: errorMessage != nil)
            
            // Error Message
            if let errorMessage = errorMessage {
                HStack(spacing: .spacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(Color.theme.error)
                        .font(.caption)
                    
                    Text(errorMessage)
                        .labelMedium(Color.theme.error)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Computed Properties
    private var borderColor: Color {
        if let _ = errorMessage {
            return Color.theme.error
        }
        return isFocused ? Color.theme.primary : Color.theme.textTertiary.opacity(0.3)
    }
    
    private var borderWidth: CGFloat {
        if errorMessage != nil {
            return 2
        }
        return isFocused ? 2 : 1
    }
    
    private var backgroundColor: Color {
        if !isEnabled {
            return Color.theme.surfaceSecondary
        }
        return isFocused ? Color.theme.surface : Color.theme.backgroundSecondary
    }
}

// MARK: - Convenience Initializers
extension CustomTextField {
    static func email(
        text: Binding<String>,
        errorMessage: String? = nil
    ) -> CustomTextField {
        CustomTextField(
            "Email",
            text: text,
            placeholder: "Enter your email",
            keyboardType: .emailAddress,
            textContentType: .emailAddress,
            errorMessage: errorMessage,
            icon: "envelope"
        )
    }
    
    static func password(
        text: Binding<String>,
        title: String = "Password",
        errorMessage: String? = nil
    ) -> CustomTextField {
        CustomTextField(
            title,
            text: text,
            placeholder: "Enter your password",
            isSecure: true,
            textContentType: .password,
            errorMessage: errorMessage,
            icon: "lock"
        )
    }
    
    static func name(
        _ title: String,
        text: Binding<String>,
        errorMessage: String? = nil
    ) -> CustomTextField {
        CustomTextField(
            title,
            text: text,
            placeholder: "Enter your \(title.lowercased())",
            textContentType: .name,
            errorMessage: errorMessage,
            icon: "person"
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: .spacing.lg) {
        CustomTextField.email(text: .constant("john@example.com"))
        
        CustomTextField.password(text: .constant("password123"))
        
        CustomTextField.name("First Name", text: .constant("John"))
        
        CustomTextField(
            "Phone Number",
            text: .constant(""),
            placeholder: "(555) 123-4567",
            keyboardType: .phonePad,
            icon: "phone"
        )
        
        CustomTextField(
            "Error Example",
            text: .constant("invalid"),
            errorMessage: "This field is required",
            icon: "exclamationmark.triangle"
        )
        
        Spacer()
    }
    .containerPadding()
}