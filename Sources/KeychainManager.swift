import Foundation
import Security

/// Securely stores and retrieves P256 private keys in iOS Keychain
/// Prevents raw key extraction and enables biometric-protected access
public class KeychainManager {
    
    /// Keychain service identifier (bundled with app)
    private let keychainService = "com.trustnet.ios-app"
    
    /// Store private key in Keychain with optional biometric protection
    /// - Parameters:
    ///   - privateKey: The P256 private key to store
    ///   - userID: The UserID associated with this key
    ///   - requireBiometric: If true, require Face ID/Touch ID to access (optional)
    /// - Throws: KeychainError if storage fails
    public func storePrivateKey(
        _ privateKey: Data,
        for userID: String,
        requireBiometric: Bool = false
    ) throws {
        
        // Validate inputs
        guard !privateKey.isEmpty else {
            throw KeychainError.invalidKeyData
        }
        guard !userID.isEmpty else {
            throw KeychainError.invalidUserID
        }
        
        // Create query for Keychain
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userID,
            kSecValueData as String: privateKey,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            // Prevent interprocess access (stay in process)
            kSecAttrAccessGroup as String: Bundle.main.bundleIdentifier ?? keychainService
        ]
        
        // Add biometric protection if requested
        if requireBiometric {
            var accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet,
                nil
            )
            query[kSecAttrAccessControl as String] = accessControl
        }
        
        // Delete any existing key for this user first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userID
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new key to Keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.storageFailure(statusCode: status)
        }
    }
    
    /// Retrieve private key from Keychain
    /// - Parameter userID: The UserID to retrieve key for
    /// - Returns: The raw private key data (32 bytes for P256)
    /// - Throws: KeychainError if retrieval fails (not found, access denied, etc.)
    public func retrievePrivateKey(for userID: String) throws -> Data {
        
        guard !userID.isEmpty else {
            throw KeychainError.invalidUserID
        }
        
        // Create query to retrieve
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userID,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        // Handle specific error cases
        if status == errSecItemNotFound {
            throw KeychainError.keyNotFound
        } else if status == errSecUserCanceled {
            throw KeychainError.userCancelledBiometric
        } else if status == errSecAuthFailed {
            throw KeychainError.biometricAuthFailed
        } else if status != errSecSuccess {
            throw KeychainError.retrievalFailure(statusCode: status)
        }
        
        // Extract and validate data
        guard let keyData = result as? Data, !keyData.isEmpty else {
            throw KeychainError.corruptedKeyData
        }
        
        // P256 private keys are exactly 32 bytes
        guard keyData.count == 32 else {
            throw KeychainError.invalidKeySize
        }
        
        return keyData
    }
    
    /// Delete private key from Keychain (logout/deactivate account)
    /// - Parameter userID: The UserID to delete
    /// - Throws: KeychainError if deletion fails
    public func deletePrivateKey(for userID: String) throws {
        
        guard !userID.isEmpty else {
            throw KeychainError.invalidUserID
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userID
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // errSecItemNotFound is not an error for delete (key already gone)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deletionFailure(statusCode: status)
        }
    }
    
    /// Check if private key exists in Keychain
    /// - Parameter userID: The UserID to check
    /// - Returns: true if key exists, false otherwise
    public func keyExists(for userID: String) -> Bool {
        guard !userID.isEmpty else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userID,
            kSecReturnData as String: false
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Get all stored UserIDs (list of registered accounts)
    /// - Returns: Array of UserID strings currently stored in Keychain
    /// - Throws: KeychainError if retrieval fails
    public func getAllUserIDs() throws -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return [] // No keys stored yet
        } else if status != errSecSuccess {
            throw KeychainError.retrievalFailure(statusCode: status)
        }
        
        guard let items = result as? [[String: Any]] else {
            throw KeychainError.corruptedKeyData
        }
        
        let userIDs = items.compactMap { $0[kSecAttrAccount as String] as? String }
        return userIDs
    }
    
    // MARK: - Keychain Attribute Management
    
    /// Update biometric protection status for a key (re-protect or remove)
    /// - Parameters:
    ///   - userID: The UserID to update
    ///   - requireBiometric: If true, require biometric for access
    /// - Throws: KeychainError if update fails
    public func updateBiometricRequirement(
        for userID: String,
        requireBiometric: Bool
    ) throws {
        
        // Retrieve current key
        let privateKey = try retrievePrivateKey(for: userID)
        
        // Delete old entry
        try deletePrivateKey(for: userID)
        
        // Re-store with new biometric requirement
        try storePrivateKey(privateKey, for: userID, requireBiometric: requireBiometric)
    }
    
    /// Get creation date of stored key
    /// - Parameter userID: The UserID to check
    /// - Returns: Date key was created, or nil if key not found
    /// - Throws: KeychainError if retrieval fails
    public func keyCreationDate(for userID: String) throws -> Date? {
        guard !userID.isEmpty else {
            throw KeychainError.invalidUserID
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userID,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        } else if status != errSecSuccess {
            throw KeychainError.retrievalFailure(statusCode: status)
        }
        
        guard let attributes = result as? [String: Any] else {
            throw KeychainError.corruptedKeyData
        }
        
        // kSecAttrCreationDate is available in attributes
        let creationDate = attributes[kSecAttrCreationDate as String] as? Date
        return creationDate
    }
}

// MARK: - Error Types

public enum KeychainError: LocalizedError {
    case invalidKeyData
    case invalidUserID
    case keyNotFound
    case corruptedKeyData
    case invalidKeySize
    case userCancelledBiometric
    case biometricAuthFailed
    case storageFailure(statusCode: OSStatus)
    case retrievalFailure(statusCode: OSStatus)
    case deletionFailure(statusCode: OSStatus)
    case biometricNotAvailable
    case accessDenied
    
    public var errorDescription: String? {
        switch self {
        case .invalidKeyData:
            return "Invalid or empty key data"
        case .invalidUserID:
            return "Invalid or empty UserID"
        case .keyNotFound:
            return "Private key not found in Keychain"
        case .corruptedKeyData:
            return "Keychain data is corrupted"
        case .invalidKeySize:
            return "Key size does not match P256 specification (32 bytes)"
        case .userCancelledBiometric:
            return "User cancelled biometric authentication"
        case .biometricAuthFailed:
            return "Biometric authentication failed"
        case .storageFailure(let status):
            return "Failed to store key in Keychain (code: \(status))"
        case .retrievalFailure(let status):
            return "Failed to retrieve key from Keychain (code: \(status))"
        case .deletionFailure(let status):
            return "Failed to delete key from Keychain (code: \(status))"
        case .biometricNotAvailable:
            return "Biometric authentication not available on this device"
        case .accessDenied:
            return "Keychain access denied"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidKeyData:
            return "Ensure private key data is valid and non-empty."
        case .invalidUserID:
            return "Verify UserID is valid and non-empty."
        case .keyNotFound:
            return "Key was not found. Re-register or check UserID."
        case .corruptedKeyData:
            return "Keychain data is corrupted. Try deleting and re-registering."
        case .invalidKeySize:
            return "This is an internal error. Contact support."
        case .userCancelledBiometric:
            return "Try again and complete biometric authentication."
        case .biometricAuthFailed:
            return "Biometric did not match. Try again."
        case .storageFailure:
            return "Device may be locked. Unlock and try again."
        case .retrievalFailure:
            return "Device may be locked or storage corrupted. Try unlocking device."
        case .deletionFailure:
            return "Device state issue. Try again or force-restart device."
        case .biometricNotAvailable:
            return "This device does not support biometric authentication."
        case .accessDenied:
            return "You do not have permission to access this key. Check app permissions."
        }
    }
}
