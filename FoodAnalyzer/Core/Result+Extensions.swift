import Foundation

// MARK: - Enhanced Result Extensions
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
    
    func mapError<NewFailure>(_ transform: (Failure) -> NewFailure) -> Result<Success, NewFailure> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            return .failure(transform(error))
        }
    }
    
    func flatMapError<NewFailure>(_ transform: (Failure) -> Result<Success, NewFailure>) -> Result<Success, NewFailure> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            return transform(error)
        }
    }
}

// MARK: - App-Specific Error Types
enum AppError: Error, LocalizedError {
    case networking(NetworkError)
    case authentication(AuthError)
    case validation(ValidationError) // Uses ValidationError from Models.swift
    case storage(StorageError)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networking(let error):
            return error.localizedDescription
        case .authentication(let error):
            return error.localizedDescription
        case .validation(let error):
            return error.errorDescription
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
        case .networking(.serverError(let code)) where code >= 500:
            return "Server is experiencing issues. Please try again later."
        case .networking(.serverError(let code)) where code == 404:
            return "The requested resource was not found."
        case .authentication(.invalidCredentials):
            return "Invalid email or password. Please try again."
        case .authentication(.userExists):
            return "An account with this email already exists."
        case .authentication(.tokenExpired):
            return "Your session has expired. Please sign in again."
        case .validation(.invalidEmail):
            return "Please enter a valid email address."
        case .validation(.weakPassword):
            return "Password must be at least 8 characters with letters and numbers."
        case .validation(.emptyFields):
            return "Please fill in all required fields."
        case .storage(.encodingFailed), .storage(.decodingFailed):
            return "Data processing error. Please try again."
        case .storage(.keychainError):
            return "Secure storage error. Please try again."
        default:
            return errorDescription ?? "Something went wrong. Please try again."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networking(.noConnection), .networking(.timeout), .networking(.serverError):
            return true
        case .authentication(.tokenExpired):
            return true
        case .storage(.encodingFailed), .storage(.decodingFailed):
            return true
        default:
            return false
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .networking(.noConnection), .networking(.timeout):
            return .warning
        case .networking(.serverError(let code)) where code >= 500:
            return .error
        case .authentication(.tokenExpired):
            return .info
        case .authentication(.unauthorized):
            return .error
        case .validation:
            return .warning
        case .storage(.keychainError):
            return .error
        default:
            return .info
        }
    }
}

// MARK: - Equatable Conformance for AppError
extension AppError: Equatable {
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.networking(let lhsError), .networking(let rhsError)):
            return lhsError == rhsError
        case (.authentication(let lhsError), .authentication(let rhsError)):
            return lhsError == rhsError
        case (.validation(let lhsError), .validation(let rhsError)):
            return lhsError == rhsError
        case (.storage(let lhsError), .storage(let rhsError)):
            return lhsError == rhsError
        case (.unknown(let lhsMessage), .unknown(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - Network Error
enum NetworkError: Error, LocalizedError, Equatable {
    case noConnection
    case timeout
    case serverError(Int)
    case invalidResponse
    case decodingError
    case imageProcessingFailed
    case requestFailed
    case invalidURL
    
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
        case .requestFailed:
            return "Request failed"
        case .invalidURL:
            return "Invalid URL"
        }
    }
}

// MARK: - Authentication Error
enum AuthError: Error, LocalizedError, Equatable {
    case invalidCredentials
    case userExists
    case tokenExpired
    case unauthorized
    case registrationFailed
    case logoutFailed
    
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
        case .registrationFailed:
            return "Registration failed"
        case .logoutFailed:
            return "Logout failed"
        }
    }
}

// MARK: - Storage Error
enum StorageError: Error, LocalizedError, Equatable {
    case keyNotFound
    case encodingFailed
    case decodingFailed
    case keychainError
    case coreDataError
    case fileSystemError
    
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
        case .coreDataError:
            return "Core Data error"
        case .fileSystemError:
            return "File system error"
        }
    }
}

// MARK: - Error Severity
enum ErrorSeverity {
    case info       // Informational, user can continue
    case warning    // Warning, user should be aware
    case error      // Error, blocks user action
    case critical   // Critical, app may need to restart
    
    var color: String {
        switch self {
        case .info: return "blue"
        case .warning: return "orange"
        case .error: return "red"
        case .critical: return "purple"
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .critical: return "exclamationmark.octagon"
        }
    }
}

// MARK: - App Result Type Alias
typealias AppResult<T> = Result<T, AppError>

// MARK: - AppResult Factory Methods
struct AppResultFactory {
    static func success<T>(_ value: T) -> AppResult<T> {
        return .success(value)
    }
    
    static func failure<T>(_ error: AppError) -> AppResult<T> {
        return .failure(error)
    }
    
    static func networkingFailure<T>(_ error: NetworkError) -> AppResult<T> {
        return .failure(.networking(error))
    }
    
    static func authenticationFailure<T>(_ error: AuthError) -> AppResult<T> {
        return .failure(.authentication(error))
    }
    
    static func validationFailure<T>(_ error: ValidationError) -> AppResult<T> {
        return .failure(.validation(error))
    }
    
    static func storageFailure<T>(_ error: StorageError) -> AppResult<T> {
        return .failure(.storage(error))
    }
    
    static func unknownFailure<T>(_ message: String) -> AppResult<T> {
        return .failure(.unknown(message))
    }
}

// MARK: - Error Logging Extensions
extension AppError {
    func log(context: String = "") {
        let severity = self.severity
        let message = "\(severity) - \(context.isEmpty ? "" : "[\(context)] ")\(userFriendlyMessage)"
        
        #if DEBUG
        print("🚨 AppError: \(message)")
        if case .unknown(let details) = self {
            print("   Details: \(details)")
        }
        #endif
        
        // Here you could add analytics/crash reporting
        // Analytics.logError(self, context: context)
    }
}

// MARK: - HTTP Status Code Mapping
extension NetworkError {
    static func from(httpStatusCode: Int) -> NetworkError {
        switch httpStatusCode {
        case 200...299:
            return .invalidResponse // Shouldn't reach here for success codes
        case 400...499:
            return .serverError(httpStatusCode)
        case 500...599:
            return .serverError(httpStatusCode)
        default:
            return .serverError(httpStatusCode)
        }
    }
}

// MARK: - Validation Error to AppError Mapping
extension ValidationError {
    var asAppError: AppError {
        return .validation(self)
    }
}

extension AuthError {
    var asAppError: AppError {
        return .authentication(self)
    }
}

extension NetworkError {
    var asAppError: AppError {
        return .networking(self)
    }
}

extension StorageError {
    var asAppError: AppError {
        return .storage(self)
    }
}
