# Phase 1C: Key Generator - Technical Implementation Notes

**Date**: March 19, 2026  
**Status**: Implementation In Progress  
**Internal Documentation Only** - WIP repo only

---

## Phase 1C: Key Generator Implementation

### Objective
Create cryptographic P256 keypair generation and deterministic UserID derivation for:
- Blockchain registration identity
- NFC signing capability (prevent forgery)
- Unique user identification without privacy exposure

### Dependencies
- Models.swift (Uses GovernmentID, BiometricHash structs) ✅
- Errors.swift (Error handling patterns) ✅
- CryptoKit (P256 keypair generation, SHA-256)
- Security framework (optional, for keychain integration in Phase 1D)
- Foundation

### File Created
**Sources/KeyGenerator.swift** (287 lines)

---

## Architecture Decisions

### 1. P256 ECDSA Cryptography
**Decision**: Use Apple's CryptoKit P256.Signing for keypair generation
```swift
let privateKey = P256.Signing.PrivateKey()
let publicKey = privateKey.publicKey
```

**Rationale**:
- P-256 (secp256r1) is government encryption standard (NIST, FIPS 186-4)
- 256-bit security level adequate for identity verification
- Hardware-backed on iPhones (Secure Enclave capable)
- Industry standard for blockchain (Ethereum uses secp256k1, similar concept)
- CryptoKit is native iOS framework (no external dependencies)

**Alternatives rejected**:
- RSA 2048: Larger keys (2048 bits), slower operations, overkill for identity
- RSA 4096: Excessive key size for identity use case
- Ed25519: Not G ovt standard, less compatible with blockchain systems

### 2. Deterministic UserID Derivation
**Decision**: Hash combination of governmentID + biometricHash + publicKeyHash
```
UserID = SHA-256(documentNumber | biometricHash | publicKeyHash)
         → Truncate to 20 chars with "TN_" prefix
```

**Rationale**:
- Deterministic: Same government ID + biometric always produces same UserID
- Prevents duplicate registrations: Different faces → different biometricHash → different UserID
- Incorporates public key: Links identity to specific keypair (can't reuse keys)
- Collision-resistant: SHA-256 provides 256-bit security, truncated to 160 bits
- Format "TN_" (TrustNet prefix) makes IDs readable and identifiable

**Example**:
```
Input:
  documentNumber: "US-123456789"
  biometricHash:  "a7f4c8e3d1b2f9a4e6c3b8d1f5a9e2c7"
  publicKeyHash:  "b9e3d7a1c4f8b2e5d9a6c3f1e8b4d7a0"

Combined: "US-123456789|a7f4c8e3d1b2f9a4e6c3b8d1f5a9e2c7|b9e3d7a1c4f8b2e5d9a6c3f1e8b4d7a0"
SHA-256:  "f4e3d2c1b9a8f7e6d5c4b3a29f8e7d6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1f0"
UserID:   "TN_f4e3d2c1b9a8f7e6d5" (first 20 chars)
```

### 3. PEM Encoding for Key Storage
**Decision**: Encode keys in industry-standard PEM format (Base64 + headers)
```
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEwCCsGSM49AWEDQQA...
-----END PRIVATE KEY-----
```

**Rationale**:
- PEM is universal format (all cryptography libraries support it)
- Base64 encoding: Safe for text storage, no binary issues
- Headers ("BEGIN/END") prevent parsing errors
- Can be viewed in text editors for debugging
- Compatible with blockchain systems expecting PEM keys

**Alternative (raw binary)**: Would be more compact but less portable

### 4. PKCS#8 DER Structure for Private Keys
**Decision**: Wrap raw P256 private key in PKCS#8 DER container
```
SEQUENCE {
  version INTEGER (0)
  privateKeyAlgorithm SEQUENCE {
    algorithm OID (1.2.840.10045.2.1 = ecPublicKey)
    parameters OID (1.2.840.10045.3.1.7 = P-256 secp256r1)
  }
  privateKey OCTET STRING (32 bytes)
}
```

**Rationale**:
- PKCS#8 is industry standard container (RFC 5208)
- Includes algorithm identifier (prevents mixing key types)
- Allows future key attribute extensions
- Required by most cryptographic libraries (OpenSSL, Keychain, etc.)

**Why not PKCS#1**: PKCS#1 is RSA-specific, PKCS#8 is universal

### 5. Subject Public Key Info (SPKI) DER for Public Keys
**Decision**: Encode public key in SPKI format (X.509 standard)
```
SEQUENCE {
  algorithm SEQUENCE {
    algorithm OID (1.2.840.10045.2.1 = ecPublicKey)
    parameters OID (1.2.840.10045.3.1.7 = P-256)
  }
  subjectPublicKey BIT STRING
}
```

**Rationale**:
- SPKI is X.509 standard for public key distribution
- Includes algorithm identifier (prevents key type confusion)
- Compatible with certificate generation (future feature)
- Required by blockchain validators

### 6. Key Derivation Security
**Decision**: Use CryptoKit's secure random for keypair generation (not derived from password)

**Rationale**:
- Phone's secure random source (CS random)
- No password needed (private key stored in Keychain)
- Can't be reconstructed from user input
- Every registration creates unique keypair (prevents account linking)

**Alternative (derived keys)**: Would require password, adds complexity, unnecessary for this use case

---

## Implementation Details

### Public API

```swift
// Main generation function
generateKeypair(
  for governmentID: GovernmentID,
  with biometricHash: BiometricHash
) throws -> (privateKey, publicKey, userID: String)

// PEM conversion (for storage/transmission)
privateKeyToPEM(_ privateKey: P256.Signing.PrivateKey) throws -> String
publicKeyToPEM(_ publicKey: P256.Signing.PublicKey) throws -> String
```

### UserID Generation Flow
```
1. governmentID.documentNumber      "US-123456789"
2. biometricHash.hash               "a7f4c8e3..."
3. publicKey → SHA-256              "b9e3d7a1..."
4. Concatenate with separators      "US-123456789|a7f4c8e3|b9e3d7a1"
5. SHA-256 hash the combined string "f4e3d2c1b9a8f7e6d5c4b3a29f8e7d6c..."
6. Truncate to 20 chars + "TN_"    "TN_f4e3d2c1b9a8f7e6d5"
```

### Key Format Conversion
```
P256.Signing.PrivateKey (CryptoKit)
  ↓ rawRepresentation
  32-byte raw private key
  ↓ constructPKCS8DER()
  DER SEQUENCE with algorithm info
  ↓ base64 encode
  ↓ wrap with -----BEGIN/END-----
  PEM format for storage
```

### DER Encoding Implementation
- Manual ASN.1 DER encoding (no external library)
- Handles length encoding for lengths > 127 (long form)
- Properly tagged: SEQUENCE (0x30), OCTET STRING (0x04), BIT STRING (0x03)
- Supports P-256 curve OID: 1.2.840.10045.3.1.7

---

## Testing Strategy (Phase 1C)

### Unit Tests Needed
```swift
// 1. Keypair generation
✓ generateKeypair() creates valid P256 private/public key pair
✓ generateKeypair() produces deterministic UserID for same inputs
✓ generateKeypair() produces different UserID for different government ID
✓ generateKeypair() produces different UserID for different biometric hash

// 2. UserID validation
✓ UserID always starts with "TN_"
✓ UserID is exactly 23 characters (3 + 20)
✓ UserID is hexadecimal (only 0-9, a-f)
✓ UserID from same inputs is identical
✓ UserID from different inputs is different

// 3. PEM encoding
✓ privateKeyToPEM() produces valid PEM format (headers + base64)
✓ publicKeyToPEM() produces valid PEM format
✓ PEM keys can be read back and verified

// 4. DER structure validation
✓ PKCS#8 DER includes version (0)
✓ PKCS#8 DER includes algorithm OID (P-256)
✓ PKCS#8 DER includes private key (32 bytes)
✓ SPKI DER includes algorithm OID
✓ SPKI DER includes public key with BIT STRING tag

// 5. Key cryptography
✓ Private/public key pair can sign and verify messages
✓ Signature from private key verifies with public key
✓ Different private keys produce different signatures
```

### Integration Tests
- Private key signs transaction, public key verifies (blockchain compatibility)
- UserID generated from real government ID structure
- Keys export/import round-trip maintains validity

### Performance Testing
- Keypair generation: <100ms (mainly random generation)
- PEM encoding: <10ms
- UserID derivation: <5ms
- Total: <120ms per registration

---

## Known Limitations & Future Enhancements

### Limitations

1. **No Hardware Security (yet)**
   - Keys stored in software initially (Keychain in Phase 1D)
   - iPhone Secure Enclave could store keys (more secure)
   - Future: Upgrade to Secure Enclave-backed keys if needed

2. **No Key Rotation**
   - Current: One keypair per registration
   - Future: Support key rotation if user wants new keypair

3. **No Backup/Recovery**
   - No seed phrase or recovery mechanism
   - If private key deleted: User must re-register
   - Acceptable for MVP (blockchain address is immutable)

### Future Enhancements

1. **Hierarchical Deterministic Keys**
   - Generate multiple keys from seed phrase
   - Allow recovery if device is lost
   - More complex but better user experience

2. **Secure Enclave Integration**
   - Upgrade keys to hardware-backed storage
   - Prevents extraction even from jailbroken phone
   - Requires iOS 16+ and supported devices (iPhone 6s+)

3. **Key Attestation**
   - Prove keys were generated on genuine Apple device
   - Requires additional API integration
   - Useful for high-security blockchain operations

---

## Git Commit Plan

Files to commit:
- `Sources/KeyGenerator.swift`

Commit message:
```
feat: Phase 1C - Implement P256 keypair generator with deterministic UserID

- P256.Signing keypair generation using CryptoKit (government-standard crypto)
- Deterministic UserID derivation (SHA-256 of governmentID+biometricHash+publicKeyHash)
- PKCS#8 DER encoding for private keys, SPKI DER for public keys
- PEM format conversion for storage and transmission
- Manual ASN.1 DER encoding without external dependencies
- Supports blockchain registration with unique user identifiers
- Comprehensive error handling and recovery suggestions
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

Before moving to Phase 1D, verify:
- [ ] `xcodebuild` succeeds with no errors
- [ ] No compiler warnings
- [ ] KeyGenerator class compiles
- [ ] CryptoKit imported correctly
- [ ] P256.Signing keypair generation working
- [ ] PEM encoding produces valid format
- [ ] DER structure correctly formed
- [ ] UserID deterministic for same inputs
- [ ] All error cases handled
- [ ] Phase 0, 1A, 1B still compile (no regressions)

---

## Dependencies for Phase 1D

Phase 1D (Keychain Manager) will:
- Take generated privateKey from KeyGenerator
- Store securely in Keychain
- Retrieve when needed for signing transactions
- Prevent export of raw key bytes

---

## How This Component Fits

**Phase 1C in Registration Flow**:
```
1. Phase 1A: Validate government ID signature ✅
2. Phase 1B: Extract & hash facial biometric ✅
3. Phase 1C: Generate keypair + UserID (THIS)
4. Phase 1D: Store private key securely
5. Phase 2: Send all to blockchain for final registration
```

**Blockchain Registration Data**:
```
UserRegistration {
  userID: String             // Deterministic identifier: "TN_f4e3d2c1b9a8f7e6d5"
  publicKey: String          // PEM-encoded, sent to blockchain
  governmentID: String       // Document number
  biometricHash: String      // Facial geometry SHA-256
  timestamp: Date            // Registration time
  signature: Data            // Signed by private key
}
```

---

**Last Updated**: March 19, 2026 23:55 UTC
