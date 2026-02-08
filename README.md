# TrustNet iOS App

Native iOS application for ICAO 9303 passport validation via NFC.

## Technology Stack
- **Language**: Swift 6.0.3
- **Framework**: SwiftUI
- **Deployment Target**: iOS 14.0+
- **Key Features**: CoreNFC, CryptoKit (signature validation)

## Project Structure
```
ios-app/
├── Sources/
│   ├── PassportValidator.swift
│   └── NFCReader.swift
├── Tests/
│   └── PassportValidatorTests.swift
└── Package.swift
```

## Getting Started
```bash
swift build
swift test
```

## Development
- Clone this repository
- Install dependencies: None (using Apple frameworks)
- Build: `swift build`
- Test: `swift test`
```
