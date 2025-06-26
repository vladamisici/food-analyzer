import Foundation

protocol AuthRepositoryProtocol {
    func register(request: RegisterRequest) async -> AppResult<AuthResponse>
    func login(request: LoginRequest) async -> AppResult<AuthResponse>
    func logout() async -> AppResult<Void>
    func refreshToken() async -> AppResult<AuthResponse>
    func getCurrentUser() async -> AppResult<User>
    
    // Local storage
    func saveAuthData(_ response: AuthResponse) -> AppResult<Void>
    func getStoredAuthToken() -> AppResult<String>
    func getStoredUser() -> AppResult<User>
    func clearAuthData() -> AppResult<Void>
    func isAuthenticated() -> Bool
}

final class AuthRepository: AuthRepositoryProtocol {
    private let apiService: APIServiceProtocol
    private let keychainManager: KeychainManager
    
    init(apiService: APIServiceProtocol = APIService.shared, 
         keychainManager: KeychainManager = .shared) {
        self.apiService = apiService
        self.keychainManager = keychainManager
    }
    
    // MARK: - Network Operations
    func register(request: RegisterRequest) async -> AppResult<AuthResponse> {
        // Validate request
        if let validationError = request.validate() {
            return .failure(.validation(validationError))
        }
        
        let result = await apiService.register(request: request)
        
        // Save auth data on success
        if case .success(let response) = result {
            _ = saveAuthData(response)
        }
        
        return result
    }
    
    func login(request: LoginRequest) async -> AppResult<AuthResponse> {
        // Validate request
        if let validationError = request.validate() {
            return .failure(.validation(validationError))
        }
        
        let result = await apiService.login(request: request)
        
        // Save auth data on success
        if case .success(let response) = result {
            _ = saveAuthData(response)
        }
        
        return result
    }
    
    func logout() async -> AppResult<Void> {
        // Clear local storage first
        let clearResult = clearAuthData()
        if clearResult.isFailure {
            return clearResult
        }
        
        // Then call API logout (best effort)
        let _ = await apiService.logout()
        
        return .success(())
    }
    
    func refreshToken() async -> AppResult<AuthResponse> {
        return await apiService.refreshToken()
    }
    
    func getCurrentUser() async -> AppResult<User> {
        return await apiService.getCurrentUser()
    }
    
    // MARK: - Local Storage Operations
    func saveAuthData(_ response: AuthResponse) -> AppResult<Void> {
        // Save token
        let tokenResult = keychainManager.saveString(response.token, forKey: KeychainManager.Keys.authToken)
        if tokenResult.isFailure {
            return tokenResult
        }
        
        // Save user
        let userResult = keychainManager.save(response.user, forKey: KeychainManager.Keys.currentUser)
        if userResult.isFailure {
            return userResult
        }
        
        return .success(())
    }
    
    func getStoredAuthToken() -> AppResult<String> {
        return keychainManager.loadString(forKey: KeychainManager.Keys.authToken)
    }
    
    func getStoredUser() -> AppResult<User> {
        return keychainManager.load(User.self, forKey: KeychainManager.Keys.currentUser)
    }
    
    func clearAuthData() -> AppResult<Void> {
        let tokenResult = keychainManager.delete(forKey: KeychainManager.Keys.authToken)
        let userResult = keychainManager.delete(forKey: KeychainManager.Keys.currentUser)
        
        if tokenResult.isFailure {
            return tokenResult
        }
        
        if userResult.isFailure {
            return userResult
        }
        
        return .success(())
    }
    
    func isAuthenticated() -> Bool {
        return keychainManager.exists(forKey: KeychainManager.Keys.authToken)
    }
}