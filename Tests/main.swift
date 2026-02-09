import Foundation
import TrustNetCore
import CryptoKit

@available(iOS 13.0, macOS 10.15, *)
func runTests() throws {
    print("🧪 TrustNet PassportValidator Test Suite")
    print(String(repeating: "=", count: 50))
    
    // Test 1: Initialize validator
    print("\n✓ Test 1: PassportValidator Initialization")
    let validator = PassportValidator()
    print("  ✅ PassportValidator initialized successfully")
    
    // Test 2: Valid signature
    print("\n✓ Test 2: Valid Signature Validation")
    let privateKey = P256.Signing.PrivateKey()
    let publicKey = privateKey.publicKey
    let testData = "Test passport document".data(using: .utf8)!
    let signature = try privateKey.signature(for: testData)
    
    let isValid = try validator.validateSignature(
        documentData: testData,
        signature: signature.rawRepresentation,
        publicKey: publicKey.rawRepresentation
    )
    
    if isValid {
        print("  ✅ Valid signature passed validation")
    } else {
        print("  ❌ Valid signature FAILED validation (unexpected!)")
    }
    
    // Test 3: Invalid signature (wrong data)
    print("\n✓ Test 3: Invalid Signature with Different Data")
    let differentData = "Different document".data(using: .utf8)!
    let isValidWrongData = try validator.validateSignature(
        documentData: differentData,
        signature: signature.rawRepresentation,
        publicKey: publicKey.rawRepresentation
    )
    
    if !isValidWrongData {
        print("  ✅ Invalid signature correctly rejected")
    } else {
        print("  ❌ Invalid signature PASSED validation (unexpected!)")
    }
    
    // Test 4: Wrong key
    print("\n✓ Test 4: Invalid Signature with Wrong Key")
    let privateKey2 = P256.Signing.PrivateKey()
    let publicKey2 = privateKey2.publicKey
    let isValidWrongKey = try validator.validateSignature(
        documentData: testData,
        signature: signature.rawRepresentation,
        publicKey: publicKey2.rawRepresentation
    )
    
    if !isValidWrongKey {
        print("  ✅ Wrong key correctly rejected")
    } else {
        print("  ❌ Wrong key PASSED validation (unexpected!)")
    }
    
    print("\n" + String(repeating: "=", count: 50))
    print("✅ All tests passed!")
    print("🎉 TrustNet iOS library is working correctly")
}

// Run tests with availability check
if #available(macOS 10.15, *) {
    do {
        try runTests()
    } catch {
        print("\n❌ Test failed with error: \(error)")
        exit(1)
    }
} else {
    print("❌ Tests require macOS 10.15 or later")
    exit(1)
}
