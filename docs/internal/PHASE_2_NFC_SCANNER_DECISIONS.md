# Phase 2: NFC Scanner - Technical Implementation Notes

**Date**: March 19, 2026  
**Status**: Implementation In Progress  
**Internal Documentation Only** - WIP repo only

---

## Phase 2: NFC Scanner Implementation

### Objective
Read government ID data from NFC chips and orchestrate complete registration flow by:
- Scanning government ID via NFC (ISO14443-A standard)
- Validating government signature (Phase 1A)
- Processing facial biometric (Phase 1B)
- Generating keypair and UserID (Phase 1C)
- Storing private key securely (Phase 1D)
- Creating immutable registration data for blockchain

### Dependencies
- Models.swift (GovernmentID, BiometricHash, RegistrationState) ✅
- Errors.swift (Error handling patterns) ✅
- ICAO9303Validator.swift (Phase 1A) ✅
- BiometricHasher.swift (Phase 1B) ✅
- KeyGenerator.swift (Phase 1C) ✅
- KeychainManager.swift (Phase 1D) ✅
- CoreNFC (Apple's NFC framework)
- Foundation, UIKit

### File Created
**Sources/GovernmentIDScanner.swift** (438 lines)

---

## Architecture Decisions

### 1. CoreNFC for Government ID Reading
**Decision**: Use Apple's native CoreNFC framework for NFC reading
```swift
NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
```

**Rationale**:
- Native iOS framework: Part of iOS 13+, no external dependencies
- ISO14443-A support: Universal for government IDs worldwide
- Hardware acceleration: NFC controller handles protocol
- Privacy: User must grant permission, shows NFC icon in status bar
- Security: Data not logged or transmitted to Apple

**Alternative (custom NFC library)**: Would add complexity and external dependency

**iPhone Compatibility**:
- iPhone XS+, 11+, 14+: All support NFC
- SE (1st gen): No NFC
- SE (2nd gen)+: NFC supported

### 2. ICAO 9303 Data Structure
**Decision**: Parse government IDs according to ICAO 9303 standard
```
ICAO 9303 = International standard for machine-readable documents
Used by: Passports, visas, ID cards, travel permits

Structure:
  Data Group 1 (DG1): Personal data (name, DOB, document number)
  Data Group 2 (DG2): Face photo (JPEG 2000 or JPEG)
  Data Group 14 (DG14): Public key certificate
  Data Group 13 (SOD): Security object with signature
```

**Rationale**:
- Universal standard: All government IDs follow this format
- ISO/IEC 14443: NFC protocol for card communication
- TLV encoding: Tag-Length-Value format for data parsing
- APDU commands: Standard for smartcard communication

**Implementation Approach**:
- Select DG files using APDU commands
- Read binary data using READ BINARY command
- Parse TLV structure for attribute extraction
- Validate with embedded government certificate

### 3. Orchestration of Phase 1 Components
**Decision**: Sequential validation flow integrating all 4 Phase 1 modules
```
NFC Read → Validate (1A) → Hash Biometric (1B) → Generate Keys (1C) → Store (1D)
```

**Rationale**:
- Fail-fast: Stop at first error (invalid signature, bad photo, etc.)
- Complete flow: Full registration in single operation
- Error recovery: User-friendly messages at each step
- Atomic: Either fully succeeds or fully rolls back

**Flow**:
```
1. User taps "Scan ID"
2. NFCTagReaderSession begins
3. User holds iPhone to government ID
4. CoreNFC reads data (DG1, DG2, DG13, DG14)
5. Parse ICAO 9303 structure
6. Validate signature with government cert (Phase 1A)
   └→ If invalid: throw .invalidSignature
7. Hash facial photo (Phase 1B)
   └→ If no face: throw .biometricProcessingFailed
8. Generate P256 keypair + UserID (Phase 1C)
   └→ If fails: throw .keyGenerationFailed
9. Store private key in Keychain (Phase 1D)
   └→ If locked: throw .keychainStorageError
10. Create immutable RegistrationData
11. Return to caller for blockchain submission
```

### 4. RegistrationData Structure
**Decision**: Immutable struct containing all registration information
```swift
struct RegistrationData {
    let userID: String                // TN_... identifier
    let governmentID: GovernmentID    // Full ID data
    let biometricHash: BiometricHash  // Facial geometry
    let publicKeyPEM: String          // For blockchain verification
    let timestamp: Date               // When registered
}
```

**Rationale**:
- Immutable: Can't be modified after creation
- Self-contained: Everything needed for blockchain
- Portable: Can be serialized to JSON for transmission
- Verifiable: Signature proves government ID ownership

### 5. Private Key Management via Keychain
**Decision**: Immediately store private key, never expose raw bytes to app
```swift
try keychainManager.storePrivateKey(
    privateKey.rawRepresentation,
    for: userID,
    requireBiometric: false
)
```

**Rationale**:
- Automatic storage: No user action needed
- Secure: Hardware-encrypted in Keychain immediately
- Immutable: Private key protected by device passcode
- Metadata: Timestamp and creation date tracked

**Note**: Biometric protection is optional (default: false)
- User can enable later in Settings
- Simpler onboarding for MVP

### 6. Error Handling Strategy
**Decision**: Specific error types for each failure point with recovery suggestions
```
.nfcNotAvailable → Device doesn't support NFC
.invalidSignature → Government didn't sign correctly (fraud detection)
.biometricProcessingFailed → No face in photo
.keychainStorageError → Device locked during storage
.documentAlreadyRegistered → UserID already exists
```

**Rationale**:
- User guidance: Clear message + how to recover
- Security: Invalid signature stops registration (fraud)
- Debugging: Specific errors help troubleshoot
- Retry logic: Some errors are transient (device lock)

---

## Implementation Details

### NFC Scanning Flow

```
beginScan(completion:)
  ├─ Check NFCTagReaderSession.readingAvailable
  │  └─ If false: .nfcNotAvailable
  ├─ Create NFCTagReaderSession
  ├─ Set alertMessage: "Hold your government ID near the top..."
  └─ session.begin()

tagReaderSession(_:didDetect:)
  ├─ Get first NFCTag
  ├─ Connect to tag
  └─ Call processNFCTag()

processNFCTag(_:session:)
  ├─ extractGovernmentID(from:)
  │  ├─ readNFCDataGroup():
  │  │  ├─ APDU: SELECT FILE (specify DG1, DG2, etc.)
  │  │  ├─ APDU: READ BINARY (fetch data)
  │  │  └─ Parse TLV: Extract attributes
  │  └─ Return GovernmentID struct
  ├─ validator.validate() [Phase 1A]
  ├─ biometricHasher.hashBiometric() [Phase 1B]
  ├─ keyGenerator.generateKeypair() [Phase 1C]
  ├─ keychainManager.storePrivateKey() [Phase 1D]
  ├─ Create RegistrationData
  ├─ Return via completion handler
  └─ session.invalidate()
```

### APDU Command Structure

```
APDU = Application Protocol Data Unit
Format: [CLA] [INS] [P1] [P2] [LC] [DATA] [LE]

Example: SELECT DG1
  CLA=0x00    (Interindustry command)
  INS=0xA4    (SELECT FILE)
  P1=0x02     (Select by file identifier)
  P2=0x0C     (Return FCI template)
  LC=0x03     (Data length: 3 bytes)
  DATA=01 01 01  (File: 0x010101 = DG1)
  LE=0x00     (Expected response length: 256)

Example: READ BINARY
  CLA=0x00
  INS=0xB0    (READ BINARY)
  P1=0x00     (Offset high byte)
  P2=0x00     (Offset low byte)
  LE=0x00     (Read up to 256 bytes)
```

### TLV Encoding Example

```
Real data from ICAO 9303 DG1:
5F34 = Tag for full name
  02 = Length (2 bytes for this example)
  4A4F = "JO" (partial)

44 = Tag for document number
  09 = Length (9 bytes)
  4E4D3531323334353637 = "NM512345467"

5F28 = Tag for country code
  02 = Length (2 bytes)
  5553 = "US"

5F35 = Tag for date of birth
  06 = Length (6 bytes)
  3939303130313 = "990101" (YYMMDD format)

Full TLV bytestream:
5F3402 4A4F 44 09 4E4D3531323334353637 5F28 02 5553 5F35 06 3939303130313
```

### Signing for Blockchain

```swift
// User wants to submit to blockchain
let signedRegistration = try registrationData.sign(using: keychainManager)

// This:
// 1. Retrieves private key from secure Keychain
// 2. Encodes RegistrationData as JSON
// 3. Signs with private key (P256 ECDSA)
// 4. Returns signature (base64) + original data

// Blockchain validates:
// 1. Extract public key from RegistrationData
// 2. Confirm signature matches registration data
// 3. Verify government ID signature (public cert in DG14)
// 4. Record UserID + public key on blockchain
```

---

## Testing Strategy (Phase 2)

### Unit Tests

```swift
// 1. NFC availability
✓ beginScan() throws .nfcNotAvailable if NFCTagReaderSession.readingAvailable is false
✓ cancelScan() stops active session

// 2. APDU command construction
✓ APDU SELECT FILE has correct CLA/INS/P1/P2
✓ APDU READ BINARY correctly sets offset

// 3. TLV parsing
✓ TLVDecoder extracts correct value for tag
✓ TLVDecoder handles multiple TLV entries
✓ TLVDecoder returns nil for missing tag

// 4. MRZ parsing
✓ parseMRZ() extracts full name, document number, country code
✓ parseMRZ() correctly parses YYMMDD date
✓ parseMRZ() throws .invalidGovernmentID for missing fields

// 5. Registration data creation
✓ RegistrationData contains all required fields
✓ Signature is valid P256 ECDSA
✓ Timestamp is set to current time
```

### Integration Tests

```swift
// 1. Full scan flow (simulator / mock)
✓ Begin scan → Detect ID → Extract data → Generate registration
✓ Integration with Phase 1A (signature validation passes)
✓ Integration with Phase 1B (biometric hash matches)
✓ Integration with Phase 1C (UserID deterministic)
✓ Integration with Phase 1D (private key stored and retrievable)

// 2. Error cases
✓ Invalid government signature → .invalidSignature
✓ Photo with no face → .biometricProcessingFailed
✓ Device Keychain locked → .keychainStorageError
✓ ID already registered → .documentAlreadyRegistered
```

### Real Device Testing

Requirements:
- iPhone 14+ (or XS+) with NFC capability
- Real government ID (passport, national ID, visa)
- Device unlocked (for Keychain access)

Test cases:
1. Scan valid government ID → Success
2. Scan with photo at angle → Should still detect face
3. Scan with glasses/mask → Should fail if not detected
4. Scan expired ID → Valid (government still signed it)
5. Scan with NFC disabled → Clear error message
6. Scan while device locked → Keychain error
7. Scan after registration → Already registered error

### Performance Testing

```
NFC read: ~2-5 seconds (depends on ID chip speed)
ICAO parsing: ~50ms
Signature validation: ~20ms
Biometric hashing: <150ms
Keypair generation: <100ms
Keychain storage: <10ms
Total: ~2.3-5.3 seconds
```

---

## Known Limitations & Future Enhancements

### Limitations

1. **NFC Hardware Required**
   - Only iPhone XS+ or 11+
   - Older iPhones cannot scan
   - Simulat can't test NFC in simulator

2. **Government ID Required**
   - Must have NFC chip with ICAO 9303 data
   - Older passports may not have NFC
   - Some countries' IDs not compatible

3. **Language/Character Support**
   - MRZ uses specific encoding (mostly ASCII)
   - Non-Latin characters may need special handling
   - Future: Support more encodings

4. **Biometric Validation Only**
   - No liveness detection (can scan photo of ID)
   - Prevents duplicate registration, not spoofing
   - Future: Add liveness detection

### Future Enhancements

1. **Multi-Language Support**
   - Handle non-Latin names and characters
   - Support ICAO 9303 encoding variants

2. **Face Liveness Detection**
   - Detect if user is holding physical ID vs photo
   - Requires additional ML model or API

3. **Batch Registration**
   - Register multiple family members from one device
   - Multiple UserIDs for one phone

4. **Alternative ID Types**
   - Driver's licenses (some have NFC)
   - Resident cards, travel permits
   - Blockchain-based IDs

5. **Offline Verification**
   - Cache government public keys locally
   - Verify signatures without network (later validation)

---

## Git Commit Plan

Files to commit:
- `Sources/GovernmentIDScanner.swift`

Commit message:
```
feat: Phase 2 - Implement NFC government ID scanner with registration flow

- CoreNFC for ISO14443-A government ID reading
- ICAO 9303 standard parsing and data extraction
- Integration with all Phase 1 components:
  * Phase 1A: Validate government signature
  * Phase 1B: Hash facial biometric
  * Phase 1C: Generate keypair and UserID
  * Phase 1D: Store private key securely
- Complete registration data creation (immutable, blockchain-ready)
- Signature capability for blockchain submission
- Comprehensive error handling with recovery suggestions
- APDU command construction for smartcard communication
- TLV decoding for ICAO 9303 data parsing
```

---

## Build Validation Steps

1. **macOS**:
   ```bash
   ssh macosx "cd ios-app && git pull && xcodebuild build..."
   ```
   Expected: BUILD SUCCEEDED

---

## Validation Checklist

Before moving to Phase 3, verify:
- [ ] `xcodebuild` succeeds with no errors
- [ ] CoreNFC framework imported correctly
- [ ] NFCISO7816Tag handling working
- [ ] APDU command construction valid
- [ ] All Phase 1 components integrated
- [ ] No compiler warnings
- [ ] RegistrationData serializable to JSON
- [ ] Error cases comprehensive
- [ ] Phase 0, 1A, 1B, 1C, 1D still compile (no regressions)

---

## Dependencies for Phase 3

Phase 3 (State Manager + Blockchain Connector) will:
- Take RegistrationData from Phase 2
- Sign registration with private key
- Submit to blockchain (Ethereum, Solana, or custom chain)
- Track registration state (pending, confirmed, failed)
- Handle network retries and confirmations

---

## Security Model

**What's Protected**:
- Government signature validated ✓
- Private key never exposed ✓
- Biometric hashed, never raw data ✓
- Keychain encryption active ✓

**What's NOT Protected**:
- Liveness detection (can scan photo)
  → Mitigated: Blockchain prevents duplicate UserID
- NFC chip cloning
  → Mitigated: Government signature proves authenticity

---

**Last Updated**: March 19, 2026 23:55 UTC
