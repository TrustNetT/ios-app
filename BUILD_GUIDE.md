# iOS App Build & Deployment Guide

Complete setup and build instructions for TrustNetValidator iOS app.

## Quick Start

### Build for iOS Simulator

```bash
# SSH to macOS VM
ssh macosx

# Navigate to project
cd ~/ios-app

# Build for simulator
xcodebuild build \
  -scheme TrustNetValidator \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator'

# Expected: Build complete! (10-15 seconds)
```

### Build for Real Device

```bash
# Connect iPhone/iPad via USB

# Build for device
xcodebuild build \
  -scheme TrustNetValidator \
  -configuration Debug \
  -destination 'generic/platform=iOS'

# Or target specific device:
xcodebuild build \
  -scheme TrustNetValidator \
  -configuration Release \
  -destination 'platform=iOS,name=iPhone 14'
```

## Project Structure

```
ios-app/
├── Package.swift                 # SPM manifest (defines TrustNetCore library)
├── Sources/
│   ├── PassportValidator.swift   # Core library (P256 ECDSA validation)
│   ├── App.swift                 # SwiftUI app entry point
│   └── ContentView.swift         # Main UI (test runner)
├── Tests/
│   ├── main.swift               # CLI test executable
│   ├── PassportValidatorTests.swift  # XCTest unit tests (legacy)
├── TrustNetValidator/            # iOS app (Xcode project)
│   ├── App.swift                # SwiftUI @main
│   └── ContentView.swift        # Test UI interface
├── TrustNetValidatorTests/       # Unit test target
│   └── TrustNetValidatorTests.swift
├── TrustNetValidatorUITests/     # UI automation tests
│   ├── TrustNetValidatorUITests.swift
│   └── TrustNetValidatorUITestsLaunchTests.swift
├── iOS-App.xcodeproj/            # Xcode project (build with this)
│   └── project.pbxproj          # Project configuration
└── TESTING_GUIDE.md             # This file's bigger sibling
```

## Building in Xcode (GUI)

### Option 1: Open in Xcode GUI

```bash
ssh macosx
cd ~/ios-app

# Open Xcode project
open iOS-App.xcodeproj
```

Then in Xcode UI:
1. Select scheme: `TrustNetValidator`
2. Select destination: 
   - Simulator: `iPhone 14` (or any simulator)
   - Device: Your connected iPhone/iPad
3. Product > Build (⌘B)
4. Product > Run (⌘R) to launch app

### Option 2: Command-line Build

#### Debug Configuration (Simulator)

```bash
xcodebuild build \
  -project iOS-App.xcodeproj \
  -scheme TrustNetValidator \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build
```

#### Release Configuration (Device)

```bash
xcodebuild build \
  -project iOS-App.xcodeproj \
  -scheme TrustNetValidator \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build
```

## Build Outputs

After successful build:

```
build/Build/Products/
├── Debug-iphonesimulator/
│   ├── TrustNetValidator.app/        # Simulator app bundle
│   ├── TrustNetValidatorTests.xctest/
│   └── TrustNetValidatorUITests.xctest/
└── Debug-iphoneos/
    ├── TrustNetValidator.app/        # Device app bundle
    ├── TrustNetValidatorTests.xctest/
    └── TrustNetValidatorUITests.xctest/
```

### Run App Binary Directly

```bash
# Simulator
open build/Build/Products/Debug-iphonesimulator/TrustNetValidator.app

# Device (via Xcode)
xcodebuild install \
  -project iOS-App.xcodeproj \
  -scheme TrustNetValidator \
  -configuration Debug \
  -destination 'generic/platform=iOS'
```

## Testing

### Run All Tests

```bash
xcodebuild test \
  -scheme TrustNetValidator \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -derivedDataPath build \
  -verbose
```

### Run Specific Test Target

```bash
# Unit tests only
xcodebuild test \
  -scheme TrustNetValidator \
  -only-testing TrustNetValidatorTests \
  -destination 'platform=iOS Simulator,name=iPhone 14'

# UI tests only
xcodebuild test \
  -scheme TrustNetValidator \
  -only-testing TrustNetValidatorUITests \
  -destination 'platform=iOS Simulator,name=iPhone 14'
```

### Run Specific Test

```bash
xcodebuild test \
  -scheme TrustNetValidator \
  -only-testing TrustNetValidatorTests/TrustNetValidatorTests/testValidSignatureValidation \
  -destination 'platform=iOS Simulator,name=iPhone 14'
```

## Xcode Project Configuration

### Targets

1. **TrustNetValidator** (Main App)
   - Product: `TrustNetValidator.app`
   - Type: iOS Application
   - Minimum iOS: 14.0
   - Supported Devices: iPhone, iPad

2. **TrustNetValidatorTests** (Unit Tests)
   - Product: `TrustNetValidatorTests.xctest`
   - Type: Unit Test Bundle
   - Tests: 4 unit tests + 1 performance test
   - Host App: TrustNetValidator

3. **TrustNetValidatorUITests** (UI Tests)
   - Product: `TrustNetValidatorUITests.xctest`
   - Type: UI Test Bundle
   - Tests: UI automation tests
   - Host App: TrustNetValidator

### Build Settings

**TrustNetValidator Target**:
```
Product Name: TrustNetValidator
Bundle Identifier: com.trustnet.validator
Version: 1.0
Build: 1
iOS Deployment Target: 14.0
Swift Language Version: 5.0
Code Sign Style: Automatic
```

**Package Dependencies**:
- TrustNetCore (local Swift package from Package.swift)

## Version Management

### Update Build Number

```bash
agvtool next-version
# Or manually:
agvtool new-version -all 2
```

### Update Marketing Version

```bash
agvtool next-marketing-version
# Or manually:
agvtool new-marketing-version 1.1
```

## Xcode Schemes

Schemes defined in iOS-App.xcodeproj:

- `TrustNetValidator` (Main app scheme)
  - Build: All targets
  - Tests: TrustNetValidatorTests + TrustNetValidatorUITests
  - Run: App (Debug config)
  - Archive: All tests + release binary

## Package Resolution

TrustNetCore is resolved as a local Swift package:

```swift
// Package.swift references local path
products: [
    .library(name: "TrustNetCore", targets: ["TrustNetCore"]),
]
```

To verify package is resolved:

```bash
xcodebuild -resolvePackageDependencies \
  -project iOS-App.xcodeproj \
  -scheme TrustNetValidator
```

## Device Provisioning

### Automatic (Free Account)

Xcode can sign automatically:

1. Xcode > Preferences > Accounts
2. Add Apple ID (free account is OK)
3. Build project → Xcode auto-provisions

### Manual (if needed)

```bash
# List signing identities
security find-identity -v -p codesigning

# Create provisioning profile
# (Usually automatic, but can create manually at developer.apple.com)
```

## Troubleshooting Build Issues

### Issue: "Could not find module 'TrustNetCore'"

```bash
# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Resolve package dependencies
xcodebuild -resolvePackageDependencies \
  -project iOS-App.xcodeproj \
  -scheme TrustNetValidator

# Rebuild
xcodebuild build -scheme TrustNetValidator
```

### Issue: "No signing identity found"

**For simulator (no signing needed)**:
```bash
xcodebuild build \
  -scheme TrustNetValidator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO
```

**For device (need signing)**:
1. Xcode > Preferences > Accounts > Add Apple ID
2. Select team
3. Xcode will auto-provision

### Issue: "Scheme not found"

```bash
# List available schemes
xcodebuild -project iOS-App.xcodeproj -list

# Ensure iOS-App.xcodeproj exists
ls -la iOS-App.xcodeproj/
```

## Build Optimization

### Fast Build (Debug, Simulator)

```bash
xcodebuild build \
  -scheme TrustNetValidator \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -toolchain default \
  -derivedDataPath build
```

Expected time: 10-15 seconds

### Optimized Build (Release, Device)

```bash
xcodebuild build \
  -scheme TrustNetValidator \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build

# Manually strip symbols
strip build/Build/Products/Release-iphoneos/TrustNetValidator.app/TrustNetValidator
```

Expected time: 20-30 seconds

### Parallel Builds

```bash
xcodebuild build \
  -scheme TrustNetValidator \
  -parallel-tests-enabled YES \
  -maximum-concurrent-test-simulator-destinations 4 \
  -destination 'generic/platform=iOS Simulator'
```

## Archive for Distribution

### Create Archive

```bash
xcodebuild archive \
  -project iOS-App.xcodeproj \
  -scheme TrustNetValidator \
  -configuration Release \
  -archivePath build/TrustNetValidator.xcarchive \
  -derivedDataPath build
```

### Export Archive

```bash
xcodebuild -exportArchive \
  -archivePath build/TrustNetValidator.xcarchive \
  -exportPath build/ipa \
  -exportOptionsPlist ExportOptions.plist
```

### ExportOptions.plist (for ad-hoc distribution)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>ad-hoc</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

## Swift Package Integration

### Local Package (Current Setup)

TrustNetCore is integrated as a local package:

```swift
// Package.swift
let package = Package(
    name: "ios-app",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(name: "TrustNetCore", targets: ["TrustNetCore"]),
    ],
    targets: [
        .target(
            name: "TrustNetCore",
            path: "Sources",
            sources: ["PassportValidator.swift"]
        ),
    ]
)
```

### Add to External Project

To use TrustNetCore in another iOS app:

1. In Xcode: File > Add Packages
2. Enter repo URL: `https://github.com/TrustNetT/ios-app`
3. Select version: `main` or release tag
4. Add to target

Or in Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/TrustNetT/ios-app.git", branch: "main"),
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "TrustNetCore", package: "ios-app"),
        ]
    ),
]
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Build iOS App

on: [push, pull_request]

jobs:
  build:
    runs-on: macos-13
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build
      run: |
        xcodebuild build \
          -scheme TrustNetValidator \
          -destination 'generic/platform=iOS Simulator'
    
    - name: Test
      run: |
        xcodebuild test \
          -scheme TrustNetValidator \
          -destination 'platform=iOS Simulator,name=iPhone 14'
```

### Jenkins

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
                xcodebuild build \
                  -scheme TrustNetValidator \
                  -configuration Debug \
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
    }
}
```

## Development Workflow

```
↓
Edit PassportValidator.swift
    ↓
Commit to ios-app GitHub repo
    ↓
Pull on macOS VM: ssh macosx && cd ~/ios-app && git pull
    ↓
Build: xcodebuild build -scheme TrustNetValidator
    ↓
Test: xcodebuild test -scheme TrustNetValidator
    ↓
Deploy: Install on real device or simulator
    ↓
Verify: Run tests on device
    ↓
Success: All 4 tests pass ✅
```

## Summary

- **Simulator builds**: 10-15s, no signing needed
- **Device builds**: 20-30s, requires Apple ID
- **Tests**: 5-10s, comprehensive coverage
- **Deployment**: Over-the-air for devices, simulator built-in
- **CI/CD**: GitHub Actions or Jenkins supported

For detailed testing instructions, see [TESTING_GUIDE.md](TESTING_GUIDE.md).
