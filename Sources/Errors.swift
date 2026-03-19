import Foundation

// MARK: - Registration Error Types
/// Errors that can occur during the registration process
public enum RegistrationError: LocalizedError, Equatable {
    /// Device does not support NFC reading
    case nfcNotAvailable
    
    /// NFC reading failed (connection lost, timeout, etc.)
    case nfcReadingFailed(String)
    
    /// Government ID signature validation failed
    case invalidSignature(String)
    
    /// Government ID is expired or invalid
    case invalidGovernmentID(String)
    
    /// Government public key not found for country
    case unknownCountry(String)
    
    /// Biometric extraction or hashing failed
    case biometricProcessingFailed(String)
    
    /// Cryptographic key generation failed
    case keyGenerationFailed(String)
    
    /// Failed to store keys in Keychain
    case keychainStorageError(String)
    
    /// Failed to retrieve keys from Keychain
    case keychainRetrievalError(String)
    
    /// Blockchain connection failed
    case blockchainConnectionFailed(String)
    
    /// Blockchain registration submission failed
    case blockchainSubmissionFailed(String)
    
    /// Blockchain rejected the registration
    case blockchainRegistrationRejected(String)
    
    /// User cancelled the registration process
    case userCancelled
    
    /// Invalid app state for registration
    case invalidAppState(String)
    
    /// Generic unexpected error
    case unknown(String)
    
    // MARK: - LocalizedError Protocol
    
    public var errorDescription: String? {
        switch self {
        case .nfcNotAvailable:
            return "This device does not support NFC reading. iPhone XS or later is required."
            
        case .nfcReadingFailed(let details):
            return "Failed to read government ID: \(details)"
            
        case .invalidSignature(let details):
            return "Government ID signature is invalid: \(details)"
            
        case .invalidGovernmentID(let details):
            return "Government ID is invalid or expired: \(details)"
            
        case .unknownCountry(let countryCode):
            return "Government ID country '\(countryCode)' is not supported"
            
        case .biometricProcessingFailed(let details):
            return "Failed to process biometric data: \(details)"
            
        case .keyGenerationFailed(let details):
            return "Failed to generate identity keys: \(details)"
            
        case .keychainStorageError(let details):
            return "Failed to secure keys: \(details)"
            
        case .keychainRetrievalError(let details):
            return "Failed to retrieve stored keys: \(details)"
            
        case .blockchainConnectionFailed(let details):
            return "Failed to connect to blockchain: \(details)"
            
        case .blockchainSubmissionFailed(let details):
            return "Failed to submit registration: \(details)"
            
        case .blockchainRegistrationRejected(let details):
            return "Blockchain rejected registration: \(details)"
            
        case .userCancelled:
            return "Registration cancelled"
            
        case .invalidAppState(let details):
            return "Invalid app state: \(details)"
            
        case .unknown(let details):
            return "Unexpected error: \(details)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .nfcNotAvailable:
            return "Please use an iPhone XS or later to register with TrustNet."
            
        case .nfcReadingFailed:
            return "Try scanning again. Hold your ID near the top of your iPhone."
            
        case .invalidSignature, .invalidGovernmentID:
            return "Your ID may be damaged or counterfeit. Please use an official government ID."
            
        case .unknownCountry:
            return "Your country is not yet supported. Check back soon."
            
        case .biometricProcessingFailed:
            return "Make sure the ID photo is clear and visible."
            
        case .keyGenerationFailed:
            return "Restart the app and try again."
            
        case .keychainStorageError, .keychainRetrievalError:
            return "Check Settings > Privacy to ensure TrustNet has Keychain access."
            
        case .blockchainConnectionFailed:
            return "Check your internet connection and try again."
            
        case .blockchainSubmissionFailed, .blockchainRegistrationRejected:
            return "Please contact support if this problem persists."
            
        case .userCancelled:
            return "You can try registering again anytime."
            
        case .invalidAppState:
            return "Restart the app and try again."
            
        case .unknown:
            return "Please try again or contact support."
        }
    }
    
    // MARK: - Equatable Conformance
    
    public static func == (lhs: RegistrationError, rhs: RegistrationError) -> Bool {
        switch (lhs, rhs) {
        case (.nfcNotAvailable, .nfcNotAvailable):
            return true
        case (.nfcReadingFailed(let a), .nfcReadingFailed(let b)):
            return a == b
        case (.invalidSignature(let a), .invalidSignature(let b)):
            return a == b
        case (.invalidGovernmentID(let a), .invalidGovernmentID(let b)):
            return a == b
        case (.unknownCountry(let a), .unknownCountry(let b)):
            return a == b
        case (.biometricProcessingFailed(let a), .biometricProcessingFailed(let b)):
            return a == b
        case (.keyGenerationFailed(let a), .keyGenerationFailed(let b)):
            return a == b
        case (.keychainStorageError(let a), .keychainStorageError(let b)):
            return a == b
        case (.keychainRetrievalError(let a), .keychainRetrievalError(let b)):
            return a == b
        case (.blockchainConnectionFailed(let a), .blockchainConnectionFailed(let b)):
            return a == b
        case (.blockchainSubmissionFailed(let a), .blockchainSubmissionFailed(let b)):
            return a == b
        case (.blockchainRegistrationRejected(let a), .blockchainRegistrationRejected(let b)):
            return a == b
        case (.userCancelled, .userCancelled):
            return true
        case (.invalidAppState(let a), .invalidAppState(let b)):
            return a == b
        case (.unknown(let a), .unknown(let b)):
            return a == b
        default:
            return false
        }
    }
}
