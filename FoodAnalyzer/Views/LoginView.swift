import SwiftUI

struct EnhancedLoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingRegister = false
    @State private var animateGradient = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated Background
                backgroundGradient
                
                // Content
                VStack(spacing: 0) {
                    // Header Section
                    headerSection(geometry: geometry)
                    
                    // Form Section
                    formSection
                    
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .sheet(isPresented: $showingRegister) {
            EnhancedRegisterView()
                .environmentObject(authViewModel)
        }
        .overlay(
            // Error Toast
            errorToast,
            alignment: .top
        )
        .onAppear {
            startGradientAnimation()
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.theme.primary.opacity(0.8),
                Color.theme.primaryDark,
                Color.theme.secondary.opacity(0.9)
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .animation(
            .easeInOut(duration: 4.0).repeatForever(autoreverses: true),
            value: animateGradient
        )
        .overlay(
            // Floating particles
            GeometryReader { geo in
                ForEach(0..<15, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: CGFloat.random(in: 20...60))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 3...8))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                            value: animateGradient
                        )
                }
            }
        )
    }
    
    // MARK: - Header Section
    private func headerSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: .spacing.lg) {
            Spacer()
                .frame(height: geometry.safeAreaInsets.top + .spacing.xl)
            
            // App Icon/Logo
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .blur(radius: 1)
                
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .scaleEffect(animateGradient ? 1.05 : 1.0)
            .animation(
                .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                value: animateGradient
            )
            
            // Title
            VStack(spacing: .spacing.sm) {
                Text("Food Analyzer")
                    .displayMedium(Color.white)
                    .multilineTextAlignment(.center)
                
                Text("Discover the nutrition in your food")
                    .titleMedium(Color.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
                .frame(height: .spacing.xxl)
        }
        .frame(height: geometry.size.height * 0.45)
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: .spacing.xl) {
                // Welcome Text
                VStack(spacing: .spacing.sm) {
                    Text("Welcome Back")
                        .headlineLarge()
                    
                    Text("Sign in to continue your nutrition journey")
                        .bodyLarge(Color.theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .paddingLG()
                
                // Form Fields
                VStack(spacing: .spacing.lg) {
                    CustomTextField.email(
                        text: $authViewModel.loginForm.email,
                        errorMessage: authViewModel.showError && !authViewModel.loginForm.email.isValidEmail && !authViewModel.loginForm.email.isEmpty ? "Invalid email format" : nil
                    )
                    
                    CustomTextField.password(
                        text: $authViewModel.loginForm.password,
                        errorMessage: authViewModel.showError && authViewModel.loginForm.password.isEmpty ? "Password is required" : nil
                    )
                }
                .containerPadding()
                
                // Login Button
                VStack(spacing: .spacing.md) {
                    PrimaryButton(
                        "Sign In",
                        isLoading: authViewModel.isLoading,
                        isEnabled: authViewModel.loginForm.canSubmit,
                        style: .primary
                    ) {
                        Task {
                            await authViewModel.login()
                        }
                    }
                    .containerPadding()
                    
                    // Forgot Password
                    Button("Forgot Password?") {
                        // Handle forgot password
                    }
                    .titleMedium(Color.theme.primary)
                }
                
                Spacer()
                    .frame(height: .spacing.xl)
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.theme.textTertiary.opacity(0.3))
                        .frame(height: 1)
                    
                    Text("or")
                        .labelMedium()
                        .padding(.horizontal, .spacing.md)
                    
                    Rectangle()
                        .fill(Color.theme.textTertiary.opacity(0.3))
                        .frame(height: 1)
                }
                .containerPadding()
                
                // Social Login (if available)
                socialLoginButtons
                
                // Register Button
                VStack(spacing: .spacing.sm) {
                    Text("Don't have an account?")
                        .bodyMedium()
                    
                    PrimaryButton(
                        "Create Account",
                        style: .ghost
                    ) {
                        showingRegister = true
                    }
                    .containerPadding()
                }
                
                Spacer()
                    .frame(height: .spacing.xl)
            }
            .background(
                RoundedRectangle(cornerRadius: .spacing.cornerRadiusLarge)
                    .fill(Color.theme.surface)
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: 30,
                        x: 0,
                        y: -10
                    )
            )
            .offset(y: -20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Social Login Buttons
    private var socialLoginButtons: some View {
        VStack(spacing: .spacing.sm) {
            // Apple Sign In
            Button(action: {}) {
                HStack(spacing: .spacing.sm) {
                    Image(systemName: "applelogo")
                        .font(.title3)
                    
                    Text("Continue with Apple")
                        .titleMedium()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: .spacing.buttonHeight)
                .background(Color.black)
                .cornerRadius(.spacing.cornerRadius)
            }
            
            // Google Sign In
            Button(action: {}) {
                HStack(spacing: .spacing.sm) {
                    Image(systemName: "globe")
                        .font(.title3)
                    
                    Text("Continue with Google")
                        .titleMedium()
                }
                .foregroundColor(Color.theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: .spacing.buttonHeight)
                .background(Color.theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                        .stroke(Color.theme.textTertiary.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(.spacing.cornerRadius)
            }
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
    private func startGradientAnimation() {
        animateGradient = true
    }
}

// MARK: - Preview
#Preview {
    EnhancedLoginView()
        .environmentObject(AuthViewModel())
}