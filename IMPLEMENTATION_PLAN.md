# iOS Registration Implementation Plan

**Date**: March 19, 2026  
**Status**: Planning Phase  
**Methodology**: Incremental implementation with validation checkpoints - NO working code modified

---

## Dependency Graph

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 0: DATA MODELS (Foundation - all others depend on)    │
├─────────────────────────────────────────────────────────────┤
│ ✓ Models.swift (GovernmentID, RegistrationState, User)     │
│ ✓ Errors.swift (Error types for validation)                │
└──────┬──────────────────────────────────────────────────────┘
       │
       ├──────────────────────┬──────────────────┬──────────────┐
       │                      │                  │              │
┌──────▼──────┐      ┌────────▼────┐    ┌───────▼──────┐   ┌──▼─────────┐
│ PHASE 1A    │      │ PHASE 1B    │    │ PHASE 1C     │   │ PHASE 1D   │
│ ICAO Val    │      │ Biometric   │    │ Key Gen      │   │ Keychain   │
│ Validator   │      │ Hasher      │    │              │   │ Manager    │
└─────────────┘      └─────────────┘    └──────────────┘   └────────────┘
       │
       ├──────────────────────┐
       │                      │
┌──────▼────────────┐   ┌─────▼──────────────┐
│ PHASE 2           │   │ PHASE 3            │
│ NFC Scanner       │   │ Blockchain         │
│ (uses validator)  │   │ Connector          │
└──────┬────────────┘   └────────────────────┘
       │
       └──────────────┬──────────────────────┐
                      │                      │
             ┌────────▼──┐         ┌─────────▼─────────┐
             │ PHASE 4   │         │ PHASE 5           │
             │ State     │         │ Integration:      │
             │ Manager   │         │ RegistrationView  │
             └───────────┘         └───────────────────┘
```

---

## Implementation Phases (Detailed Order)

### PHASE 0: Data Models & Error Handling
**Dependencies**: None (Foundation)  
**Objective**: Define data structures that all other components depend on

#### Tasks
- [ ] Create `Models.swift`
  - [ ] `GovernmentID` struct (name, dob, document number, biometric template, signature, validity)
  - [ ] `User` struct (userID, governmentID, biometric hash, public key, private key, registration status)
  - [ ] `RegistrationState` enum (idle, scanning, validating, hashing, generatingKeys, registering, complete, error)
  - [ ] `IdentityVerification` struct (all immutable, hashable)
- [ ] Create `Errors.swift`
  - [ ] `RegistrationError` enum (nfcNotAvailable, scanFailed, invalidSignature, biometricFailed, keyGenerationFailed, blockchainFailed, storageError)
  - [ ] Custom error messages

**Validation Checkpoint 0**:
- [ ] Code compiles without errors
- [ ] All structs properly initialized
- [ ] Enums match all error cases

---

### PHASE 1A: ICAO 9303 Validator
**Dependencies**: Models.swift  
**Objective**: Validate government ID signatures using ECDSA P256

#### Tasks
- [ ] Create `ICAO9303Validator.swift`
  - [ ] Load government public keys from bundle (US, GB, DE, etc.)
  - [ ] `validate(data: Data, signature: Data, countryCode: String) -> Bool` function
  - [ ] Use SecKeyVerifySignature with P256 ECDSA
  - [ ] Handle key loading errors gracefully

**Validation Checkpoint 1A**:
- [ ] Code compiles without errors
- [ ] Can load PEM format government keys
- [ ] Signature validation works with test data
- [ ] Error handling for missing keys

---

### PHASE 1B: Biometric Hasher
**Dependencies**: Models.swift  
**Objective**: Extract and hash facial geometry from government ID photos

#### Tasks
- [ ] Create `BiometricHasher.swift`
  - [ ] Use Vision framework to detect face landmarks
  - [ ] Extract facial geometry points (eye distance, nose position, etc.)
  - [ ] SHA-256 hash the geometry data
  - [ ] Return hashable biometric representation

**Validation Checkpoint 1B**:
- [ ] Code compiles without errors
- [ ] Can process sample image data
- [ ] Generates consistent hash for same biometric data
- [ ] Different biometrics produce different hashes

---

### PHASE 1C: Key Generator
**Dependencies**: Models.swift  
**Objective**: Generate cryptographic keypairs for user identity

#### Tasks
- [ ] Create `KeyGenerator.swift`
  - [ ] Generate P256 keypairs using CryptoKit
  - [ ] Create `UserID` by combining: biometric hash + public key + timestamp
  - [ ] Return (privateKey, publicKey, userID) tuple
  - [ ] Handle key generation failures

**Validation Checkpoint 1C**:
- [ ] Code compiles without errors
- [ ] Generates valid P256 keypairs
- [ ] UserID is consistent and unique
- [ ] Private key is not exposed in UserID

---

### PHASE 1D: Keychain Manager
**Dependencies**: Models.swift  
**Objective**: Securely store and retrieve cryptographic keys

#### Tasks
- [ ] Create `KeychainManager.swift`
  - [ ] Store privateKey securely in Keychain
  - [ ] Store publicKey in UserDefaults (public data)
  - [ ] Store UserID in UserDefaults
  - [ ] `retrievePrivateKey() -> SecKey?` function
  - [ ] `retrieveUserID() -> String?` function
  - [ ] `clearAllData()` for logout

**Validation Checkpoint 1D**:
- [ ] Code compiles without errors
- [ ] Can store and retrieve keys
- [ ] Data persists across app restarts
- [ ] Clear function removes all data

---

### PHASE 2: NFC Government ID Scanner
**Dependencies**: Models.swift, ICAO9303Validator.swift  
**Objective**: Read government ID via NFC and validate passport data

#### Tasks
- [ ] Create `GovernmentIDScanner.swift`
  - [ ] Implement `NFCTagReaderSessionDelegate`
  - [ ] `startScan(completion:)` function
  - [ ] Read APDU responses for ICAO 9303 data
  - [ ] Extract: name, DOB, document number, biometric template, signature
  - [ ] Call ICAO9303Validator to verify signature
  - [ ] Return validated `GovernmentID` object or error

**Validation Checkpoint 2**:
- [ ] Code compiles without errors
- [ ] Can initiate NFC session
- [ ] Device recognizes NFC capability
- [ ] Raw APDU reading works (test with real passport on macOS)
- [ ] Validator called correctly
- [ ] Returns GovernmentID or error appropriately

---

### PHASE 1B: Blockchain Connector (Independent)
**Dependencies**: Models.swift  
**Objective**: Connect to TrustNet blockchain and submit registration

#### Tasks
- [ ] Create `BlockchainConnector.swift`
  - [ ] Initialize connection to blockchain node (localhost:26657 or remote)
  - [ ] `submitRegistration(userID: String, publicKey: Data) -> Bool` function
  - [ ] Create transaction payload
  - [ ] Handle blockchain errors
  - [ ] Return success/failure

**Validation Checkpoint 1B-alt**:
- [ ] Code compiles without errors
- [ ] Can connect to blockchain node
- [ ] Can submit test transaction
- [ ] Returns success/failure correctly

---

### PHASE 3: Registration State Manager
**Dependencies**: Models.swift, all Phase 1 components, GovernmentIDScanner  
**Objective**: Orchestrate the complete registration flow

#### Tasks
- [ ] Create `RegistrationManager.swift`
  - [ ] Manage flow: scan → validate → hash → generate keys → store → blockchain
  - [ ] Update `RegistrationState` at each step
  - [ ] Call each component in correct order
  - [ ] Handle failures at each stage
  - [ ] Return final registration result

**Validation Checkpoint 3**:
- [ ] Code compiles without errors
- [ ] State transitions work correctly
- [ ] Error at any step is handled properly
- [ ] Can trace complete flow with logging

---

### PHASE 4: Integration & UI Updates
**Dependencies**: All previous phases  
**Objective**: Wire up RegistrationView to use NFC registration flow

#### Tasks
- [ ] Update `RegistrationView.swift`
  - [ ] Remove email/password form (DEPRECATED)
  - [ ] Add "Scan Government ID with NFC" button
  - [ ] Show registration state (scanning, validating, etc.)
  - [ ] Call RegistrationManager to start flow
  - [ ] Handle completion (success → show dashboard, error → show error)
- [ ] Update `App.swift` to check for registered UserID
  - [ ] If UserID exists in Keychain → show dashboard
  - [ ] If no UserID → show registration

**Validation Checkpoint 4**:
- [ ] Code compiles without errors
- [ ] App builds and runs on simulator
- [ ] Registration button appears
- [ ] Flows navigate correctly (registration → dashboard)
- [ ] No crashes or runtime errors

---

## Checkpoint Validation Protocol

**For each checkpoint, do NOT proceed to next phase unless:**

1. **Code Quality**
   - [ ] Swift code compiles without warnings
   - [ ] No force unwraps or crash-prone patterns
   - [ ] Proper error handling (no `fatalError`)

2. **Unit Testing** (if applicable)
   - [ ] Component works in isolation
   - [ ] Test with sample/mock data
   - [ ] Error cases handled

3. **Integration Testing**
   - [ ] Component integrates with previous phase
   - [ ] Data flows correctly between components
   - [ ] No data corruption or loss

4. **Build Validation**
   - [ ] `xcodebuild` succeeds on macOS
   - [ ] App runs on iPhone 14 Pro Max simulator
   - [ ] No crashes during component usage

5. **Git Checkpoint**
   - [ ] Commit: `git add . && git commit -m "feat: Phase X - [component name]"`
   - [ ] Push: `git push origin main`
   - [ ] Pull on macOS and rebuild: `ssh macosx "cd ios-app && git pull && xcodebuild build..."`

---

## Testing Strategy

### Phase 0-1: Unit Tests
- Models initialize correctly
- Validators work with test data
- Keys generate properly
- Keychain stores/retrieves correctly

### Phase 2: Real Device Testing
- NFC reading on actual iPhone (requires registered developer)
- Passport data extraction works
- Signature validation with real government keys

### Phase 3-4: Integration Testing
- End-to-end flow works
- State transitions correct
- Blockchain submission succeeds
- UI updates properly

---

## Rollback Plan

If any checkpoint fails:
1. **Immediately stop** proceeding to next phase
2. **Debug** within current phase only
3. **Revert** last commit if necessary: `git revert HEAD`
4. **Fix** the issue in isolated component
5. **Re-validate** checkpoint before proceeding
6. **New commit**: `git commit -m "fix: Phase X - [description]"`

**Never modify** passing code in previous phases.

---

## Success Criteria

✅ Registration flow complete when:
- [ ] User taps "Scan Government ID"
- [ ] App reads NFC passport/ID successfully
- [ ] Signature validated against government key
- [ ] Biometric hash generated from photo
- [ ] P256 keypair created
- [ ] UserID stored in Keychain
- [ ] Registration submitted to blockchain
- [ ] User navigated to dashboard
- [ ] Subsequent app launches check Keychain and go directly to dashboard

---

## Estimated Timeline

- **Phase 0**: 30 min (Models are simple structs)
- **Phase 1A-1D**: 2-3 hours each (4-5 components, mostly independent)
- **Phase 2**: 2-3 hours (NFC requires device testing)
- **Phase 3**: 1-2 hours (Orchestration/state management)
- **Phase 4**: 1 hour (UI integration)

**Total**: ~15-20 hours (spread across sessions with validation checkpoints)

---

## Next Steps

1. ✅ You review this plan
2. ✅ Confirm order makes sense (ask questions if not)
3. We start **Phase 0** and validate before moving to Phase 1
4. After each phase passes checkpoint → commit → push → macOS pull & build
5. No code changes except in current phase

Ready to start Phase 0?
