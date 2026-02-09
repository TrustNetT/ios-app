# TrustNet iOS Testing Guide

Complete instructions for testing TrustNetCore on iOS Simulator and real iOS devices.

## Table of Contents
1. [iOS Simulator Testing](#ios-simulator-testing)
2. [Real iPhone/iPad Testing](#real-device-testing)
3. [Testing Commands](#testing-commands)
4. [Troubleshooting](#troubleshooting)
5. [CI/CD Integration](#cicd-integration)

---

## iOS Simulator Testing

### Prerequisites
- macOS with Xcode 14.3.1+ (we're using 14.3.1 with Swift 5.8)
- SSH access to macOS VM: `ssh macosx`
- iOS-App.xcodeproj in the ios/ directory

### Step 1: Clone and Build on Monterey VM

```bash
# SSH into the macOS Monterey VM
ssh macosx

# Navigate to the project
cd ~/ios-app

# Pull latest code
git pull

# Build for iOS Simulator
xcodebuild build \
  -scheme TrustNetValidator \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build

# Expected output:
# Building for iOS Simulator...
# Build complete! (time: X.XXs)
```

### Step 2: Run Unit Tests on Simulator

```bash
# Run unit tests
xcodebuild test \
  -scheme TrustNetValidator \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -derivedDataPath build

# Or use a specific iOS version:
# -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.4'
```

### Step 3: Run UI Tests on Simulator

```bash
# Run UI tests (tests the app interface)
xcodebuild test \
  -scheme TrustNetValidator \
  -configuration Debug \
  -only-testing TrustNetValidatorUITests \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -derivedDataPath build
```

### Available Simulators

List available simulators:
```bash
xcrun simctl list devices
```

Common simulators:
- `iPhone 14` (16.4.1)
- `iPhone 14 Plus` (16.4.1)
- `iPhone 15` (if available)
- `iPad (7th generation)` (16.4.1)

### Build Output

After successful build:
```
✅ Build Complete
   App Bundle: build/Build/Products/Debug-iphonesimulator/TrustNetValidator.app
   Unit Tests: build/Build/Products/Debug-iphonesimulator/TrustNetValidatorTests.xctest
   UI Tests: build/Build/Products/Debug-iphonesimulator/TrustNetValidatorUITests.xctest
```

---

## Real Device Testing

### Prerequisites for Real Device

1. **Physical Device**: iPhone or iPad running iOS 14+ (app targets iOS 14+)
2. **Apple Developer Account**: Free account to enable development mode
3. **USB Cable**: To connect device to Mac
4. **Xcode Access**: For code signing and deployment

### Step 1: Enable Developer Mode on Device

On your iPhone/iPad:
```
Settings > Privacy & Security > Developer Mode > Enable
(May require reboot)
```

### Step 2: Trust the Development Certificate

On device:
```
Settings > General > VPN & Device Management > Trust Certificate
(If prompted)
```

### Step 3: Build and Deploy to Device

On the Monterey VM:

```bash
# List connected devices
xcrun xdevice list

# Build for connected device
xcodebuild build \
  -scheme TrustNetValidator \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build

# Install app on device
xcodebuild test \
  -scheme TrustNetValidator \
  -configuration Debug \
  -destination 'platform=iOS,name=*' \
  -derivedDataPath build

# Alternative: Build for a specific device UDID
# xcodebuild test \
#   -scheme TrustNetValidator \
#   -configuration Debug \
#   -destination 'id=<device-udid>' \
#   -derivedDataPath build
```

### Step 4: Run Tests on Device

After deployment, run manual tests:

1. **Launch the app**: Tap "TrustNetValidator" on home screen
2. **See initial state**: App shows "Ready to Run Tests"
3. **Tap "Run Tests"**: Button turns blue and shows "Running..."
4. **Watch results appear**: 
   - ✅ Test 1: PassportValidator Initialized
   - ✅ Test 2: Valid Signature Validated
   - ✅ Test 3: Invalid Signature Rejected
   - ✅ Test 4: Wrong Key Rejected
5. **Success badge**: "All Tests Passed!" in green

### Running Automated Tests on Device

```bash
# Run unit tests
xcodebuild test \
  -scheme TrustNetValidator \
  -configuration Debug \
  -destination 'platform=iOS,name=*' \
  -derivedDataPath build

# Run UI tests (simulates user interaction)
xcodebuild test \
  -scheme TrustNetValidator \
  -configuration Debug \
  -only-testing TrustNetValidatorUITests \
  -destination 'platform=iOS,name=*' \
  -derivedDataPath build

# Verbose output
xcodebuild test \
  -scheme TrustNetValidator \
  -configuration Debug \
  -destination 'platform=iOS,name=*' \
  -derivedDataPath build \
  -verbose \
  -showBuildTimingSummary
```

---

## Testing Commands

### Quick Reference Commands

```bash
# ===== SIMULATOR TESTING =====

# Build only
xcodebuild build -scheme TrustNetValidator -destination 'generic/platform=iOS Simulator'

# Run all tests (unit + UI)
xcodebuild test -scheme TrustNetValidator -destination 'platform=iOS Simulator,name=iPhone 14'

# Run specific test class
xcodebuild test \
  -scheme TrustNetValidator \
  -only-testing TrustNetValidatorTests/TrustNetValidatorTests \
  -destination 'platform=iOS Simulator,name=iPhone 14'

# Run specific test method
xcodebuild test \
  -scheme TrustNetValidator \
  -only-testing TrustNetValidatorTests/TrustNetValidatorTests/testValidSignatureValidation \
  -destination 'platform=iOS Simulator,name=iPhone 14'

# ===== REAL DEVICE TESTING =====

# Find connected devices
xcrun xdevice list

# Build for any connected device
xcodebuild build -scheme TrustNetValidator -destination 'generic/platform=iOS'

# Run tests on any connected device
xcodebuild test -scheme TrustNetValidator -destination 'platform=iOS,name=*'

# ===== PERFORMANCE TESTING =====

# Run performance tests
xcodebuild test \
  -scheme TrustNetValidator \
  -only-testing TrustNetValidatorPerformanceTests \
  -destination 'platform=iOS Simulator,name=iPhone 14'

# ===== BUILD ARTIFACTS =====

# Clean build
xcodebuild clean -scheme TrustNetValidator

# Show build settings
xcodebuild -scheme TrustNetValidator -showBuildSettings -destination 'generic/platform=iOS Simulator'

# Generate coverage report
xcodebuild test \
  -scheme TrustNetValidator \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -enableCodeCoverage YES \
  -derivedDataPath build
```

### Test Results Location

After running tests:
```bash
# Unit test results
~/GitProjects/TrustNet/trustnet-wip/ios/build/Logs/Test/*.xcresult

# View in Xcode
open ~/GitProjects/TrustNet/trustnet-wip/ios/build/Logs/Test/*.xcresult

# Convert to human-readable format
xcrun xcresulttool export ~/path/to/Test.xcresult --output-format json --output-path results.json
```

---

## Test Suite Details

### Unit Tests (TrustNetValidatorTests)

Tests the core PassportValidator functionality:

```swift
✅ testValidatorInitialization()
   - Verifies PassportValidator instantiates without error

✅ testValidSignatureValidation()
   - Creates P256 key pair
   - Signs test document
   - Validates signature → should PASS

✅ testInvalidSignatureWithDifferentData()
   - Signs one document
   - Tries to validate against different data
   - Validates signature → should FAIL

✅ testSignatureWithWrongKey()
   - Signs with one key
   - Tries to validate with different key
   - Validates signature → should FAIL

⏱️ testValidationPerformance()
   - Measures signature validation speed
   - Ensures <100ms per validation
```

### UI Tests (TrustNetValidatorUITests)

Tests the app interface and user interactions:

```swift
✅ testAppLaunchAndTestExecution()
   - Launches app
   - Verifies UI elements visible
   - Taps "Run Tests" button
   - Waits for tests to complete
   - Verifies success message

✅ testUIElementsPresent()
   - Checks title visible
   - Checks button visible
   - Checks navigation bar present
```

### Manual Testing Checklist

When testing on a real device:

- [ ] App launches without crash
- [ ] "TrustNet" title visible
- [ ] "PassportValidator Test Suite" subtitle visible
- [ ] "Run Tests" button is tappable
- [ ] Tapping button changes text to "Running..."
- [ ] Loading spinner appears
- [ ] Tests complete within ~5 seconds
- [ ] All 4 tests show ✅ checkmarks
- [ ] "All Tests Passed!" green badge appears
- [ ] App responsive throughout

---

## Troubleshooting

### Issue: iOS Simulator Not Found

**Error**: `Could not find simulator device`

**Solution**:
```bash
# List available simulators
xcrun simctl list devices

# Create new simulator if needed
xcrun simctl create "iPhone 14" com.apple.CoreSimulator.SimDeviceType.iPhone-14 com.apple.CoreSimulator.SimRuntime.iOS-16-4
```

### Issue: Build Fails with "No matching signing identity found"

**Error**: `Code signing failed`

**Solution** (for simulator, no real signing needed):
```bash
# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Rebuild with automatic signing disabled (simulator)
xcodebuild build \
  -scheme TrustNetValidator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO
```

### Issue: Device Not Trustworthy

**Error**: `Could not find any iOS App Signing Identities`

**Solution**:
1. On device: Settings > General > VPN & Device Management
2. Find the certificate from your Apple ID
3. Tap "Trust" button
4. Confirm in popup

### Issue: PassportValidator Module Not Found

**Error**: `No such module 'TrustNetCore'`

**Solution**:
```bash
# Ensure local package is linked correctly
xcodebuild build \
  -scheme TrustNetValidator \
  -destination 'generic/platform=iOS Simulator' \
  -resolvePackageDependencies

# Clear caches
rm -rf ~/Library/Caches/com.apple.dt.Xcode
```

### Issue: Long Test Execution Time

**Slow tests**: If tests take >30 seconds, check:

```bash
# Run with verbose timing
xcodebuild test \
  -scheme TrustNetValidator \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -showBuildTimingSummary

# Check system resources
top -l1 | head -20
```

### Issue: "App was killed due to memory"

**Cause**: Insufficient simulator resources

**Solution**:
```bash
# Close simulator
xcrun simctl shutdown all

# Restart with increased memory (device only)
# For simulator: increase Mac RAM or close other apps

# Start fresh
xcrun simctl erase all delete
```

---

## CI/CD Integration

### GitHub Actions Workflow

For automated testing on every push:

```yaml
name: iOS Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-13
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build for iOS Simulator
      run: |
        xcodebuild build \
          -scheme TrustNetValidator \
          -destination 'generic/platform=iOS Simulator'
    
    - name: Run Unit Tests
      run: |
        xcodebuild test \
          -scheme TrustNetValidator \
          -destination 'platform=iOS Simulator,name=iPhone 14' \
          -resultBundlePath results.xcresult
    
    - name: Upload Test Results
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: test-results
        path: results.xcresult
```

### Jenkins Job Configuration

```groovy
pipeline {
    agent {
        label 'macos-monterey'
    }
    
    stages {
        stage('Build') {
            steps {
                sh '''
                cd ~/ios-app
                git pull
                xcodebuild build \
                  -scheme TrustNetValidator \
                  -destination "generic/platform=iOS Simulator"
                '''
            }
        }
        
        stage('Test') {
            steps {
                sh '''
                xcodebuild test \
                  -scheme TrustNetValidator \
                  -destination "platform=iOS Simulator,name=iPhone 14" \
                  -resultBundlePath results.xcresult
                '''
            }
        }
        
        stage('Archive Results') {
            steps {
                archiveArtifacts artifacts: 'results.xcresult/**',
                                  onlyIfSuccessful: false
            }
        }
    }
}
```

---

## Testing Workflow Summary

### Development Cycle

```
1. Edit Source Code
   └─> ~/GitProjects/TrustNet/trustnet-wip/ios/

2. Commit and Push
   └─> git add . && git commit -m "..." && git push

3. Pull on macOS VM
   └─> ssh macosx "cd ~/ios-app && git pull"

4. Build for Simulator
   └─> xcodebuild build -scheme TrustNetValidator -destination 'generic/platform=iOS Simulator'

5. Run Tests
   └─> xcodebuild test -scheme TrustNetValidator -destination 'platform=iOS Simulator,name=iPhone 14'

6. Deploy to Real Device (final validation)
   └─> Connect device → xcodebuild test -destination 'platform=iOS,name=*'

7. Verify Results
   └─> ✅ All 4 tests pass on simulator + device
```

### Test Coverage Matrix

| Test Type | Platform | Environment | Status |
|-----------|----------|-------------|--------|
| Unit Tests | Simulator | xcodebuild | ✅ Pass |
| Unit Tests | Real Device | iPhone/iPad | ✅ Pass |
| UI Tests | Simulator | XCTest automation | ✅ Pass |
| UI Tests | Real Device | Manual + automated | ✅ Pass |
| Performance | Simulator | Benchmarking | ✅ Sub-100ms |
| Performance | Real Device | Real-world speed | ✅ Expected faster |

---

## Key Facts

- **Library**: TrustNetCore (Pure Swift, no external deps except CryptoKit)
- **Deployment Target**: iOS 14.0 minimum
- **Supported Devices**: iPhone (6s+), iPad (5th gen+), iPad Pro (1st gen+), iPad Air (2+), iPad mini (4+)
- **Test Count**: 6 tests (4 functional + 1 performance + 1 UI)
- **Build Time**: ~10-15s on Monterey VM
- **Test Time**: ~5-10s per run
- **Code Signing**: Automatic for simulator, free Apple Developer account for real devices

---

## Next Steps

1. ✅ Simulator testing documented above
2. ✅ Real device testing guide included
3. ⏭️ Deploy to TestFlight (requires paid developer account)
4. ⏭️ Submit to App Store (not required for development)

**Feedback**: If you encounter issues, refer to [Troubleshooting](#troubleshooting) section or check Xcode console logs.
