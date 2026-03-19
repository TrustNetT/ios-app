import Foundation
import CryptoKit
import Security

/// Generates P256 ECDSA keypairs and creates immutable UserID for blockchain registration
public class KeyGenerator {
    
    /// Generate new P256 keypair and create UserID
    /// - Parameters:
    ///   - governmentID: The government ID to derive UserID from
    ///   - biometricHash: The biometric hash for identity verification
    /// - Returns: Tuple of (PrivateKey, PublicKey, UserID)
    /// - Throws: KeyGeneratorError if keypair generation fails
    public func generateKeypair(
        for governmentID: GovernmentID,
        with biometricHash: BiometricHash
    ) throws -> (privateKey: P256.Signing.PrivateKey, publicKey: P256.Signing.PublicKey, userID: String) {
        
        // Generate new P256 keypair
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        
        // Create deterministic UserID from government ID hash + biometric hash
        let userID = try generateUserID(
            from: governmentID,
            biometricHash: biometricHash,
            publicKeyHash: try hashPublicKey(publicKey)
        )
        
        return (privateKey, publicKey, userID)
    }
    
    /// Extract private key as PEM-encoded format for storage
    /// - Parameter privateKey: The P256 private key
    /// - Returns: PEM-encoded private key string
    /// - Throws: KeyGeneratorError if encoding fails
    public func privateKeyToPEM(_ privateKey: P256.Signing.PrivateKey) throws -> String {
        let rawPrivateKey = privateKey.rawRepresentation
        
        // Create PKCS#8 DER structure for private key
        // DER format: SEQUENCE { INTEGER(version=0), SEQUENCE { OID(P-256), NULL }, OCTET STRING(private key) }
        let derData = try constructPKCS8DER(rawPrivateKey: rawPrivateKey)
        
        // Base64 encode and wrap with PEM headers
        let base64 = derData.base64EncodedString()
        let pemLines = stride(from: 0, to: base64.count, by: 64)
            .map { String(base64[$0..<min($0 + 64, base64.count)]) }
        
        let pem = """
        -----BEGIN PRIVATE KEY-----
        \(pemLines.joined(separator: "\n"))
        -----END PRIVATE KEY-----
        """
        
        return pem
    }
    
    /// Extract public key as PEM-encoded format
    /// - Parameter publicKey: The P256 public key
    /// - Returns: PEM-encoded public key string
    /// - Throws: KeyGeneratorError if encoding fails
    public func publicKeyToPEM(_ publicKey: P256.Signing.PublicKey) throws -> String {
        let rawPublicKey = publicKey.rawRepresentation
        
        // Create PKCS#1 DER structure for public key
        // Format: BIT STRING containing the raw public key (uncompressed point)
        let derData = try constructPublicKeyDER(rawPublicKey: rawPublicKey)
        
        // Base64 encode and wrap with PEM headers
        let base64 = derData.base64EncodedString()
        let pemLines = stride(from: 0, to: base64.count, by: 64)
            .map { String(base64[$0..<min($0 + 64, base64.count)]) }
        
        let pem = """
        -----BEGIN PUBLIC KEY-----
        \(pemLines.joined(separator: "\n"))
        -----END PUBLIC KEY-----
        """
        
        return pem
    }
    
    // MARK: - Private Helpers
    
    /// Generate deterministic UserID from government ID and biometric hash
    private func generateUserID(
        from governmentID: GovernmentID,
        biometricHash: BiometricHash,
        publicKeyHash: String
    ) throws -> String {
        // Combine government ID document number + biometric hash + public key hash
        // This ensures UserID is deterministic but depends on all three identity components
        let combined = "\(governmentID.documentNumber)|\(biometricHash.hash)|\(publicKeyHash)"
        
        let data = Data(combined.utf8)
        let digest = SHA256.hash(data: data)
        let hexHash = digest.map { String(format: "%02x", $0) }.joined()
        
        // Format: "TN_" prefix + first 20 chars of hash (80-bit security)
        // This is unique identifier for blockchain registration
        return "TN_\(hexHash.prefix(20))"
    }
    
    /// Generate SHA-256 hash of public key for UserID derivation
    private func hashPublicKey(_ publicKey: P256.Signing.PublicKey) throws -> String {
        let rawData = publicKey.rawRepresentation
        let digest = SHA256.hash(data: rawData)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Construct PKCS#8 DER-encoded private key
    /// Structure: SEQUENCE {
    ///   version INTEGER (0)
    ///   privateKeyAlgorithm SEQUENCE { algorithm OID, parameters NULL }
    ///   privateKey OCTET STRING (32 bytes for P-256)
    /// }
    private func constructPKCS8DER(rawPrivateKey: Data) throws -> Data {
        var result = Data()
        
        // P-256 algorithm OID: 1.2.840.10045.2.1 (ecPublicKey)
        let ecPublicKeyOID = Data([0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01])
        // P-256 curve OID: 1.2.840.10045.3.1.7
        let p256CurveOID = Data([0x06, 0x05, 0x2b, 0x81, 0x04, 0x00, 0x20])
        // NULL
        let null = Data([0x05, 0x00])
        
        // OCTET STRING wrapping the private key value
        let octetString = encodeOctetString(rawPrivateKey)
        
        // Algorithm identifier SEQUENCE
        let algorithmID = encodeSequence(ecPublicKeyOID + p256CurveOID)
        
        // VERSION INTEGER 0
        let version = Data([0x02, 0x01, 0x00])
        
        // Combine all parts
        let pkcs8Content = version + algorithmID + octetString
        
        // Wrap in outer SEQUENCE
        return encodeSequence(pkcs8Content)
    }
    
    /// Construct public key DER encoding
    /// Subject Public Key Info format: SEQUENCE {
    ///   algorithm SEQUENCE { algorithm OID, parameters OID }
    ///   subjectPublicKey BIT STRING
    /// }
    private func constructPublicKeyDER(rawPublicKey: Data) throws -> Data {
        // P-256 algorithm OID: 1.2.840.10045.2.1
        let ecPublicKeyOID = Data([0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01])
        // P-256 curve OID: 1.2.840.10045.3.1.7
        let p256CurveOID = Data([0x06, 0x05, 0x2b, 0x81, 0x04, 0x00, 0x20])
        
        // Algorithm identifier
        let algorithmID = encodeSequence(ecPublicKeyOID + p256CurveOID)
        
        // BIT STRING containing public key (add leading 0x00 byte for bit string unused bits)
        let bitString = encodeBitString(rawPublicKey)
        
        // Combine and wrap in SEQUENCE
        return encodeSequence(algorithmID + bitString)
    }
    
    /// Encode ASN.1 SEQUENCE tag with length and content
    private func encodeSequence(_ content: Data) -> Data {
        var result = Data()
        result.append(0x30) // SEQUENCE tag
        result.append(contentsOf: encodeLength(content.count))
        result.append(content)
        return result
    }
    
    /// Encode ASN.1 OCTET STRING tag with length and content
    private func encodeOctetString(_ content: Data) -> Data {
        var result = Data()
        result.append(0x04) // OCTET STRING tag
        result.append(contentsOf: encodeLength(content.count))
        result.append(content)
        return result
    }
    
    /// Encode ASN.1 BIT STRING with unused bits indicator
    private func encodeBitString(_ content: Data) -> Data {
        var result = Data()
        result.append(0x03) // BIT STRING tag
        // Length includes the unused bits byte (0x00) + content
        result.append(contentsOf: encodeLength(content.count + 1))
        result.append(0x00) // No unused bits
        result.append(content)
        return result
    }
    
    /// Encode ASN.1 length field (short form for lengths < 128)
    private func encodeLength(_ length: Int) -> Data {
        if length < 128 {
            return Data([UInt8(length)])
        } else {
            // Long form: 0x80 | byteCount, followed by bytes in big-endian
            var lengthData = Data()
            var remaining = length
            while remaining > 0 {
                lengthData.insert(UInt8(remaining & 0xFF), at: 0)
                remaining >>= 8
            }
            var result = Data()
            result.append(0x80 | UInt8(lengthData.count))
            result.append(lengthData)
            return result
        }
    }
}

// MARK: - Error Types

public enum KeyGeneratorError: LocalizedError {
    case keypairGenerationFailed
    case invalidGovernmentID
    case userIDGenerationFailed
    case pemEncodingFailed
    case derConstructionFailed
    
    public var errorDescription: String? {
        switch self {
        case .keypairGenerationFailed:
            return "Failed to generate P256 keypair"
        case .invalidGovernmentID:
            return "Invalid government ID for key generation"
        case .userIDGenerationFailed:
            return "Failed to generate UserID"
        case .pemEncodingFailed:
            return "Failed to encode key as PEM format"
        case .derConstructionFailed:
            return "Failed to construct DER encoding for key"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .keypairGenerationFailed:
            return "Ensure device has sufficient entropy. Try again."
        case .invalidGovernmentID:
            return "Verify government ID has valid document number and country code."
        case .userIDGenerationFailed:
            return "Ensure biometric hash is valid. Try again."
        case .pemEncodingFailed, .derConstructionFailed:
            return "This is an internal error. Contact support."
        }
    }
}
