import Foundation
import UIKit

protocol APIServiceProtocol {
    func register(request: RegisterRequest) async -> AppResult<AuthResponse>
    func login(request: LoginRequest) async -> AppResult<AuthResponse>
    func logout() async -> AppResult<Void>
    func refreshToken() async -> AppResult<AuthResponse>
    func getCurrentUser() async -> AppResult<User>
    func analyzeFood(image: UIImage, metadata: FoodAnalysisRequest.ImageMetadata?) async -> AppResult<FoodAnalysisResponse>
    func getAnalysisHistory() async -> AppResult<AnalysisHistory>
}

final class APIService: APIServiceProtocol {
    static let shared = APIService()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Auth Endpoints
    func register(request: RegisterRequest) async -> AppResult<AuthResponse> {
        guard let url = URL(string: "\(Config.authServiceURL)/register") else {
            return .failure(.networking(.invalidResponse))
        }
        
        return await performRequestWithBody(url: url, method: .POST, body: request)
    }
    
    func login(request: LoginRequest) async -> AppResult<AuthResponse> {
        guard let url = URL(string: "\(Config.authServiceURL)/login") else {
            return .failure(.networking(.invalidResponse))
        }
        
        return await performRequestWithBody(url: url, method: .POST, body: request)
    }
    
    func logout() async -> AppResult<Void> {
        guard let url = URL(string: "\(Config.authServiceURL)/logout") else {
            return .failure(.networking(.invalidResponse))
        }
        
        return await performVoidRequest(url: url, method: .POST, requiresAuth: true)
    }
    
    func refreshToken() async -> AppResult<AuthResponse> {
        guard let url = URL(string: "\(Config.authServiceURL)/refresh") else {
            return .failure(.networking(.invalidResponse))
        }
        
        return await performRequest(url: url, method: .POST, requiresAuth: true)
    }
    
    func getCurrentUser() async -> AppResult<User> {
        guard let url = URL(string: "\(Config.authServiceURL)/me") else {
            return .failure(.networking(.invalidResponse))
        }
        
        return await performRequest(url: url, method: .GET, requiresAuth: true)
    }
    
    // MARK: - Food Analysis Endpoints
    func analyzeFood(image: UIImage, metadata: FoodAnalysisRequest.ImageMetadata?) async -> AppResult<FoodAnalysisResponse> {
        guard let url = URL(string: "\(Config.foodServiceURL)/analyze") else {
            return .failure(.networking(.invalidResponse))
        }
        
        // Optimize image
        let optimizedImage = optimizeImage(image)
        guard let imageData = optimizedImage.jpegData(compressionQuality: 0.8) else {
            return .failure(.networking(.imageProcessingFailed))
        }
        
        let base64String = imageData.base64EncodedString()
        
        // Simple request format as per API spec
        let request = ["image": base64String]
        
        return await performRequestWithBody(url: url, method: .POST, body: request, requiresAuth: true)
    }
    
    func getAnalysisHistory() async -> AppResult<AnalysisHistory> {
        guard let url = URL(string: "\(Config.foodServiceURL)/history") else {
            return .failure(.networking(.invalidResponse))
        }
        
        return await performRequest(url: url, method: .GET, requiresAuth: true)
    }
    
    // MARK: - Private Methods
    private func performRequest<T: Codable>(
        url: URL,
        method: HTTPMethod,
        requiresAuth: Bool = false
    ) async -> AppResult<T> {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("FoodAnalyzer iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add auth header if required
        if requiresAuth {
            switch KeychainManager.shared.loadString(forKey: KeychainManager.Keys.authToken) {
            case .success(let token):
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            case .failure:
                return .failure(.authentication(.unauthorized))
            }
        }
        
        return await executeRequest(request: request)
    }
    
    private func performRequestWithBody<T: Codable, B: Codable>(
        url: URL,
        method: HTTPMethod,
        body: B,
        requiresAuth: Bool = false
    ) async -> AppResult<T> {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("FoodAnalyzer iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add auth header if required
        if requiresAuth {
            switch KeychainManager.shared.loadString(forKey: KeychainManager.Keys.authToken) {
            case .success(let token):
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            case .failure:
                return .failure(.authentication(.unauthorized))
            }
        }
        
        // Add body 
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            return .failure(.networking(.decodingError))
        }
        
        return await executeRequest(request: request)
    }
    
    private func performVoidRequest(
        url: URL,
        method: HTTPMethod,
        requiresAuth: Bool = false
    ) async -> AppResult<Void> {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("FoodAnalyzer iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add auth header if required
        if requiresAuth {
            switch KeychainManager.shared.loadString(forKey: KeychainManager.Keys.authToken) {
            case .success(let token):
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            case .failure:
                return .failure(.authentication(.unauthorized))
            }
        }
        
        return await executeVoidRequest(request: request)
    }
    
    private func executeRequest<T: Codable>(request: URLRequest) async -> AppResult<T> {
        // Perform request
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networking(.invalidResponse))
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success - decode response
                do {
                    let decodedResponse = try decoder.decode(T.self, from: data)
                    return .success(decodedResponse)
                } catch {
                    return .failure(.networking(.decodingError))
                }
                
            case 401:
                return .failure(.authentication(.unauthorized))
                
            case 403:
                return .failure(.authentication(.tokenExpired))
                
            case 409:
                return .failure(.authentication(.userExists))
                
            case 422:
                return .failure(.validation(.invalidEmail))
                
            default:
                return .failure(.networking(.serverError(httpResponse.statusCode)))
            }
            
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    return .failure(.networking(.noConnection))
                case .timedOut:
                    return .failure(.networking(.timeout))
                default:
                    return .failure(.networking(.invalidResponse))
                }
            } else {
                return .failure(.networking(.invalidResponse))
            }
        }
    }
    
    private func executeVoidRequest(request: URLRequest) async -> AppResult<Void> {
        // Perform request
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networking(.invalidResponse))
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                return .success(())
                
            case 401:
                return .failure(.authentication(.unauthorized))
                
            case 403:
                return .failure(.authentication(.tokenExpired))
                
            case 409:
                return .failure(.authentication(.userExists))
                
            case 422:
                return .failure(.validation(.invalidEmail))
                
            default:
                return .failure(.networking(.serverError(httpResponse.statusCode)))
            }
            
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    return .failure(.networking(.noConnection))
                case .timedOut:
                    return .failure(.networking(.timeout))
                default:
                    return .failure(.networking(.invalidResponse))
                }
            } else {
                return .failure(.networking(.invalidResponse))
            }
        }
    }
    
    private func optimizeImage(_ image: UIImage) -> UIImage {
        let maxSize: CGFloat = 1024
        let scale = min(maxSize / image.size.width, maxSize / image.size.height, 1.0)
        
        if scale < 1.0 {
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let optimizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
            return optimizedImage
        }
        
        return image
    }
    
    private func createImageMetadata(original: UIImage, optimized: UIImage, data: Data) -> FoodAnalysisRequest.ImageMetadata {
        let originalData = original.jpegData(compressionQuality: 1.0) ?? Data()
        
        return FoodAnalysisRequest.ImageMetadata(
            size: optimized.size,
            originalSize: originalData.count,
            compressedSize: data.count
        )
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

