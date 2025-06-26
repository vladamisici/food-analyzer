import Foundation
import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Form States
    @Published var loginForm = LoginForm()
    @Published var registerForm = RegisterForm()
    
    // MARK: - Dependencies
    private let authRepository: AuthRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(authRepository: AuthRepositoryProtocol = AuthRepository()) {
        self.authRepository = authRepository
        loadSavedAuth()
        setupErrorHandling()
    }
    
    // MARK: - Public Methods
    func login() async {
        guard loginForm.isValid else {
            showValidationError(loginForm.validationError)
            return
        }
        
        await performAuthOperation {
            await authRepository.login(request: LoginRequest(
                email: loginForm.email,
                password: loginForm.password
            ))
        }
    }
    
    func register() async {
        guard registerForm.isValid else {
            showValidationError(registerForm.validationError)
            return
        }
        
        await performAuthOperation {
            await authRepository.register(request: RegisterRequest(
                email: registerForm.email,
                password: registerForm.password,
                firstName: registerForm.firstName,
                lastName: registerForm.lastName
            ))
        }
    }
    
    func logout() async {
        isLoading = true
        
        let result = await authRepository.logout()
        
        switch result {
        case .success:
            isAuthenticated = false
            currentUser = nil
            clearForms()
            
        case .failure(let error):
            showError(error)
        }
        
        isLoading = false
    }
    
    func refreshSession() async {
        guard authRepository.isAuthenticated() else { return }
        
        let result = await authRepository.refreshToken()
        
        switch result {
        case .success(let response):
            currentUser = response.user
            
        case .failure:
            // Refresh failed, logout user
            await logout()
        }
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Private Methods
    private func performAuthOperation(_ operation: () async -> AppResult<AuthResponse>) async {
        isLoading = true
        clearError()
        
        let result = await operation()
        
        switch result {
        case .success(let response):
            isAuthenticated = true
            currentUser = response.user
            clearForms()
            
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
        case .failure(let error):
            showError(error)
        }
        
        isLoading = false
    }
    
    private func loadSavedAuth() {
        guard authRepository.isAuthenticated() else { return }
        
        if case .success(let user) = authRepository.getStoredUser() {
            isAuthenticated = true
            currentUser = user
        }
    }
    
    private func setupErrorHandling() {
        // Auto-clear errors after 5 seconds
        $showError
            .filter { $0 }
            .delay(for: .seconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.clearError()
            }
            .store(in: &cancellables)
    }
    
    private func showError(_ error: AppError) {
        errorMessage = error.userFriendlyMessage
        showError = true
        
        // Add error haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    private func showValidationError(_ error: String?) {
        guard let error = error else { return }
        errorMessage = error
        showError = true
    }
    
    private func clearForms() {
        loginForm = LoginForm()
        registerForm = RegisterForm()
    }
}

// MARK: - Form Models
extension AuthViewModel {
    struct LoginForm {
        var email = ""
        var password = ""
        
        var isValid: Bool {
            return validationError == nil
        }
        
        var validationError: String? {
            if email.isEmpty || password.isEmpty {
                return "Please fill in all fields"
            }
            
            if !email.isValidEmail {
                return "Please enter a valid email address"
            }
            
            return nil
        }
        
        var canSubmit: Bool {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    struct RegisterForm {
        var email = ""
        var password = ""
        var confirmPassword = ""
        var firstName = ""
        var lastName = ""
        var agreeToTerms = false
        
        var isValid: Bool {
            return validationError == nil
        }
        
        var validationError: String? {
            if email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty {
                return "Please fill in all fields"
            }
            
            if !email.isValidEmail {
                return "Please enter a valid email address"
            }
            
            if !password.isValidPassword {
                return "Password must be at least 8 characters with letters and numbers"
            }
            
            if password != confirmPassword {
                return "Passwords do not match"
            }
            
            if !agreeToTerms {
                return "Please agree to the terms and conditions"
            }
            
            return nil
        }
        
        var canSubmit: Bool {
            return !email.isEmpty && 
                   !password.isEmpty && 
                   !firstName.isEmpty && 
                   !lastName.isEmpty &&
                   agreeToTerms
        }
        
        var passwordStrength: PasswordStrength {
            return PasswordStrength.evaluate(password)
        }
    }
}

// MARK: - Password Strength
enum PasswordStrength: CaseIterable {
    case veryWeak, weak, fair, good, strong
    
    var color: Color {
        switch self {
        case .veryWeak: return Color.theme.error
        case .weak: return Color.theme.error.opacity(0.8)
        case .fair: return Color.theme.warning
        case .good: return Color.theme.secondary
        case .strong: return Color.theme.success
        }
    }
    
    var text: String {
        switch self {
        case .veryWeak: return "Very Weak"
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .good: return "Good"
        case .strong: return "Strong"
        }
    }
    
    var progress: Double {
        switch self {
        case .veryWeak: return 0.2
        case .weak: return 0.4
        case .fair: return 0.6
        case .good: return 0.8
        case .strong: return 1.0
        }
    }
    
    static func evaluate(_ password: String) -> PasswordStrength {
        var score = 0
        
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.contains(where: { $0.isLowercase }) { score += 1 }
        if password.contains(where: { $0.isUppercase }) { score += 1 }
        if password.contains(where: { $0.isNumber }) { score += 1 }
        if password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) { score += 1 }
        
        switch score {
        case 0...1: return .veryWeak
        case 2: return .weak
        case 3...4: return .fair
        case 5: return .good
        case 6: return .strong
        default: return .strong
        }
    }
}