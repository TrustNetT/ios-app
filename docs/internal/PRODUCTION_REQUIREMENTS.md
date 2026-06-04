# Production Requirements Checklist

**Date Created**: March 19, 2026  
**Status**: PRE-PRODUCTION PLANNING  
**Scope**: Requirements that must be implemented BEFORE shipping to App Store

---

## Code Signing & Distribution

### ⚠️ CRITICAL: Code Signing (Currently Disabled for Development)

**Current Status (Development)**:

```bash
CODE_SIGN_IDENTITY=''           # DISABLED - Development builds only
CODE_SIGNING_REQUIRED=NO        # DISABLED - Development builds only
```

**Why disabled now**:

- Development phase requires rapid iteration without certificate setup
- Local validation on macOS to verify Swift compilation
- No distribution or end-user access

**What MUST be configured for production**:

1. **Apple Developer Account & Team ID**
   - Register team ID: `TEAM_ID` from Apple Developer Program
   - Create development certificate: Personal Identity Verification (PIV)
   - Create distribution certificate: for App Store distribution

2. **Code Signing Identity**
   ```bash
   # Production build requires:
   CODE_SIGN_IDENTITY="Apple Distribution: Your Company Name (TEAM_ID)"
   CODE_SIGNING_REQUIRED=YES
   ```

3. **Provisioning Profiles**
   - Development provisioning profile: For TestFlight testing
   - App Store distribution profile: For App Store release
   - Must be downloaded from Apple Developer portal
   - Bundled in app or referenced in Xcode project

4. **Build Configuration**
   ```swift
   // In Xcode project settings:
   DEVELOPMENT_TEAM = TEAM_ID
   CODE_SIGN_STYLE = Automatic (or Manual)
   PROVISIONING_PROFILE_SPECIFIER = "App Store Provisioning Profile"
   ```

5. **Jenkinsfile Updates** (when CI/CD is enabled)
   ```groovy
   // Extract signing credentials from Jenkins
   withCredentials([
       file(credentialsId: 'ios-app-signing-cert', variable: 'CERT_FILE'),
       string(credentialsId: 'ios-provisioning-profile', variable: 'PROFILE'),
       string(credentialsId: 'apple-team-id', variable: 'TEAM_ID')
   ]) {
       sh '''
       # Configure signing
       xcodebuild build -scheme TrustNetValidator \\
           -configuration Release \\
           CODE_SIGN_IDENTITY="Apple Distribution:..." \\
           CODE_SIGNING_REQUIRED=YES \\
           PROVISIONING_PROFILE_SPECIFIER="$PROFILE"
       '''
   }
   ```

### Timeline for Code Signing Implementation

**Phase 4 (UI Integration)**:
- [ ] Set up Apple Developer account
- [ ] Create team and certificates
- [ ] Generate provisioning profiles
- [ ] Configure Xcode project signing settings
- [ ] Update Jenkinsfile with credentials

**Before App Store Submission**:
- [ ] Test code signing locally on macOS
- [ ] Verify provisioning profiles load correctly
- [ ] Build signed release version
- [ ] Test on physical device (unsigned builds won't run on real device)

---

## Other Production Requirements

### App Store Compliance

1. **Privacy Policy**
   - Required before submission
   - Document all biometric data handling
   - Link in App Store Connect

2. **Terms of Service**
   - Required for user acceptance
   - Include blockchain registration terms
   - Government ID usage disclosure

3. **Data Protection & GDPR**
   - Biometric data: Never stored raw (only hash) ✅ Already designed
   - User data: Encrypted in transit and at rest
   - CCPA compliance for California users

4. **Security Requirements**
   - Code signing ⚠️ Must implement
   - Transport security (TLS 1.2+) - Mandatory by Apple
   - Keychain usage for sensitive data ✅ In Phase 1D
   - No hardcoded secrets ✅ Using Keychain

### Testing Requirements

1. **Device Testing**
   - Must test on physical iOS device (not simulator for NFC)
   - NFC: Requires iPhone 7+ with NFC capability
   - Face ID/Touch ID: Test on supported devices

2. **Biometric Testing**
   - Test with multiple face angles
   - Test with glasses/sunglasses scenarios
   - Test edge cases: poor lighting, makeup, etc.

3. **Blockchain Integration**
   - Test transaction confirmation flow
   - Test network failure recovery
   - Test duplicate registration prevention

---

## Security Checklist for Production

- [ ] Code signing configured with App Store certificates
- [ ] All API keys in Keychain (never hardcoded)
- [ ] Blockchain RPC endpoint uses HTTPS only
- [ ] NFC data validated before use
- [ ] Biometric data hashed, never stored raw
- [ ] No debug logging in production builds
- [ ] All network requests use certificate pinning (optional but recommended)
- [ ] App permission requests: Privacy descriptions for NFC, Camera, Keychain

---

## Deployment Pipeline

### Before TestFlight Beta
- [ ] Code signing functioning
- [ ] All tests passing
- [ ] Beta testers identified
- [ ] Crash reporting configured (e.g., Sentry, Firebase)

### Before App Store Release
- [ ] All production code signed
- [ ] Privacy policy live
- [ ] Terms of service live
- [ ] App Store Connect fully configured
- [ ] Screenshots, description, keywords ready
- [ ] Age rating questionnaire completed
- [ ] Content rights verified (government ID images for testing)

---

## Credentials Management

All production credentials stored in **Jenkins** (never in code or .env):
- Apple signing certificate (`.p8` file)
- Apple provisioning profiles
- Apple team ID
- Blockchain testnet/mainnet RPC key
- GitHub container registry token

**Access**: Only on macOS VM during CI/CD build, never extracted to files.

---

## Future Enhancements (Post-MVP)

1. Liveness detection (prevent spoofing with printed face)
2. Additional biometric modalities (iris, fingerprint)
3. Hardware security module support
4. Cross-platform Android version
5. Web-based registration backup

---

**Last Updated**: March 19, 2026  
**Next Review**: Before Phase 4 (UI Integration)
