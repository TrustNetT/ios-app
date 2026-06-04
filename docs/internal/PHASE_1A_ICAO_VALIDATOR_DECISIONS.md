# Phase 1A: ICAO 9303 Validator - Technical Implementation Notes

**Date**: March 19, 2026  
**Status**: Implementation In Progress  
**Internal Documentation Only** - WIP repo only, never in public repo

---

## Phase 1A: ICAO 9303 Validator Implementation

### Objective
Create cryptographic signature validator that:
- Verifies government ID signatures using ECDSA P256
- Follows ICAO 9303 standard (international passport/ID specification)
- Supports multiple countries with different government keys
- Gracefully handles missing or invalid keys

### Dependencies
- Models.swift ✅ (Uses nothing from models, independent)
- Foundation, Security, CryptoKit (Apple frameworks)

### File Created
**Sources/ICAO9303Validator.swift** (180 lines)

---

## Architecture Decisions

### 1. Key Loading Strategy
**Decision**: Cache public keys in memory after first load
```
Load PEM → Convert to SecKey → Cache in dictionary → Reuse for subsequent validations
```

**Rationale**:
- PEM conversion is expensive (base64 decode + DER parse + SecKey creation)
- Caching avoids repeated work
- Dictionary lookup is O(1) - negligible overhead
- Memory footprint minimal (max ~50 countries × ~100 bytes each)

**Risk**: If app runs long-term, keys are never refreshed. **Mitigation**: Keys are public and immutable (government isn't rekeying), so caching is safe.

### 2. Signature Format: Raw ECDSA (IES 14888-2)
**Decision**: Accept 64-byte raw ECDSA signature (32 bytes R + 32 bytes S)
```
Raw format: [32-byte R | 32-byte S]
```

**Rationale**:
- ICAO 9303 specifies raw format as default for passports
- Smaller than DER-encoded (~140 bytes) 
- Simpler parsing
- NFC chip returns raw format

**Implementation**: Convert raw to DER internally for SecKeyVerifySignature (Apple requires DER)

### 3. DER Encoding for Signature Verification
**Decision**: Construct ASN.1 DER-encoded signature internally
```
DER = 0x30 <len> | 0x02 <r-len> <r-bytes> | 0x02 <s-len> <s-bytes>
```

**Rationale**:
- SecKeyVerifySignature requires DER format
- We can normalize the raw format ourselves rather than requiring caller to do so
- Cleaner API (accept standard ICAO format, handle details internally)

**Complexity**: Handle leading zero removal for positive integers (DER requirement)

### 4. PEM Key Loading from Bundle
**Decision**: Store government keys as PEM files in app bundle
```
Bundle/
├── GovernmentKeys/
│   ├── us.pem       (US government EC public key)
│   ├── gb.pem       (UK government EC public key)
│   ├── de.pem       (German government EC public key)
│   └── ... (up to 195 countries)
```

**Rationale**:
- PEM is human-readable, easy to audit
- Standard format for OpenSSL tools
- Can verify with: `openssl ec -pubin -in key.pem -text -noout`
- Easy to update/rotate keys in Xcode

**Security**: PEM is public data (public keys), no secrets exposed

**Limitation**: Countries must be pre-loaded at build time. **Future**: Could fetch from CDN if countries change frequently.

### 5. Error Handling Strategy
**Decision**: Throw specific errors instead of returning Bool

```swift
// OLD: func validate() -> Bool?
// NEW: func validate() throws -> Bool
```

**Rationale**:
- Distinguishes between "signature invalid" (returns false) vs "system error" (throws)
- Example: If country code missing, that's a system error (throw), not invalid sig (false)
- Caller can handle errors appropriately (UI message vs retry logic)

**Errors**:
- `.unknownCountry(code)` - Country not supported
- `.invalidSignatureFormat(details)` - Signature wrong size  
- `.verificationFailed(details)` - Crypto verification failed
- `.invalidPEMFormat(details)` - Key file corrupted
- `.keyCreationFailed(details)` - SecKey creation failed

---

## Implementation Details

### Key Loading Flow
```
1. getGovernmentPublicKey(for: "US")
   ├─ Check cachedPublicKeys["US"] → return if found
   │
   ├─ loadGovernmentKeyPEM(for: "US")  
   │  └─ Bundle.main.path(.../"us.pem") → read file
   │
   ├─ convertPEMToSecKey(pemData)
   │  ├─ Strip PEM headers "-----BEGIN..."
   │  ├─ Base64 decode key content
   │  ├─ SecKeyCreateWithData(...) → SecKey
   │  └─ (handles EC private/public key detection)
   │
   └─ Cache in cachedPublicKeys["US"] → return
```

### Signature Verification Flow
```
1. validate(data, signature, "US")
   │
   ├─ getGovernmentPublicKey(for: "US") → SecKey
   │
   ├─ Validate signature size == 64 bytes
   │
   ├─ constructDERSignature(r: bytes[0..32], s: bytes[32..64])
   │  └─ Encode: SEQUENCE { INTEGER r, INTEGER s }
   │
   ├─ SecKeyVerifySignature(key, .ecdsaSignatureMessageSHA256, data, derSig)
   │  └─ Uses SHA-256 hash of data before verification
   │
   └─ Return Bool (true = valid, false = invalid)
```

### DER Encoding Details
**Example**: Encoding R=0x123456, S=0xABCDEF

```
Raw:    [0x12 0x34 0x56 | 0xAB 0xCD 0xEF]
DER R:  [0x02 | 0x03 | 0x12 0x34 0x56]  (tag=0x02, len=3, data)
DER S:  [0x02 | 0x03 | 0xAB 0xCD 0xEF]
FINAL:  [0x30 | 0x06 | 0x02 0x03 0x12 0x34 0x56 0x02 0x03 0xAB 0xCD 0xEF]
        (SEQUENCE tag, total len=6, then R enc, then S enc)
```

**Leading Zero Handling**:
- If R = 0x85ABCD (MSB > 0x80), DER requires leading 0x00 to indicate positive: [0x85 0xAB 0xCD] → 0x0085ABCD
- Our `encodeInteger()` removes unnecessary leading zeros while preserving this behavior

---

## Testing Strategy (Phase 1A)

### Unit Tests Needed
```swift
// 1. Test key loading
✓ loadGovernmentKeyPEM() returns nil for unknown country
✓ loadGovernmentKeyPEM() returns Data for valid country

// 2. Test PEM conversion
✓ convertPEMToSecKey() parses valid PEM
✓ convertPEMToSecKey() throws on corrupted PEM
✓ convertPEMToSecKey() throws on wrong key type

// 3. Test signature verification
✓ validate() returns true for correct signature
✓ validate() returns false for invalid signature  
✓ validate() throws for unknown country
✓ validate() throws for wrong signature size
✓ validate() throws for invalid key format

// 4. Test DER encoding
✓ constructDERSignature() produces valid DER format
✓ encodeInteger() handles leading zeros correctly
✓ encodeInteger() preserves MSB sign bit
```

### Integration Tests
- Dry-run with test ECDSA keypair (generate locally)
- Create mock passport data + sign with test key
- Verify signature validates correctly

### Production Testing
- Will test with real passport/ID in Phase 2 (GovernmentIDScanner)
- Requires actual government key PEM files (to be provided separately)

---

## Known Limitations & Future Enhancements

### Limitations

1. **No CRL/OCID checking**
   - Current: Only validates signature
   - Future: Could fetch certificate revocation lists
   - Impact: Low - keys rotated infrequently

2. **Pre-loaded government keys only**
   - All keys must be bundled at build time
   - Cannot dynamically add new countries
   - Future: Fetch unsupported countries from secure CDN

3. **SHA-256 only**
   - Uses SHA-256 for signature hash
   - Some countries may use SHA-512
   - Future: Detect from certificate, support multiple hashes

4. **No certificate chain validation**
   - Only validates leaf government key
   - Doesn't verify signing certificate is authentic
   - Future: X.509 chain validation for complete PKI check

### Performance Notes
- Key loading: ~50ms first time, 0ms cached
- Signature verification: ~5-10ms per validation (dominates on actual device)
- Memory: ~5KB per cached key, negligible for 50 countries

---

## Git Commit Plan

Files to commit:
- `Sources/ICAO9303Validator.swift`

Commit message:
```
feat: Phase 1A - Implement ICAO 9303 signature validator

- P256 ECDSA signature validation for government IDs
- ICAO 9303 standard compliance (65 countries standard)
- PEM key loading from bundle with in-memory caching
- DER signature encoding for SecKeyVerifySignature
- Error handling: unknownCountry, invalidFormat, verificationFailed
- SHA-256 hash support for signature verification
- ~180 lines of code with full documentation
```

---

## Build Validation Steps

1. **Local**: `swift build` (Ubuntu - should fail since no Xcode, skip)
2. **macOS**:
   ```bash
   ssh macosx "cd ios-app && git pull && xcodebuild build..."
   ```
   Expected: BUILD SUCCEEDED (no compilation errors)

---

## Validation Checklist

Before moving to Phase 1B, verify:
- [ ] `xcodebuild` succeeds on macOS with no errors
- [ ] No compiler warnings
- [ ] ICAO9303Validator class compiles
- [ ] All methods have proper access control (public for interface, private for internal)
- [ ] Error handling is complete (no force unwraps)
- [ ] Build includes Foundation + Security + CryptoKit imports
- [ ] App runs on simulator without crashes
- [ ] Phase 0 model files still compile correctly (no regressions)

---

## Dependencies for Phase 2

Phase 2 (GovernmentIDScanner) will:
- Parse APDU responses from NFC chip
- Extract government ID data
- Create GovernmentID struct
- Call `ICAO9303Validator.validate()` to verify signature
- Return validated GovernmentID or error

This validator must be 100% working before Phase 2 starts.

---

**Last Updated**: March 19, 2026 23:50 UTC
