import Foundation
import Security
import CryptoKit

// MARK: - ICAO 9303 Signature Validator
/// Validates government ID signatures using ECDSA P256 cryptography
/// per ICAO 9303 international standard for passports and national IDs
public class ICAO9303Validator {
    
    // MARK: - Public Interface
    
    /// Validate government ID signature
    /// - Parameters:
    ///   - data: Raw ID data that was signed
    ///   - signature: Government's ECDSA signature over the data
    ///   - countryCode: Two-letter ISO country code (e.g., "US", "GB")
    /// - Returns: True if signature is valid, false otherwise
    public func validate(
        data: Data,
        signature: Data,
        countryCode: String
    ) throws -> Bool {
        // Get the public key for this country
        guard let publicKey = try getGovernmentPublicKey(for: countryCode) else {
            throw ICAO9303Error.unknownCountry(countryCode)
        }
        
        // Parse P256 signature (raw format: 64 bytes = 32 bytes R + 32 bytes S)
        guard signature.count == 64 else {
            throw ICAO9303Error.invalidSignatureFormat("Expected 64 bytes, got \(signature.count)")
        }
        
        // Create P256 signature from raw components
        let signatureBytes = [UInt8](signature)
        let rData = Data(signatureBytes[0..<32])
        let sData = Data(signatureBytes[32..<64])
        
        // Construct ASN.1 DER-encoded ECDSA signature for verification
        // Format: SEQUENCE { INTEGER r, INTEGER s }
        let derSignature = constructDERSignature(r: rData, s: sData)
        
        // Verify using SecKey
        var verifyError: Unmanaged<CFError>?
        let isValid = SecKeyVerifySignature(
            publicKey,
            .ecdsaSignatureMessageSHA256,
            data,
            derSignature,
            &verifyError
        )
        
        if let error = verifyError?.takeRetainedValue() {
            throw ICAO9303Error.verificationFailed(error.localizedDescription)
        }
        
        return isValid
    }
    
    // MARK: - Government Public Key Management
    
    private var cachedPublicKeys: [String: SecKey] = [:]
    
    private func getGovernmentPublicKey(for countryCode: String) throws -> SecKey? {
        // Check cache first
        if let cached = cachedPublicKeys[countryCode] {
            return cached
        }
        
        // Load PEM file for country
        guard let pemData = loadGovernmentKeyPEM(for: countryCode) else {
            return nil
        }
        
        // Convert PEM to SecKey
        let key = try convertPEMToSecKey(pemData)
        
        // Cache for future use
        cachedPublicKeys[countryCode] = key
        
        return key
    }
    
    private func loadGovernmentKeyPEM(for countryCode: String) -> Data? {
        // Try to load from app bundle
        // Format: "CountryCode.pem" in "GovernmentKeys" directory
        guard let keyPath = Bundle.main.path(
            forResource: countryCode.lowercased(),
            ofType: "pem",
            inDirectory: "GovernmentKeys"
        ) else {
            return nil
        }
        
        return try? Data(contentsOf: URL(fileURLWithPath: keyPath))
    }
    
    private func convertPEMToSecKey(_ pemData: Data) throws -> SecKey {
        // Remove PEM headers/footers and decode base64
        guard let pemString = String(data: pemData, encoding: .utf8) else {
            throw ICAO9303Error.invalidPEMFormat("Cannot decode PEM as UTF-8")
        }
        
        let lines = pemString.components(separatedBy: .newlines)
        let keyLines = lines.filter { !$0.hasPrefix("-----") && !$0.isEmpty }
        let keyBase64 = keyLines.joined()
        
        guard let keyData = Data(base64Encoded: keyBase64) else {
            throw ICAO9303Error.invalidPEMFormat("Cannot decode base64 key data")
        }
        
        // Create SecKey from DER data
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 256,
        ]
        
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(
            keyData as CFData,
            attributes as CFDictionary,
            &error
        ) else {
            let errorMsg = error?.takeRetainedValue().localizedDescription ?? "Unknown"
            throw ICAO9303Error.keyCreationFailed(errorMsg)
        }
        
        return secKey
    }
    
    // MARK: - DER Signature Construction
    
    private func constructDERSignature(r: Data, s: Data) -> Data {
        // DER-encode SEQUENCE { INTEGER r, INTEGER s }
        // Each INTEGER: 0x02 <length> <bytes>
        
        let rEncoded = encodeInteger(r)
        let sEncoded = encodeInteger(s)
        let sequenceLength = rEncoded.count + sEncoded.count
        
        var result = Data()
        result.append(0x30) // SEQUENCE tag
        result.append(UInt8(sequenceLength))
        result.append(rEncoded)
        result.append(sEncoded)
        
        return result
    }
    
    private func encodeInteger(_ data: Data) -> Data {
        var result = Data()
        result.append(0x02) // INTEGER tag
        
        // Remove leading zeros but keep one if MSB is set (to indicate positive number)
        var bytes = [UInt8](data)
        while bytes.count > 1 && bytes[0] == 0 && bytes[1] & 0x80 == 0 {
            bytes.removeFirst()
        }
        
        result.append(UInt8(bytes.count))
        result.append(Data(bytes))
        
        return result
    }
}

// MARK: - Error Types
enum ICAO9303Error: LocalizedError {
    case unknownCountry(String)
    case invalidSignatureFormat(String)
    case verificationFailed(String)
    case invalidPEMFormat(String)
    case keyCreationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .unknownCountry(let code):
            return "Unsupported country code: \(code)"
        case .invalidSignatureFormat(let details):
            return "Invalid signature format: \(details)"
        case .verificationFailed(let details):
            return "Signature verification failed: \(details)"
        case .invalidPEMFormat(let details):
            return "Invalid PEM format: \(details)"
        case .keyCreationFailed(let details):
            return "Failed to create security key: \(details)"
        }
    }
}
