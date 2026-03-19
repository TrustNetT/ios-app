import Foundation

// MARK: - Government ID Data (from NFC)
/// Represents data extracted from government ID via NFC
public struct GovernmentID: Codable, Equatable {
    /// Full name as on ID
    public let fullName: String
    
    /// Date of birth from ID
    public let dateOfBirth: Date
    
    /// Government document number (passport/national ID)
    public let documentNumber: String
    
    /// Country code (US, GB, DE, etc.)
    public let countryCode: String
    
    /// Raw biometric template from ID (facial data)
    public let biometricTemplate: Data
    
    /// Government's digital signature over the ID data
    public let governmentSignature: Data
    
    /// Whether signature has been validated
    public let isValid: Bool
    
    /// Raw ID photo (optional, for biometric hashing)
    public let idPhoto: Data?
    
    public init(
        fullName: String,
        dateOfBirth: Date,
        documentNumber: String,
        countryCode: String,
        biometricTemplate: Data,
        governmentSignature: Data,
        isValid: Bool,
        idPhoto: Data? = nil
    ) {
        self.fullName = fullName
        self.dateOfBirth = dateOfBirth
        self.documentNumber = documentNumber
        self.countryCode = countryCode
        self.biometricTemplate = biometricTemplate
        self.governmentSignature = governmentSignature
        self.isValid = isValid
        self.idPhoto = idPhoto
    }
}

// MARK: - Biometric Hash (Privacy-preserving)
/// SHA-256 hash of facial geometry (never stores raw biometric data)
public struct BiometricHash: Codable, Equatable, Hashable {
    /// SHA-256 hash of facial geometry extracted from ID photo
    public let hash: String
    
    /// Timestamp when hash was computed
    public let timestamp: Date
    
    public init(hash: String, timestamp: Date = Date()) {
        self.hash = hash
        self.timestamp = timestamp
    }
}

// MARK: - User Identity
/// Complete user identity after registration
public struct User: Codable, Equatable {
    /// Unique user identifier (derived from biometric hash + public key + timestamp)
    public let userID: String
    
    /// Government ID data used for registration
    public let governmentID: GovernmentID
    
    /// Privacy-preserving biometric hash
    public let biometricHash: BiometricHash
    
    /// P256 public key (public, can be shared)
    public let publicKey: Data
    
    /// Registration timestamp
    public let registrationTimestamp: Date
    
    /// Whether user is registered on blockchain
    public let isBlockchainRegistered: Bool
    
    /// Blockchain transaction hash (if registered)
    public let blockchainTransactionHash: String?
    
    public init(
        userID: String,
        governmentID: GovernmentID,
        biometricHash: BiometricHash,
        publicKey: Data,
        registrationTimestamp: Date = Date(),
        isBlockchainRegistered: Bool = false,
        blockchainTransactionHash: String? = nil
    ) {
        self.userID = userID
        self.governmentID = governmentID
        self.biometricHash = biometricHash
        self.publicKey = publicKey
        self.registrationTimestamp = registrationTimestamp
        self.isBlockchainRegistered = isBlockchainRegistered
        self.blockchainTransactionHash = blockchainTransactionHash
    }
}

// MARK: - Identity Verification (Immutable state)
/// Immutable verification state at each registration step
public struct IdentityVerification: Codable, Equatable {
    /// Government ID successfully scanned and signature validated
    public let governmentIDVerified: Bool
    
    /// Timestamp of government ID verification
    public let governmentIDVerifiedAt: Date?
    
    /// Biometric hash successfully generated
    public let biometricVerified: Bool
    
    /// Timestamp of biometric verification
    public let biometricVerifiedAt: Date?
    
    /// Cryptographic keys successfully generated
    public let keysGenerated: Bool
    
    /// Timestamp of key generation
    public let keysGeneratedAt: Date?
    
    /// User successfully registered on blockchain
    public let blockchainRegistered: Bool
    
    /// Timestamp of blockchain registration
    public let blockchainRegisteredAt: Date?
    
    public init(
        governmentIDVerified: Bool = false,
        governmentIDVerifiedAt: Date? = nil,
        biometricVerified: Bool = false,
        biometricVerifiedAt: Date? = nil,
        keysGenerated: Bool = false,
        keysGeneratedAt: Date? = nil,
        blockchainRegistered: Bool = false,
        blockchainRegisteredAt: Date? = nil
    ) {
        self.governmentIDVerified = governmentIDVerified
        self.governmentIDVerifiedAt = governmentIDVerifiedAt
        self.biometricVerified = biometricVerified
        self.biometricVerifiedAt = biometricVerifiedAt
        self.keysGenerated = keysGenerated
        self.keysGeneratedAt = keysGeneratedAt
        self.blockchainRegistered = blockchainRegistered
        self.blockchainRegisteredAt = blockchainRegisteredAt
    }
}

// MARK: - Registration State Machine
/// Registration flow state (tracks where user is in process)
public enum RegistrationState: Equatable {
    /// App idle, waiting for user to start registration
    case idle
    
    /// Waiting for user to scan government ID with NFC
    case readyToScan
    
    /// Currently scanning NFC tag
    case scanning
    
    /// Validating scanned government ID signature
    case validatingID
    
    /// Generating biometric hash from ID photo
    case hashingBiometric
    
    /// Generating P256 cryptographic keypair
    case generatingKeys
    
    /// Storing keys in Keychain
    case storingKeys
    
    /// Submitting registration to blockchain
    case registeringOnBlockchain
    
    /// Registration complete and successful
    case complete(User)
    
    /// Error occurred during registration
    case error(RegistrationError)
    
    /// Human-readable state description
    public var description: String {
        switch self {
        case .idle:
            return "Ready to start registration"
        case .readyToScan:
            return "Ready to scan government ID"
        case .scanning:
            return "Scanning government ID..."
        case .validatingID:
            return "Validating government ID signature..."
        case .hashingBiometric:
            return "Processing biometric data..."
        case .generatingKeys:
            return "Generating identity keys..."
        case .storingKeys:
            return "Securing keys..."
        case .registeringOnBlockchain:
            return "Registering on blockchain..."
        case .complete:
            return "Registration complete!"
        case .error(let error):
            return "Registration error: \(error.localizedDescription)"
        }
    }
}
