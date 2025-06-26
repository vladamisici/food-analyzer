import Foundation

// Enhanced Result type for better error handling
extension Result {
    var value: Success? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    var error: Failure? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
    
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    var isFailure: Bool {
        return !isSuccess
    }
}

// App-specific error types
enum AppError: Error, LocalizedError, Equatable {
    case networking(NetworkError)
    case authentication(AuthError)
    case validation(ValidationError)
    case storage(StorageError)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networking(let error):
            return error.localizedDescription
        case .authentication(let error):
            return error.localizedDescription
        case .validation(let error):
            return error.localizedDescription
        case .storage(let error):
            return error.localizedDescription
        case .unknown(let message):
            return message
        }
    }
    
    var userFriendlyMessage: String {
        switch self {
        case .networking(.noConnection):
            return "No internet connection. Please check your network and try again."
        case .networking(.timeout):
            return "Request timed out. Please try again."
        case .authentication(.invalidCredentials):
            return "Invalid email or password. Please try again."
        case .authentication(.userExists):
            return "An account with this email already exists."
        case .validation(.invalidEmail):
            return "Please enter a valid email address."
        case .validation(.weakPassword):
            return "Password must be at least 8 characters long."
        default:
            return errorDescription ?? "Something went wrong. Please try again."
        }
    }
}

enum NetworkError: Error, LocalizedError, Equatable {
    case noConnection
    case timeout
    case serverError(Int)
    case invalidResponse
    case decodingError
    case imageProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .serverError(let code):
            return "Server error (\(code))"
        case .invalidResponse:
            return "Invalid server response"
        case .decodingError:
            return "Failed to decode response"
        case .imageProcessingFailed:
            return "Failed to process image"
        }
    }
}

enum AuthError: Error, LocalizedError, Equatable {
    case invalidCredentials
    case userExists
    case tokenExpired
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials"
        case .userExists:
            return "User already exists"
        case .tokenExpired:
            return "Session expired"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

enum ValidationError: Error, LocalizedError, Equatable {
    case invalidEmail
    case weakPassword
    case emptyFields
    case invalidImageFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Invalid email format"
        case .weakPassword:
            return "Password too weak"
        case .emptyFields:
            return "Required fields are empty"
        case .invalidImageFormat:
            return "Invalid image format"
        }
    }
}

enum StorageError: Error, LocalizedError, Equatable {
    case keyNotFound
    case encodingFailed
    case decodingFailed
    case keychainError
    
    var errorDescription: String? {
        switch self {
        case .keyNotFound:
            return "Key not found"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        case .keychainError:
            return "Keychain access error"
        }
    }
}

typealias AppResult<T> = Result<T, AppError>