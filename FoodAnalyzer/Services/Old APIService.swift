import Foundation
import UIKit

class APIService: ObservableObject {
    static let shared = APIService()
    
    private init() {}
    
    func register(email: String, password: String, firstName: String, lastName: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(Config.authServiceURL)/register") else {
            throw APIError.invalidURL
        }
        
        let request = RegisterRequest(email: email, password: password, firstName: firstName, lastName: lastName)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(Config.authServiceURL)/login") else {
            throw APIError.invalidURL
        }
        
        let request = LoginRequest(email: email, password: password)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    func analyzeFood(image: UIImage, token: String) async throws -> FoodAnalysisResponse {
        guard let url = URL(string: "\(Config.foodServiceURL)/analyze") else {
            throw APIError.invalidURL
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.imageProcessingFailed
        }
        
        let base64String = imageData.base64EncodedString()
        let request = FoodAnalysisRequest(image: base64String)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(FoodAnalysisResponse.self, from: data)
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case imageProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .imageProcessingFailed:
            return "Failed to process image"
        }
    }
}