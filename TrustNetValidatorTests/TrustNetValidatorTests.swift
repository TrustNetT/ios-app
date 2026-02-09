import XCTest
import CryptoKit
@testable import TrustNetCore

@available(iOS 14, *)
final class TrustNetValidatorTests: XCTestCase {
    var validator: PassportValidator!
    
    override func setUp() {
        super.setUp()
        validator = PassportValidator()
    }
    
    override func tearDown() {
        validator = nil
        super.tearDown()
    }
    
    func testValidatorInitialization() throws {
        XCTAssertNotNil(validator, "PassportValidator should initialize successfully")
    }
    
    func testValidSignatureValidation() throws {
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        let testData = "Test passport document".data(using: .utf8)!
        let signature = try privateKey.signature(for: testData)
        
        let isValid = try validator.validateSignature(
            documentData: testData,
            signature: signature.rawRepresentation,
            publicKey: publicKey.rawRepresentation
        )
        
        XCTAssertTrue(isValid, "Valid signature should pass validation")
    }
    
    func testInvalidSignatureWithDifferentData() throws {
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        let testData = "Test passport document".data(using: .utf8)!
        let signature = try privateKey.signature(for: testData)
        
        let differentData = "Different data".data(using: .utf8)!
        let isValid = try validator.validateSignature(
            documentData: differentData,
            signature: signature.rawRepresentation,
            publicKey: publicKey.rawRepresentation
        )
        
        XCTAssertFalse(isValid, "Signature with different data should fail validation")
    }
    
    func testSignatureWithWrongKey() throws {
        let privateKey1 = P256.Signing.PrivateKey()
        let privateKey2 = P256.Signing.PrivateKey()
        let publicKey2 = privateKey2.publicKey
        let testData = "Test passport document".data(using: .utf8)!
        let signature = try privateKey1.signature(for: testData)
        
        let isValid = try validator.validateSignature(
            documentData: testData,
            signature: signature.rawRepresentation,
            publicKey: publicKey2.rawRepresentation
        )
        
        XCTAssertFalse(isValid, "Signature with wrong key should fail validation")
    }
}

@available(iOS 14, *)
final class TrustNetValidatorPerformanceTests: XCTestCase {
    var validator: PassportValidator!
    
    override func setUp() {
        super.setUp()
        validator = PassportValidator()
    }
    
    func testValidationPerformance() throws {
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        let testData = "Test passport document".data(using: .utf8)!
        let signature = try privateKey.signature(for: testData)
        
        self.measure {
            _ = try? validator.validateSignature(
                documentData: testData,
                signature: signature.rawRepresentation,
                publicKey: publicKey.rawRepresentation
            )
        }
    }
}
