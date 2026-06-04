# Phase 0: Data Models & Errors - Technical Notes

**Date**: March 19, 2026  
**Status**: Implementation In Progress  
**Internal Documentation Only** - Not for public repository

---

## Implementation Summary

Created foundational data structures that all other registration components depend on.

### Files Created
1. **Sources/Models.swift** (347 lines)
   - Core data structures for registration flow
   - Immutable structs for data integrity
   - Codable for persistence/serialization

2. **Sources/Errors.swift** (209 lines)
   - Complete error type hierarchy
   - LocalizedError for user-facing messages
   - Recovery suggestions for each error

---

## Data Model Architecture

### Dependency Chain
```
GovernmentID (NFC input)
    ↓
BiometricHash (derived from photo)
    ↓
User (combines all identity data)
    ↓
IdentityVerification (immutable state tracking)
    ↓
RegistrationState (state machine for flow)
```

### Key Design Decisions

1. **GovernmentID struct**
   - Contains raw NFC data + government signature
   - `isValid` flag set after signature validation
   - `idPhoto: Data?` optional for biometric processing
   - Codable for potential storage

2. **BiometricHash struct**
   - Pure hash (never stores raw biometric data)
   - Privacy-preserving design per ICAO 9303
   - Includes timestamp for audit trail

3. **User struct**
   - Combines government ID + biometric hash + cryptographic keys
   - Immutable after creation (all `let` properties)
   - Tracks blockchain registration status
   - Hashable for collection usage

4. **IdentityVerification struct**
   - Tracks verification state at each step
   - Timestamps for audit trail
   - Immutable - reflects historical verification state

5. **RegistrationState enum**
   - State machine with associated values
   - `.complete(User)` carries registered user
   - `.error(RegistrationError)` carries error details
   - `description` property for UI state display

6. **RegistrationError enum**
   - 14 specific error cases
   - LocalizedError protocol for user messages
   - Recovery suggestions for each error
   - Equatable for testing

---

## Swift Version Compatibility

- **Target**: iOS 14.0+
- **Swift**: 6.0+ (Swift 6 features)
- **Frameworks**: Foundation only (no external deps at this stage)
- **Codable**: Built-in support for all structs/enums

---

## Testing Strategy

### Unit Test Coverage Needed
- [ ] GovernmentID initialization
- [ ] BiometricHash generation consistency
- [ ] User struct creation
- [ ] IdentityVerification state transitions
- [ ] RegistrationState state machine logic
- [ ] RegistrationError localization

### Validation Approach
1. Ensure code compiles without warnings
2. Manual instantiation of each struct/enum
3. Verify Codable serialization/deserialization
4. Check LocalizedError messages render correctly

---

## Next Phase Dependencies

All following phases depend on these models:
- **Phase 1A**: ICAO9303Validator uses `GovernmentID`
- **Phase 1B**: BiometricHasher creates `BiometricHash`
- **Phase 1C**: KeyGenerator creates `User`
- **Phase 2**: GovernmentIDScanner returns `GovernmentID`
- **Phase 3**: RegistrationManager orchestrates using `RegistrationState`

---

## Known Limitations / Future Enhancements

1. **Codable serialization**: No encryption at this stage
   - Should use Keychain for sensitive data in Phase 1D

2. **Error recovery**: Basic error handling
   - Could add retry logic in Phase 3

3. **Biometric hash algorithm**: SHA-256
   - Could use more advanced algorithms later

4. **User equality**: Based on all properties
   - May need to refine for comparing registrations

---

## Build Validation

```bash
# Local validation
cd ~/GitProjects/TrustNet/trustnet-wip/ios
swift build

# macOS validation
ssh macosx "cd ios-app && xcodebuild build -scheme TrustNetValidator -configuration Debug -destination 'generic/platform=iOS Simulator'"
```

---

## Git Checkpoint

Files to commit:
- `Sources/Models.swift`
- `Sources/Errors.swift`

Commit message:
```
feat: Phase 0 - Add data models and error types for registration flow

- GovernmentID: NFC scan data with signature validation flag
- BiometricHash: Privacy-preserving facial geometry hash
- User: Complete identity after registration
- IdentityVerification: Immutable state tracking per step
- RegistrationState: State machine enum for flow control
- RegistrationError: 14 error cases with LocalizedError support
```

---

## Validation Checklist

Before moving to Phase 1, verify:
- [ ] `swift build` succeeds without warnings
- [ ] All structs initialize correctly
- [ ] All enums have proper associated values
- [ ] LocalizedError messages are clear
- [ ] Codable serialization works (if tested)
- [ ] `xcodebuild` succeeds on macOS
- [ ] No compiler errors on macOS Xcode build
- [ ] App runs on simulator without crashes

---

**Last Updated**: March 19, 2026 23:45 UTC
