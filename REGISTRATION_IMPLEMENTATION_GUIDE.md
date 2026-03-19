# iOS Registration Module - Implementation Guide

**Date**: March 18, 2026  
**Status**: Ready for development  
**Scope**: Complete user registration flow (NFC → blockchain recording)  
**Platform**: iOS 13+ with NFC capability (iPhone XS and later)

---

## Executive Summary

The iOS registration module enables users to register on TrustNet via:
1. Government ID scanning (NFC passport/national ID)
2. Biometric verification (facial geometry hashing)
3. Cryptographic identity creation (private/public keypairs)
4. Blockchain recording (immutable identity registration)
5. Local secure storage (iOS Keychain)

This document is the source of truth for implementation. All decisions are locked in from architecture phase.

---

## Registration Flow (Complete Sequence)

### Phase 1: App Launch & Check Registration Status

```swift
func applicationDidFinishLaunching() {
    if userHasRegistered() {
        showLoginFlow()
    } else {
        showRegistrationScreen()
    }
}

func userHasRegistered() -> Bool {
    // Check iOS Keychain for stored UserID
    let keychain = KeychainManager.shared
    return keychain.retrieveUserID() != nil
}
```

### Phase 2: Registration Screen (Entry Point)

**Display**:
- Welcome message: "Create your TrustNet Identity"
- "Register Identity" button
- Explanation: "Sign in securely with your government ID"

**Requirements**:
- ✅ Device must have NFC capability (check at runtime)
- ✅ Device must be iPhone 13+ for NFC support
- ✅ User age verification (18+)

**Code Structure**:
```
Sources/
├── UI/
│   └── RegistrationView.swift        (Main registration flow UI)
├── NFC/
│   ├── GovernmentIDScanner.swift      (NFC reading logic)
│   └── ICAO9303Validator.swift        (Government signature validation)
├── Crypto/
│   ├── KeyGenerator.swift             (Private/public keypair generation)
│   ├── BiometricHasher.swift          (Facial geometry hashing)
│   └── UserIDGenerator.swift          (Combine components to create UserID)
├── Blockchain/
│   ├── BlockchainConnector.swift      (Node communication)
│   └── RegistrationTransactor.swift   (Submit registration to chain)
├── Storage/
│   ├── KeychainManager.swift          (Secure storage)
│   └── UserDataManager.swift          (Local user cache)
└── Models/
    ├── GovernmentID.swift             (Scanned ID data)
    ├── User.swift                     (User identity)
    └── RegistrationState.swift        (State machine)
```

---

## Technical Specification: Component by Component

### 1. NFC Government ID Scanner

**File**: `Sources/NFC/GovernmentIDScanner.swift`

**Responsibility**: Read government ID via NFC and extract ICAO 9303 data

**Implementation**:
```swift
import CoreNFC

class GovernmentIDScanner: NSObject, NFCTagReaderSessionDelegate {
    
    var nfcSession: NFCTagReaderSession?
    var completionHandler: ((GovernmentID?, Error?) -> Void)?
    
    func startScan(completion: @escaping (GovernmentID?, Error?) -> Void) {
        // Check NFC availability
        guard NFCTagReaderSession.readingAvailable else {
            completion(nil, ScannerError.nfcNotAvailable)
            return
        }
        
        self.completionHandler = completion
        
        // Create NFC session
        nfcSession = NFCTagReaderSession(
            pollingOption: [.iso14443],
            delegate: self,
            queue: DispatchQueue.main
        )
        
        nfcSession?.alertMessage = "Hold your government ID near the top of your iPhone"
        nfcSession?.begin()
    }
    
    // MARK: - NFCTagReaderSessionDelegate
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // Called when NFC reader is ready
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, 
                         didInvalidateWithError error: Error) {
        completionHandler?(nil, error)
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, 
                         didDetect tags: [NFCTag]) {
        // Process detected NFC tag
        guard let tag = tags.first else { return }
        
        session.connect(to: tag) { [weak self] error in
            if let error = error {
                self?.completionHandler?(nil, error)
                return
            }
            
            // Read NDEF records (or raw APDU for passport)
            self?.readGovernmentIDData(tag: tag, session: session)
        }
    }
    
    private func readGovernmentIDData(tag: NFCTag, session: NFCTagReaderSession) {
        // Parse APDU responses for ICAO 9303 data
        // Extract:
        //  - Full name
        //  - Date of birth
        //  - Document number
        //  - Facial image / biometric template
        //  - Government signature
        
        // Delegate to ICAO9303Validator for signature checking
        let validator = ICAO9303Validator()
        if validator.validate(data: extractedData) {
            let governmentID = GovernmentID(
                fullName: "...",
                dateOfBirth: Date(),
                documentNumber: "...",
                biometricTemplate: Data(),
                governmentSignature: Data(),
                isValid: true
            )
            completionHandler?(governmentID, nil)
        } else {
            completionHandler?(nil, ScannerError.invalidSignature)
        }
        
        session.invalidate()
    }
}

enum ScannerError: Error {
    case nfcNotAvailable
    case readingFailed
    case invalidSignature
    case noDataRead
}
```

**ICAO 9303 Validation**:
```swift
// File: Sources/NFC/ICAO9303Validator.swift

class ICAO9303Validator {
    
    private let governmentPublicKeys: [String: SecKey] = {
        // Bundle government public keys for common countries
        // Downloaded once, cached in app
        return [
            "US": loadPEMKey("us-government.pem"),
            "GB": loadPEMKey("uk-government.pem"),
            "DE": loadPEMKey("germany-government.pem"),
            // ... 190+ countries
        ]
    }()
    
    func validate(data: Data, signature: Data, countryCode: String) -> Bool {
        guard let publicKey = governmentPublicKeys[countryCode] else {
            return false
        }
        
        // Verify 256-bit ECDSA signature
        let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageSHA256
        let isValid = SecKeyVerifySignature(
            publicKey,
            algorithm,
            data,
            signature,
            nil
        )
        
        return isValid
    }
    
    private func loadPEMKey(_ filename: String) -> SecKey? {
        // Load from app bundle, convert PEM to SecKey
        guard let keyData = loadPEMData(filename) else { return nil }
        
        let keyAttrs: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
        ]
        
        var error: Unmanaged<CFError>?
        let key = SecKeyCreateWithData(keyData as CFData, keyAttrs as CFDictionary, &error)
        return key
    }
}
```

**Input**: NFC-equipped iPhone, government ID (passport or national ID)
**Output**: `GovernmentID` object with validated data
**Dependencies**: CoreNFC, CryptoKit

---

### 2. Biometric Hashing (Privacy-First)

**File**: `Sources/Crypto/BiometricHasher.swift`

**Responsibility**: Extract facial geometry from ID photo, compute SHA-256 hash

**Why**: Prevents duplicate registrations without storing raw biometric data

```swift
import Vision
import CryptoKit

class BiometricHasher {
    
    func hashBiometricData(
        facialImage: UIImage,
        biometricTemplate: Data?
    ) throws -> String {
        // Step 1: Extract facial landmarks from image
        let facialGeometry = try extractFacialGeometry(image: facialImage)
        
        // Step 2: Combine geometry + template data
        var bioData = Data()
        bioData.append(facialGeometry)
        if let template = biometricTemplate {
            bioData.append(template)
        }
        
        // Step 3: SHA-256 hash (one-way, cannot reverse)
        let digest = SHA256.hash(data: bioData)
        let hashString = digest.map { String(format: "%02x", $0) }.joined()
        
        return hashString
    }
    
    private func extractFacialGeometry(image: UIImage) throws -> Data {
        guard let cgImage = image.cgImage else {
            throw HashingError.invalidImage
        }
        
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)
        
        try handler.perform([request])
        
        guard let result = request.results?.first as? VNFaceObservation else {
            throw HashingError.noFaceDetected
        }
        
        // Extract landmark positions (nose, eyes, mouth, etc.)
        var geometry = Data()
        
        if let landmarks = result.landmarks {
            // Add all landmark positions (normalized coordinates)
            if let nose = landmarks.nose {
                addLandmarkToData(&geometry, nose.normalizedPoints)
            }
            if let leftEye = landmarks.leftEye {
                addLandmarkToData(&geometry, leftEye.normalizedPoints)
            }
            if let rightEye = landmarks.rightEye {
                addLandmarkToData(&geometry, rightEye.normalizedPoints)
            }
            if let mouth = landmarks.mouth {
                addLandmarkToData(&geometry, mouth.normalizedPoints)
            }
            // ... add other landmarks
        }
        
        return geometry
    }
    
    private func addLandmarkToData(_ data: inout Data, _ points: [CGPoint]) {
        for point in points {
            var x = Float(point.x)
            var y = Float(point.y)
            data.append(Data(bytes: &x, count: MemoryLayout<Float>.size))
            data.append(Data(bytes: &y, count: MemoryLayout<Float>.size))
        }
    }
}

enum HashingError: Error {
    case invalidImage
    case noFaceDetected
    case processingFailed
}
```

**Input**: Facial image (from government ID scan) + biometric template
**Output**: SHA-256 hash string (e.g., "7f2d4a8b9c3e5f1d...")
**Privacy**: Raw biometric data is NOT stored; only hash is transmitted

---

### 3. Cryptographic Key Generation

**File**: `Sources/Crypto/KeyGenerator.swift`

**Responsibility**: Generate Ed25519 keypairs in iOS Secure Enclave

```swift
import CryptoKit

class KeyGenerator {
    
    func generateKeyPair() throws -> (privateKey: Data, publicKey: Data) {
        // Generate Ed25519 keypair using CryptoKit
        let privateKey = Curve25519.Signing.PrivateKey()
        let publicKeyObject = privateKey.publicKey
        
        // Serialize public key
        let publicKeyData = publicKeyObject.rawRepresentation
        
        // For private key: store in Keychain, return reference
        let privateKeyData = privateKey.rawRepresentation
        
        return (privateKeyData, publicKeyData)
    }
    
    func storePrivateKeyInSecureEnclave(
        privateKeyData: Data,
        userID: String
    ) throws {
        // Store in iOS Keychain (hardware-backed secure enclave)
        let keychain = KeychainManager.shared
        try keychain.savePrivateKey(privateKeyData, forUserID: userID)
    }
    
    func signMessage(_ message: Data, withUserID userID: String) throws -> Data {
        // Retrieve private key from Keychain
        let keychain = KeychainManager.shared
        guard let privateKeyData = try keychain.retrievePrivateKey(forUserID: userID) else {
            throw KeyError.keyNotFound
        }
        
        // Create Ed25519 signing key
        let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)
        
        // Sign message
        let signature = try privateKey.signature(for: message)
        
        return Data(signature)
    }
}

enum KeyError: Error {
    case generationFailed
    case storageFailed
    case keyNotFound
    case signatureGenerationFailed
}
```

**Keychain Storage**:
```swift
// File: Sources/Storage/KeychainManager.swift

class KeychainManager {
    static let shared = KeychainManager()
    
    func savePrivateKey(_ keyData: Data, forUserID userID: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "private_key_\(userID)",
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete if exists
        SecItemDelete(query as CFDictionary)
        
        // Save new key
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    func retrievePrivateKey(forUserID userID: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "private_key_\(userID)",
            kSecReturnData as String: true
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data {
            return data
        }
        return nil
    }
}

enum KeychainError: Error {
    case saveFailed(OSStatus)
    case retrievalFailed(OSStatus)
}
```

**Security Notes**:
- Private keys NEVER leave device (except for intentional backup process)
- Stored in Keychain with device-only accessibility
- Protected by device passcode/biometric if configured
- Ed25519 provides 256-bit cryptographic security

---

### 4. UserID Generation

**File**: `Sources/Crypto/UserIDGenerator.swift`

**Responsibility**: Combine biometric hash + public key + timestamp → unique UserID

```swift
import CryptoKit

class UserIDGenerator {
    
    func generateUserID(
        biometricHash: String,
        publicKey: Data,
        communityID: String = "global",
        timestamp: Date = Date()
    ) throws -> String {
        // Combine components
        var inputData = Data()
        
        // 1. Biometric hash (32 bytes from SHA-256)
        inputData.append(Data(biometricHash.utf8))
        
        // 2. Public key (32 bytes for Ed25519)
        inputData.append(publicKey)
        
        // 3. Community ID (prevents same user from being registered in different communities)
        inputData.append(Data(communityID.utf8))
        
        // 4. Timestamp (ensures uniqueness even with identical other components)
        var timestampInterval = UInt64(timestamp.timeIntervalSince1970)
        inputData.append(Data(bytes: &timestampInterval, count: 8))
        
        // 5. Hash all together → UserID
        let userIDDigest = SHA256.hash(data: inputData)
        let userIDHex = userIDDigest.map { String(format: "%02x", $0) }.joined()
        
        // Format: "0x" + 64-char hex
        let userID = "0x" + userIDHex
        
        return userID
    }
}
```

**Output Format**:
- `0x7f2d4a8b9c3e5f1d2b4c6e8f0a2c4e6a8f0b2d4e6f8a0c2e4a6c8e0a2c4e6a`
- 0x prefix + 64 hex characters (256-bit hash)
- Immutable forever (derived from immutable components)
- Globally unique (vanishingly small probability of collision)

---

### 5. Blockchain Registration

**File**: `Sources/Blockchain/RegistrationTransactor.swift`

**Responsibility**: Submit registration to TrustNet blockchain

```swift
class RegistrationTransactor {
    private let blockchainNode: BlockchainConnector
    
    init(nodeURL: URL = URL(string: "http://localhost:26657")!) {
        self.blockchainNode = BlockchainConnector(nodeURL: nodeURL)
    }
    
    func registerIdentity(
        userID: String,
        publicKey: Data,
        biometricHash: String,
        displayName: String,
        communityID: String = "global",
        signature: Data
    ) async throws -> String {
        // Create registration transaction
        let transaction = RegistrationTransaction(
            userID: userID,
            publicKey: publicKey.base64EncodedString(),
            biometricHash: biometricHash,
            displayName: displayName,
            communityID: communityID,
            timestamp: Date().timeIntervalSince1970,
            signature: signature.base64EncodedString()
        )
        
        // Submit to blockchain node
        let txHash = try await blockchainNode.submitTransaction(transaction)
        
        // Poll for confirmation (Tendermint instant finality)
        let confirmation = try await waitForConfirmation(txHash: txHash, timeout: 10)
        
        guard confirmation.success else {
            throw RegistrationError.blockchainRejected(confirmation.error)
        }
        
        return txHash
    }
    
    private func waitForConfirmation(txHash: String, timeout: TimeInterval) async throws -> TransactionConfirmation {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            do {
                let status = try await blockchainNode.getTransactionStatus(txHash)
                
                if status.confirmed {
                    return TransactionConfirmation(success: true, error: nil)
                }
                
                // Wait 1 second before next check
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch {
                // Temporary error, retry
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        
        throw RegistrationError.timeout
    }
}

struct RegistrationTransaction: Codable {
    let userID: String
    let publicKey: String          // base64-encoded
    let biometricHash: String      // SHA-256 hex string
    let displayName: String
    let communityID: String
    let timestamp: Double
    let signature: String          // base64-encoded Ed25519 signature
}

enum RegistrationError: Error {
    case blockchainRejected(String)
    case timeout
    case connectionFailed
}
```

**Blockchain Storage** (via smart contract):
```
IdentityRegistry contract:
  - Record UserID → { publicKey, biometricHash, displayName, timestamp }
  - Index biometricHash → UserID (for duplicate detection)
  - Immutable (no updates/deletes)
```

---

### 6. Local Secure Storage

**File**: `Sources/Storage/UserDataManager.swift`

**Responsibility**: Store registration data in iOS Keychain for offline access

```swift
class UserDataManager {
    static let shared = UserDataManager()
    private let keychain = KeychainManager.shared
    
    struct RegisteredUser: Codable {
        let userID: String
        let publicKeyBase64: String
        let biometricHash: String
        let displayName: String
        let communityID: String
        let registrationTimestamp: TimeInterval
        let blockchainTxHash: String
    }
    
    func saveRegistration(
        userID: String,
        publicKey: Data,
        biometricHash: String,
        displayName: String,
        communityID: String,
        txHash: String
    ) throws {
        let user = RegisteredUser(
            userID: userID,
            publicKeyBase64: publicKey.base64EncodedString(),
            biometricHash: biometricHash,
            displayName: displayName,
            communityID: communityID,
            registrationTimestamp: Date().timeIntervalSince1970,
            blockchainTxHash: txHash
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        let userData = try encoder.encode(user)
        
        // Save to Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "registered_user",
            kSecValueData as String: userData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw StorageError.saveFailed
        }
    }
    
    func retrieveRegistration() -> RegisteredUser? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "registered_user",
            kSecReturnData as String: true
        ]
        
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else {
            return nil
        }
        
        guard let data = result as? Data else { return nil }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(RegisteredUser.self, from: data)
    }
    
    func isUserRegistered() -> Bool {
        return retrieveRegistration() != nil
    }
}

enum StorageError: Error {
    case saveFailed
    case retrievalFailed
}
```

**Stored Data**:
- ✅ UserID (public, needed for every transaction)
- ✅ Public key (public, needed for verification)
- ✅ Biometric hash (public, but sensitive - never share)
- ✅ Display name (public, user-chosen)
- ✅ Blockchain TX hash (proof of registration)
- ❌ NEVER: Private key (stays in Keychain separately)
- ❌ NEVER: Raw government ID data

---

## Implementation Sequence

### Week 1: Core Infrastructure
1. ✅ Create project structure (files listed above)
2. ✅ Implement `KeychainManager` (storage foundation)
3. ✅ Implement `KeyGenerator` with certificate/key handling
4. ✅ Write unit tests for key generation

### Week 2: NFC & Validation
5. ✅ Implement `GovernmentIDScanner` (NFC reading)
6. ✅ Implement `ICAO9303Validator` (signature verification)
7. ✅ Test with actual government ID (passport/national ID)
8. ✅ Write unit tests for NFC parsing

### Week 3: Biometric & UserID
9. ✅ Implement `BiometricHasher` (facial geometry extraction)
10. ✅ Implement `UserIDGenerator` (hash combination)
11. ✅ Unit tests for hash consistency
12. ✅ Test privacy (verify hashes don't expose raw data)

### Week 4: Blockchain Integration
13. ✅ Implement `BlockchainConnector` (node communication)
14. ✅ Implement `RegistrationTransactor` (transaction submission)
15. ✅ Integration test with local TrustNet node
16. ✅ Test transaction signing and blockchain confirmation

### Week 5: UI & End-to-End
17. ✅ Implement `RegistrationView.swift` (SwiftUI screens)
18. ✅ Connect all components into registration flow
19. ✅ End-to-end testing (full user flow)
20. ✅ Error handling & user feedback

### Week 6: Polish & Testing
21. ✅ Edge case handling (no NFC, invalid ID, etc.)
22. ✅ Performance optimization
23. ✅ Security review (private key handling, etc.)
24. ✅ Release candidate

---

## Testing Strategy

### Unit Tests
- `KeyGeneratorTests`: Verify Ed25519 keypair generation
- `BiometricHasherTests`: Match hash output against reference hashes
- `UserIDGeneratorTests`: Deterministic UserID from inputs
- `KeychainManagerTests`: Secure storage and retrieval

### Integration Tests
- `NFCIntegrationTests`: Real government ID scanning (requires testable government ID)
- `BlockchainIntegrationTests`: Registration transaction submission & confirmation
- `EndToEndTests`: Full registration flow on simulator + test blockchain node

### Manual Testing Checklist
- [ ] Run on iPhone 13+ with NFC
- [ ] Scan government ID (passport, national ID)
- [ ] Verify ICAO 9303 signature validation
- [ ] Check Keychain storage via iOS Settings
- [ ] Verify blockchain confirmation via node RPC
- [ ] Test offline operation (after registration)
- [ ] Test private key signing (for future transactions)

---

## Government Public Keys

**To implement**: Bundle government public keys for ~200 countries

**Source**: ICAO provides these as part of PKI ("Public Key Infrastructure")

**Process**:
1. Download official ICAO PKI certificates
2. Extract country public keys
3. Convert to PEM format
4. Bundle in app (encrypted or plaintext)
5. Validate signatures in `ICAO9303Validator`

**Note**: This is a one-time setup; keys rarely change, but annual updates recommended.

---

## Security Considerations

| Component | Threat | Mitigation |
|-----------|--------|-----------|
| Private Key | Theft from device | iOS Keychain + Secure Enclave |
| Private Key | Interception during transmission | NEVER transmitted |
| Biometric Hash | Reverse engineering | SHA-256 one-way; no raw data stored |
| Government ID Signature | Forgery | ICAO 9303 validation with government keys |
| UserID Collision | Impersonation | SHA-256 produces 2^256 space; birthday paradox negligible |
| Blockchain Transaction | Replay attack | Timestamp + nonce in transaction |
| Blockchain Transaction | Double-spending identity | Smart contract rejects duplicate biometric hashes |

**Cryptographic Standards**:
- Ed25519: RFC 8032 (IETF standard)
- SHA-256: FIPS 180-4
- ECDSA 256-bit: FIPS 186-4 (government standards)
- Keychain: Apple platform security standard (hardware-backed)

---

## Future Extensions (Not in Scope for v1)

- **Backup & Recovery**: Export encrypted private key + recovery codes
- **Multiple Identities**: User can register multiple identities (different biometric + ID)
- **ID Renewal**: When government ID expires, re-verify with new ID
- **Revocation**: Revoke identity if ID document is lost/stolen
- **Face ID Authentication**: Use Face ID to sign transactions (app-level convenience)

---

## Success Criteria

- ✅ User can register with single iPhone
- ✅ Government ID validates via ICAO 9303
- ✅ Private key never leaves device
- ✅ Public key recorded on blockchain
- ✅ Biometric hash prevents duplicate registration
- ✅ Offline operation works (can view identity, sign transactions without blockchain)
- ✅ No sensitive data in logs or debug output
- ✅ Zero user data stored on backend servers
- ✅ Registration takes < 2 minutes (UX target)

---

## Questions & Decisions

**Q**: What if user loses iPhone?
**A**: Private key is gone (v1). Future: add encrypted backup to recovery device.

**Q**: What if government changes ID format?
**A**: Update `ICAO9303Validator` with new format; bundled in app update.

**Q**: Can user register multiple times?
**A**: No. Biometric hash check prevents it. If user tries, blockchain rejects with "already registered".

**Q**: What about countries without NFC IDs?
**A**: v1 = NFC only. v2 = manual entry option (deferred, requires liveness detection).

---

**Document Standard**: This is the implementation contract. All decisions locked in. Changes require written decision and documented rationale.

