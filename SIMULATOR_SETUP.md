# iOS Simulator Setup & Build Guide

**Date**: March 19, 2026  
**Status**: Ready for Testing  
**Purpose**: Document simulator configuration and how to build/run TrustNet iOS app

---

## Simulator Environment

### Available Machines
There are **two macOS environments** available for testing:

**Option 1: macOS VM via SSH** (Recommended for remote development)
```bash
ssh macosx
```

**Option 2: Local Mac (if available)**
- Physical macOS machine with Xcode
- Direct simulator access

### Simulator Details
- **Device**: iPhone 14 Pro Max (or iPhone 15 Pro)
- **iOS Version**: 14.0+ (compatible with iOS 13+)
- **Available Simulators**: List with `xcrun simctl list devices`
- **Performance**: Reasonable simulator performance on macOS VM

---

## Quick Start: Build & Run

### Step 1: SSH to macOS
```bash
ssh macosx
```

### Step 2: Navigate to Project
```bash
cd ~/ios-app/trustnet-wip/ios
# Or if symlinked:
cd ~/GitProjects/TrustNet/trustnet-wip/ios
```

### Step 3: List Available Simulators
```bash
xcrun simctl list devices available iphone
```
Example output:
```
iPhone 14 Pro Max (XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX) (Booted)
iPhone 15 Pro (XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX) (Shutdown)
```

### Step 4: Build for Simulator
```bash
xcodebuild build \
  -scheme TrustNetValidator \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator'
```

**Expected Output**:
```
Build complete! (11 seconds)
** BUILD SUCCEEDED **
```

### Step 5: Boot Simulator (if not running)
```bash
xcrun simctl boot "iPhone 14 Pro Max"
```

### Step 6: Launch Simulator UI
```bash
open -a Simulator
```

### Step 7: Install & Run App
```bash
# Get the build location
BUILD_DIR=$(xcodebuild -scheme TrustNetValidator -configuration Debug -showBuildSettings | grep BUILD_DIR | awk '{print $3}')

# Install on simulator
xcrun simctl install booted "${BUILD_DIR}/Debug-iphonesimulator/TrustNetValidator.app"

# Launch the app
xcrun simctl launch booted com.trustnet.validator
```

---

## Xcode Project Structure

### Project Files
```
ios/
├── TrustNetValidator/
│   ├── App.swift                    ← Main app entry point (166 lines)
│   ├── Assets.xcassets/             ← App icons
│   └── Info.plist                   ← iOS bundle configuration
├── Sources/
│   ├── Models.swift                 ← Phase 0: Data structures
│   ├── Errors.swift                 ← Phase 0: Error types
│   ├── ICAO9303Validator.swift      ← Phase 1A: Government signature
│   ├── BiometricHasher.swift        ← Phase 1B: Facial hash
│   ├── KeyGenerator.swift           ← Phase 1C: Keypair generation
│   ├── KeychainManager.swift        ← Phase 1D: Secure storage
│   ├── GovernmentIDScanner.swift    ← Phase 2: NFC orchestration
│   └── PassportValidator.swift      ← Validator utility
├── Tests/
│   └── main.swift                   ← Test entry point
├── iOS-App.xcodeproj/
│   └── project.pbxproj              ← Xcode configuration
├── Package.swift                    ← Swift Package config
└── BUILD_GUIDE.md                   ← This file
```

### Scheme: TrustNetValidator
- **Product Name**: TrustNetValidator
- **Bundle ID**: com.trustnet.validator
- **Target SDK**: iOS 14.0+
- **Configuration**: Debug / Release

---

## Current App Display

The minimal app shows project status with:
- **Title**: "TrustNet Digital Identity Registration"
- **Status Card**: Backend components (Phase 0-2)
  - ✅ Phase 0: Models & Errors (Complete)
  - ✅ Phase 1A: ICAO9303 Validator (Complete)
  - ✅ Phase 1B: Biometric Hasher (Complete)
  - ✅ Phase 1C: Key Generator (Complete)
  - ✅ Phase 1D: Keychain Manager (Complete)
  - ✅ Phase 2: NFC Scanner (Complete)
  - ⏳ Phase 3: SwiftUI Interface (Design Ready)
- **Button**: "Begin Registration" (placeholder for Phase 3)
- **Design**: Dark purple/blue gradient background (matches TrustNet branding)

### What It Shows
- All Phase 1-2 backend components are ready
- No UI screens yet (Phase 3 to implement)
- App structure confirms all dependencies compile correctly

---

## Debugging on Simulator

### View App Console Output
```bash
log stream --level debug --predicate 'eventMessage contains "TrustNet"'
```

### Clear App Data
```bash
xcrun simctl erase all
```

### Uninstall App
```bash
xcrun simctl uninstall booted com.trustnet.validator
```

### Get Device UDID
```bash
xcrun simctl list devices | grep "iPhone 14 Pro Max"
```

### Kill All Simulators
```bash
xcrun simctl shutdown all
```

---

## Build Troubleshooting

### Build Fails: "Scheme not found"
```bash
# Check available schemes
xcodebuild -list

# Expected: TrustNetValidator scheme
```

### Build Fails: "File not found"
```bash
# Clean build folder
xcodebuild clean

# Rebuild
xcodebuild build -scheme TrustNetValidator -configuration Debug -destination 'generic/platform=iOS Simulator'
```

### Simulator Won't Boot
```bash
# Try explicit iOS version
xcrun simctl create "iPhone Test" com.apple.CoreSimulator.SimDeviceType.iPhone-14-pro-max com.apple.CoreSimulator.SimRuntime.iOS-16-4

# List created devices
xcrun simctl list devices
```

### App Crashes on Launch
- Check console: `log stream --level debug`
- Likely cause: Missing view controller (Phase 3 not implemented)
- Current minimal app should launch without crashes

---

## App Phases & Implementation Status

| Phase | Component | Status | Files | Lines |
|-------|-----------|--------|-------|-------|
| 0 | Models & Errors | ✅ Complete | Models.swift, Errors.swift | 438 |
| 1A | ICAO9303 Validator | ✅ Complete | ICAO9303Validator.swift | 238 |
| 1B | Biometric Hasher | ✅ Complete | BiometricHasher.swift | 316 |
| 1C | Key Generator | ✅ Complete | KeyGenerator.swift | 362 |
| 1D | Keychain Manager | ✅ Complete | KeychainManager.swift | 438 |
| 2 | NFC Scanner | ✅ Complete | GovernmentIDScanner.swift | 438 |
| 3 | UI (SwiftUI) | ⏳ Design Ready | App.swift | 166 (placeholder) |
| 4 | Blockchain | ⏸️ Planned | - | - |

---

## What to Look For in Simulator

### Expected Behavior
1. App launches without crashes
2. Shows TrustNet title and purple/blue gradient
3. Displays project status with 6 completed phases + 1 design-ready
4. Button text "Begin Registration" visible
5. App exits cleanly on home button press

### Visual Check
- Dark theme (purple to blue gradient)
- All text visible and readable
- No warnings in console
- Component status shows correct phase counts

### After Viewing
- Verify current code compiles correctly
- Confirm UI is ready for Phase 3 implementation
- Check if any design changes needed before rebuilding Phase 3

---

## Next Steps After Viewing

### If Everything Looks Good
1. Note any UI improvements for Phase 3
2. Start Phase 3 implementation (SwiftUI screens per design doc)
3. Update App.swift to use new Phase 3 views
4. Test each phase 3 screen as created

### If Changes Needed
1. Document preferred design changes
2. Update PHASE_3_UI_DESIGN_DECISIONS.md if needed
3. Adjust Phase 3 screen specifications
4. Begin Phase 3 implementation with updated design

---

## Reference: Previous Build Success

**Date**: February 9, 2026  
- **Summary**: App successfully built and ran on iPhone 14 Pro Max simulator
- **Build Time**: ~11 seconds
- **RAM Usage**: 87 MB
- **Crashes**: None
- **File**: BUILD_SUCCESS.md (in project root)

---

## Remote Access

### If on Linux Machine (main workspace)
SSH tunnel to macOS:
```bash
ssh macosx
cd /path/to/ios-app
xcodebuild build -scheme TrustNetValidator -configuration Debug -destination 'generic/platform=iOS Simulator'
open -a Simulator
```

### If on macOS Machine
Direct access:
```bash
cd /path/to/ios-app
open iOS-App.xcodeproj
# Use Xcode UI to build and run
# Or use xcodebuild commands above
```

---

## Build Artifacts Location

After successful build:
```
~/Library/Developer/Xcode/DerivedData/
└── TrustNetValidator-<hash>/
    └── Build/Products/Debug-iphonesimulator/
        └── TrustNetValidator.app
```

This is what `xcrun simctl install` deploys to the simulator.

---

## Design System in Current App

The minimal status app uses:
- **Background**: LinearGradient (purple to dark blue)
- **Cards**: White background with opacity (0.1 overlay)
- **Text**: White primary, white with opacity secondary
- **Status Color**: Green for complete, Orange for in-progress
- **Corner Radius**: 12pt for main card, 10pt for button
- **Spacing**: 40pt between major sections, 16pt between cards

This design will be extended in Phase 3 with:
- Navigation between screens
- Form components for input
- Progress indicators for scanning
- Error display patterns
- Accessibility features (VoiceOver, dynamic type)

---

**Last Updated**: March 19, 2026
**Next Review**: After Phase 3 implementation
**Contact**: Refer to project README.md
