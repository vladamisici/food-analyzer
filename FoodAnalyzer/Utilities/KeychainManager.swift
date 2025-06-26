import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    private let service = "com.foodanalyzer.keychain"
    
    // MARK: - Save Data
    func save<T: Codable>(_ item: T, forKey key: String) -> AppResult<Void> {
        do {
            let data = try JSONEncoder().encode(item)
            return saveData(data, forKey: key)
        } catch {
            return .failure(.storage(.encodingFailed))
        }
    }
    
    func saveString(_ string: String, forKey key: String) -> AppResult<Void> {
        guard let data = string.data(using: .utf8) else {
            return .failure(.storage(.encodingFailed))
        }
        return saveData(data, forKey: key)
    }
    
    private func saveData(_ data: Data, forKey key: String) -> AppResult<Void> {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData: data
        ] as CFDictionary
        
        // Delete existing item first
        SecItemDelete(query)
        
        let status = SecItemAdd(query, nil)
        
        if status == errSecSuccess {
            return .success(())
        } else {
            return .failure(.storage(.keychainError))
        }
    }
    
    // MARK: - Load Data
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> AppResult<T> {
        switch loadData(forKey: key) {
        case .success(let data):
            do {
                let item = try JSONDecoder().decode(type, from: data)
                return .success(item)
            } catch {
                return .failure(.storage(.decodingFailed))
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func loadString(forKey key: String) -> AppResult<String> {
        switch loadData(forKey: key) {
        case .success(let data):
            if let string = String(data: data, encoding: .utf8) {
                return .success(string)
            } else {
                return .failure(.storage(.decodingFailed))
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    private func loadData(forKey key: String) -> AppResult<Data> {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        
        if status == errSecSuccess {
            if let data = result as? Data {
                return .success(data)
            } else {
                return .failure(.storage(.decodingFailed))
            }
        } else if status == errSecItemNotFound {
            return .failure(.storage(.keyNotFound))
        } else {
            return .failure(.storage(.keychainError))
        }
    }
    
    // MARK: - Delete Data
    func delete(forKey key: String) -> AppResult<Void> {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ] as CFDictionary
        
        let status = SecItemDelete(query)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            return .success(())
        } else {
            return .failure(.storage(.keychainError))
        }
    }
    
    // MARK: - Check if Key Exists
    func exists(forKey key: String) -> Bool {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: false,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        
        let status = SecItemCopyMatching(query, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Clear All Data
    func clearAll() -> AppResult<Void> {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service
        ] as CFDictionary
        
        let status = SecItemDelete(query)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            return .success(())
        } else {
            return .failure(.storage(.keychainError))
        }
    }
}

// MARK: - Keychain Keys
extension KeychainManager {
    enum Keys {
        static let authToken = "auth_token"
        static let refreshToken = "refresh_token"
        static let currentUser = "current_user"
        static let biometricEnabled = "biometric_enabled"
        static let deviceID = "device_id"
    }
}