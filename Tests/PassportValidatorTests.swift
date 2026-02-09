import XCTest
@testable import TrustNetCore
import CryptoKit

@available(iOS 13.0, macOS 10.15, *)
final class PassportValidatorTests: XCTestCase {
    
    func testPassportValidatorInitialization() {
        let validator = PassportValidator()
        XCTAssertNotNil(validator, "PassportValidator should initialize successfully")
    }
    
    func testSignatureValidationWithValidSignature() throws {
        let validator = PassportValidator()
        
        // Generate a test P256 key pair
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        
        // Create test data to sign
        let testData = "Test passport document".data(using: .utf8)!
        
        // Sign the data
        let signature = try privateKey.signature(for: testData)
        
        // Extract raw representations for the validator
        let publicKeyData = publicKey.rawRepresentation
        let signatureData = signature.rawRepresentation
        
        // Test validation
        let isValid = try validator.validateSignature(
            documentData: testData,
            signature: signatureData,
            publicKey: publicKeyData
        )
        
        XCTAssertTrue(isValid, "Valid signature should pass validation")
    }
    
    func testSignatureValidationWithInvalidSignature() throws {
        let validator = PassportValidator()
        
        // Generate a test P256 key pair
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        
        // Create test data
        let testData = "Test passport document".data(using: .utf8)!
        let differentData = "Different document".data(using: .utf8)!
        
        // Sign the original data
        let signature = try privateKey.signature(for: testData)
        
        // Extract raw representations
        let publicKeyData = publicKey.rawRepresentation
        let signatureData = signature.rawRepresentation
        
        // Try to validate with different data (should fail)
        let isValid = try validator.validateSignature(
            documentData: differentData,
            signature: signatureData,
            publicKey: publicKeyData
        )
        
        XCTAssertFalse(isValid, "Invalid signature should fail validation")
    }
    
    func testSignatureValidationWithWrongKey() throws {
        let validator = PassportValidator()
        
        // Generate two different key pairs
        let privateKey1 = P256.Signing.PrivateKey()
        let privateKey2 = P256.Signing.PrivateKey()
        let publicKey2 = privateKey2.publicKey
        
        // Create test data and sign with key 1
        let testData = "Test passport document".data(using: .utf8)!
        let signature = try privateKey1.signature(for: testData)
        
        // Extract raw representations (using key2's public key, key1's signature)
        let publicKeyData = publicKey2.rawRepresentation  // Different key
        let signatureData = signature.rawRepresentation
        
        // Try to validate with wrong key (should fail)
        let isValid = try validator.validateSignature(
            documentData: testData,
            signature: signatureData,
            publicKey: publicKeyData
        )
        
        XCTAssertFalse(isValid, "Signature from different key should fail validation")
    }
}
