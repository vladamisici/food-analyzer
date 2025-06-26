import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authToken: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let tokenKey = "auth_token"
    private let userKey = "current_user"
    
    init() {
        loadSavedAuth()
    }
    
    func register(email: String, password: String, firstName: String, lastName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await APIService.shared.register(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )
            
            await handleAuthResponse(response)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await APIService.shared.login(email: email, password: password)
            await handleAuthResponse(response)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout() {
        isAuthenticated = false
        currentUser = nil
        authToken = nil
        
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
    }
    
    private func handleAuthResponse(_ response: AuthResponse) async {
        authToken = response.token
        currentUser = response.user
        isAuthenticated = true
        
        UserDefaults.standard.set(response.token, forKey: tokenKey)
        if let userData = try? JSONEncoder().encode(response.user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
    }
    
    private func loadSavedAuth() {
        if let token = UserDefaults.standard.string(forKey: tokenKey),
           let userData = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            authToken = token
            currentUser = user
            isAuthenticated = true
        }
    }
}