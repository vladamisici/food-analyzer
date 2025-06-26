import SwiftUI

struct EnhancedRegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentStep = 0
    @State private var animateStep = false
    
    private let totalSteps = 3
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.theme.background,
                        Color.theme.backgroundSecondary,
                        Color.theme.primary.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Header
                    progressHeader
                    
                    // Step Content
                    stepContent
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
                    
                    // Navigation
                    navigationButtons
                }
            }
        }
        .navigationBarHidden(true)
        .overlay(
            // Error Toast
            errorToast,
            alignment: .top
        )
    }
    
    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: .spacing.lg) {
            // Navigation Bar
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color.theme.textSecondary)
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(Color.theme.surface)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                
                Spacer()
                
                Text("Create Account")
                    .titleLarge()
                
                Spacer()
                
                // Placeholder for symmetry
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .containerPadding()
            
            // Progress Bar
            VStack(spacing: .spacing.sm) {
                HStack(spacing: .spacing.xs) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        progressSegment(for: index)
                    }
                }
                
                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .labelMedium()
                    .foregroundColor(Color.theme.textSecondary)
            }
            .containerPadding()
        }
        .background(Color.theme.surface)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    private func progressSegment(for index: Int) -> some View {
        Rectangle()
            .fill(index <= currentStep ? Color.theme.primary : Color.theme.textTertiary.opacity(0.3))
            .frame(height: 4)
            .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.1), value: currentStep)
    }
    
    // MARK: - Step Content
    private var stepContent: some View {
        TabView(selection: $currentStep) {
            // Step 1: Personal Information
            personalInfoStep
                .tag(0)
            
            // Step 2: Account Details
            accountDetailsStep
                .tag(1)
            
            // Step 3: Terms & Confirmation
            termsStep
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentStep)
    }
    
    // MARK: - Step 1: Personal Information
    private var personalInfoStep: some View {
        ScrollView {
            VStack(spacing: .spacing.xl) {
                // Header
                stepHeader(
                    title: "Tell us about yourself",
                    subtitle: "We'll use this information to personalize your experience"
                )
                
                // Form Fields
                VStack(spacing: .spacing.lg) {
                    CustomTextField.name(
                        "First Name",
                        text: $authViewModel.registerForm.firstName,
                        errorMessage: authViewModel.showError && authViewModel.registerForm.firstName.isEmpty ? "First name is required" : nil
                    )
                    
                    CustomTextField.name(
                        "Last Name",
                        text: $authViewModel.registerForm.lastName,
                        errorMessage: authViewModel.showError && authViewModel.registerForm.lastName.isEmpty ? "Last name is required" : nil
                    )
                }
                .containerPadding()
                
                Spacer()
            }
        }
    }
    
    // MARK: - Step 2: Account Details
    private var accountDetailsStep: some View {
        ScrollView {
            VStack(spacing: .spacing.xl) {
                // Header
                stepHeader(
                    title: "Create your account",
                    subtitle: "Choose a secure email and password"
                )
                
                // Form Fields
                VStack(spacing: .spacing.lg) {
                    CustomTextField.email(
                        text: $authViewModel.registerForm.email,
                        errorMessage: authViewModel.showError && !authViewModel.registerForm.email.isValidEmail && !authViewModel.registerForm.email.isEmpty ? "Invalid email format" : nil
                    )
                    
                    VStack(spacing: .spacing.sm) {
                        CustomTextField.password(
                            text: $authViewModel.registerForm.password,
                            title: "Password",
                            errorMessage: authViewModel.showError && !authViewModel.registerForm.password.isValidPassword && !authViewModel.registerForm.password.isEmpty ? "Password must be at least 8 characters with letters and numbers" : nil
                        )
                        
                        // Password Strength Indicator
                        if !authViewModel.registerForm.password.isEmpty {
                            passwordStrengthIndicator
                        }
                    }
                    
                    CustomTextField.password(
                        text: $authViewModel.registerForm.confirmPassword,
                        title: "Confirm Password",
                        errorMessage: authViewModel.showError && authViewModel.registerForm.password != authViewModel.registerForm.confirmPassword && !authViewModel.registerForm.confirmPassword.isEmpty ? "Passwords do not match" : nil
                    )
                }
                .containerPadding()
                
                Spacer()
            }
        }
    }
    
    // MARK: - Step 3: Terms & Confirmation
    private var termsStep: some View {
        ScrollView {
            VStack(spacing: .spacing.xl) {
                // Header
                stepHeader(
                    title: "Almost there!",
                    subtitle: "Review and accept our terms to complete your account"
                )
                
                // Account Summary
                accountSummary
                
                // Terms and Conditions
                termsAndConditions
                
                Spacer()
            }
        }
    }
    
    // MARK: - Password Strength Indicator
    private var passwordStrengthIndicator: some View {
        let strength = authViewModel.registerForm.passwordStrength
        
        return VStack(alignment: .leading, spacing: .spacing.xs) {
            HStack {
                Text("Password Strength:")
                    .labelMedium()
                
                Spacer()
                
                Text(strength.text)
                    .labelMedium(strength.color)
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.theme.textTertiary.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(strength.color)
                        .frame(width: geometry.size.width * strength.progress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeOut(duration: 0.3), value: strength.progress)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, .spacing.md)
    }
    
    // MARK: - Account Summary
    private var accountSummary: some View {
        VStack(spacing: .spacing.md) {
            Text("Account Summary")
                .titleMedium()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: .spacing.sm) {
                summaryRow("Name", value: "\(authViewModel.registerForm.firstName) \(authViewModel.registerForm.lastName)")
                summaryRow("Email", value: authViewModel.registerForm.email)
            }
            .cardPadding()
            .background(
                RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                    .fill(Color.theme.backgroundSecondary)
            )
        }
        .containerPadding()
    }
    
    private func summaryRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .bodyMedium()
            
            Spacer()
            
            Text(value)
                .bodyMedium()
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Terms and Conditions
    private var termsAndConditions: some View {
        VStack(spacing: .spacing.md) {
            // Terms Toggle
            Button(action: { authViewModel.registerForm.agreeToTerms.toggle() }) {
                HStack(spacing: .spacing.sm) {
                    Image(systemName: authViewModel.registerForm.agreeToTerms ? "checkmark.square.fill" : "square")
                        .foregroundColor(authViewModel.registerForm.agreeToTerms ? Color.theme.primary : Color.theme.textTertiary)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: .spacing.xs) {
                        Text("I agree to the Terms of Service and Privacy Policy")
                            .bodyMedium()
                            .multilineTextAlignment(.leading)
                        
                        Text("By creating an account, you agree to our terms")
                            .labelMedium()
                            .foregroundColor(Color.theme.textSecondary)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Terms Links
            HStack(spacing: .spacing.lg) {
                Button("Terms of Service") {
                    // Open terms
                }
                .titleMedium(Color.theme.primary)
                
                Button("Privacy Policy") {
                    // Open privacy policy
                }
                .titleMedium(Color.theme.primary)
            }
        }
        .containerPadding()
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        VStack(spacing: .spacing.md) {
            if currentStep < totalSteps - 1 {
                // Next Button
                PrimaryButton(
                    "Continue",
                    isEnabled: canProceedToNextStep,
                    style: .primary
                ) {
                    nextStep()
                }
                .containerPadding()
            } else {
                // Create Account Button
                PrimaryButton(
                    "Create Account",
                    isLoading: authViewModel.isLoading,
                    isEnabled: authViewModel.registerForm.canSubmit,
                    style: .success
                ) {
                    Task {
                        await authViewModel.register()
                        if authViewModel.isAuthenticated {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .containerPadding()
            }
            
            // Back Button
            if currentStep > 0 {
                Button("Back") {
                    previousStep()
                }
                .titleMedium(Color.theme.textSecondary)
            }
        }
        .background(Color.theme.surface)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -2)
    }
    
    // MARK: - Helper Views
    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: .spacing.sm) {
            Text(title)
                .headlineMedium()
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .bodyLarge(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .containerPadding()
    }
    
    // MARK: - Error Toast
    private var errorToast: some View {
        Group {
            if authViewModel.showError, let errorMessage = authViewModel.errorMessage {
                VStack {
                    HStack(spacing: .spacing.sm) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.white)
                        
                        Text(errorMessage)
                            .bodyMedium(.white)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Button(action: authViewModel.clearError) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.caption)
                        }
                    }
                    .cardPadding()
                    .background(
                        RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                            .fill(Color.theme.error)
                            .shadow(radius: 10)
                    )
                    .containerPadding()
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: authViewModel.showError)
    }
    
    // MARK: - Helper Methods
    private var canProceedToNextStep: Bool {
        switch currentStep {
        case 0:
            return !authViewModel.registerForm.firstName.isEmpty && !authViewModel.registerForm.lastName.isEmpty
        case 1:
            return authViewModel.registerForm.email.isValidEmail && 
                   authViewModel.registerForm.password.isValidPassword &&
                   authViewModel.registerForm.password == authViewModel.registerForm.confirmPassword
        case 2:
            return authViewModel.registerForm.agreeToTerms
        default:
            return false
        }
    }
    
    private func nextStep() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStep = min(currentStep + 1, totalSteps - 1)
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func previousStep() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStep = max(currentStep - 1, 0)
        }
    }
}

// MARK: - Preview
#Preview {
    EnhancedRegisterView()
        .environmentObject(AuthViewModel())
}