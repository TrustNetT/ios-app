# Phase 3: User Interface (SwiftUI) - Technical Design Notes

**Date**: March 19, 2026  
**Status**: Design Complete, Ready for Implementation  
**Internal Documentation Only** - WIP repo only

---

## Phase 3: SwiftUI Registration Interface

### Objective
Build user-facing interface for complete registration flow by:
- Displaying device capability checks (NFC available?)
- Guided NFC scanning experience (step-by-step progress)
- Real-time error handling with recovery suggestions
- Registration confirmation and review
- Navigation between screens (onboarding → scan → confirmation → blockchain ready)
- Accessibility compliance (VoiceOver, text sizing, high contrast)

### Dependencies
- SwiftUI framework (iOS 13+)
- Models.swift (GovernmentID, RegistrationData, RegistrationState) ✅
- GovernmentIDScanner.swift (Phase 2) ✅
- All Phase 1 components (validator, hasher, generator, keychain) ✅
- CoreNFC (implicit from Phase 2)
- Foundation

### Files to Create
1. **Views/RegistrationCoordinator.swift** - Navigation controller (150-200 lines)
2. **Views/OnboardingView.swift** - Welcome & capability check (120-150 lines)
3. **Views/NFCScanningView.swift** - Live scanning interface (200-250 lines)
4. **Views/ErrorRecoveryView.swift** - Error display & retry (100-130 lines)
5. **Views/ConfirmationView.swift** - Review & sign confirmation (180-220 lines)
6. **ViewModels/RegistrationViewModel.swift** - State management (250-300 lines)
7. **Utilities/AccessibilityHelpers.swift** - A11y support (80-120 lines)

---

## Architecture Decisions

### 1. SwiftUI for UI Framework
**Decision**: Use Apple's native SwiftUI for all user-facing interface
```swift
import SwiftUI

@main
struct TrustNetApp: App {
    var body: some Scene {
        WindowGroup {
            RegistrationCoordinator()
        }
    }
}
```

**Rationale**:
- Native iOS framework: Part of iOS 13+, no external dependencies
- Declarative UI: Clear, readable screen definitions
- State-driven rendering: Auto-updates when data changes
- Live preview: Real-time design feedback in Xcode
- Accessibility built-in: VoiceOver support native
- SwiftUI debugging: Xcode inspector tools
- Modern patterns: Combine framework integration

**Alternative (UIKit)**: Imperative, more boilerplate, legacy patterns
**Alternative (Cross-platform)**: React Native, Flutter add complexity, slower iterations

### 2. State Management Architecture
**Decision**: Hierarchical state with ViewModel + @StateObject
```swift
@main
struct TrustNetApp: App {
    @StateObject var coordinator = RegistrationCoordinator()
    
    var body: some Scene {
        WindowGroup {
            coordinator.body
        }
    }
}
```

**Pattern**:
```swift
// App-level state (persists across screen changes)
class RegistrationCoordinator: NSObject, ObservableObject {
    @Published var currentScreen: RegistrationScreen = .onboarding
    @Published var registrationData: RegistrationData?
    @Published var scanError: GovernmentIDScannerError?
}

// Screen-level state (local, screen-specific)
struct NFCScanningView: View {
    @StateObject private var viewModel: NFCScanViewModel
    @EnvironmentObject var coordinator: RegistrationCoordinator
    
    @State private var scanProgress: Double = 0.0
    @State private var currentStep: String = "Initializing..."
}
```

**Rationale**:
- **@StateObject**: Preserves state across screen transitions (RegistrationCoordinator)
- **@EnvironmentObject**: Passes coordinator down view hierarchy (no prop drilling)
- **@State**: Local, transient UI state (progress indicators, animations)
- **@Published**: Observable changes trigger SwiftUI re-renders
- **Separation of concerns**: Coordinator manages flow, ViewModels manage data

### 3. Navigation Pattern
**Decision**: NavigationStack-based navigation with enum routing
```swift
enum RegistrationScreen {
    case onboarding
    case nfcScanning
    case errorRecovery(GovernmentIDScannerError)
    case confirmation(RegistrationData)
    case blockchainReady(SignedRegistration)
}

struct RegistrationCoordinator: View {
    @Published var currentScreen: RegistrationScreen = .onboarding
    
    @ViewBuilder
    var body: some View {
        NavigationStack(path: $(currentScreen)) {
            ZStack {
                switch currentScreen {
                case .onboarding:
                    OnboardingView()
                case .nfcScanning:
                    NFCScanningView()
                case .errorRecovery(let error):
                    ErrorRecoveryView(error: error)
                case .confirmation(let data):
                    ConfirmationView(data: data)
                case .blockchainReady(let signed):
                    BlockchainReadyView(signed: signed)
                }
            }
        }
    }
}
```

**Rationale**:
- Single source of truth for navigation state
- Type-safe routing (compiler prevents invalid transitions)
- Back button handling automatic (NavigationStack manages stack)
- Screen data passed via associated values (no separate data passing)
- Easy to test (just change enum values)
- Compatible with deep linking (future feature)

### 4. Error Handling & Recovery UX
**Decision**: Dedicated error recovery screen with user guidance
```swift
struct ErrorRecoveryView: View {
    let error: GovernmentIDScannerError
    @EnvironmentObject var coordinator: RegistrationCoordinator
    
    var body: some View {
        VStack(spacing: 20) {
            // Error icon
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            // User-facing description
            Text(error.errorDescription ?? "Scan failed")
                .font(.headline)
            
            // Recovery suggestion (actionable)
            Text(error.recoverySuggestion ?? "Try again")
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Retry button
            Button("Try Again") {
                coordinator.currentScreen = .nfcScanning
            }
            .buttonStyle(.borderedProminent)
            
            // Contact support link
            Link("Contact Support", destination: URL(string: "https://trustnet.help")!)
                .font(.caption)
        }
        .padding()
        .navigationTitle("Scan Failed")
    }
}
```

**Rationale**:
- Dedicated screen prevents confusion (clear error state)
- Error descriptions from Phase 2 (reuse, consistency)
- Recovery suggestions actionable (vs generic "try again")
- Retry mechanism navigates back to scan screen
- Support link for unrecoverable errors
- Accessibility: VoiceOver reads all guidance

### 5. Real-Time Scan Progress
**Decision**: ProgressView with step-by-step messaging
```swift
struct NFCScanningView: View {
    @StateObject private var viewModel: NFCScanViewModel
    @EnvironmentObject var coordinator: RegistrationCoordinator
    @State private var scanProgress: Double = 0.0
    @State private var currentStep: String = "Hold ID near top of iPhone"
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Scanning Government ID")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Step indicators
            VStack(alignment: .leading, spacing: 12) {
                ScanStepIndicator(
                    step: "Reading NFC",
                    isActive: viewModel.step >= .reading,
                    isComplete: viewModel.step > .reading
                )
                ScanStepIndicator(
                    step: "Validating Signature",
                    isActive: viewModel.step >= .validating,
                    isComplete: viewModel.step > .validating
                )
                ScanStepIndicator(
                    step: "Processing Biometric",
                    isActive: viewModel.step >= .biometric,
                    isComplete: viewModel.step > .biometric
                )
                ScanStepIndicator(
                    step: "Generating Keys",
                    isActive: viewModel.step >= .keyGeneration,
                    isComplete: viewModel.step > .keyGeneration
                )
            }
            .padding()
            
            // Progress bar
            ProgressView(value: scanProgress)
                .tint(.blue)
            
            // Current step message
            Text(currentStep)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            // Cancel button
            Button("Cancel", role: .destructive) {
                viewModel.cancelScan()
                coordinator.currentScreen = .onboarding
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            viewModel.startScan { result in
                switch result {
                case .success(let data):
                    coordinator.currentScreen = .confirmation(data)
                case .failure(let error):
                    coordinator.currentScreen = .errorRecovery(error)
                }
            }
        }
    }
}
```

**Rationale**:
- Progress indicators show work is happening (prevents "frozen" perception)
- Step-by-step messaging guides user (vs silent processing)
- Cancel option gives user control (reduces anxiety)
- Real-time updates from Phase 2 scanner (via completion handler)
- Smooth transitions between steps (SwiftUI animation)

### 6. Confirmation & Review Screen
**Decision**: Display captured data with edit/retry options
```swift
struct ConfirmationView: View {
    let registrationData: RegistrationData
    @EnvironmentObject var coordinator: RegistrationCoordinator
    @State private var agreedToTerms = false
    
    var body: some View {
        Form {
            Section("Personal Information") {
                LabeledContent("Name", value: registrationData.governmentID.fullName)
                LabeledContent("Date of Birth", value: formatDate(registrationData.governmentID.dateOfBirth))
                LabeledContent("Document #", value: registrationData.governmentID.documentNumber)
                LabeledContent("Country", value: registrationData.governmentID.countryCode)
            }
            
            Section("TrustNet Identity") {
                LabeledContent("UserID", value: registrationData.userID)
                    .font(.system(.caption, design: .monospaced))
                LabeledContent("Biometric Hash", value: String(registrationData.biometricHash.hash.prefix(16)) + "...")
                    .font(.system(.caption, design: .monospaced))
            }
            
            Section("Agreement") {
                Toggle("I agree to register this identity on TrustNet", isOn: $agreedToTerms)
                Text("This action creates an immutable record on the blockchain. You cannot undo this.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button("Confirm & Continue", action: submitToBlockchain)
                    .disabled(!agreedToTerms)
                    .frame(maxWidth: .infinity)
                
                Button("Rescan ID", role: .secondary) {
                    coordinator.currentScreen = .nfcScanning
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Review Information")
    }
    
    private func submitToBlockchain() {
        // Phase 4: Sign and submit to blockchain
        do {
            let keychainManager = KeychainManager()
            let signedRegistration = try registrationData.sign(using: keychainManager)
            coordinator.currentScreen = .blockchainReady(signedRegistration)
        } catch {
            coordinator.scanError = .keychainStorageError
            coordinator.currentScreen = .errorRecovery(.keychainStorageError)
        }
    }
}
```

**Rationale**:
- Display all captured data (transparency, verification)
- Edit warning (immutable blockchain record)
- Agreement toggle (explicit consent before blockchain)
- Rescan option (catches errors before submission)
- Signature happens here (Phase 4 entry point)

### 7. OnboardingView: Device Capability Check
**Decision**: Pre-flight check before scanning
```swift
struct OnboardingView: View {
    @EnvironmentObject var coordinator: RegistrationCoordinator
    @State private var deviceSupportsNFC = false
    @State private var isUnderage = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Create Your TrustNet Identity")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Register securely with your government ID via NFC")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                // Device check
                HStack {
                    Image(systemName: deviceSupportsNFC ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(deviceSupportsNFC ? .green : .red)
                    VStack(alignment: .leading) {
                        Text("NFC Support")
                            .fontWeight(.semibold)
                        Text(deviceSupportsNFC ? "iPhone XS or later" : "Device does not support NFC")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Age check
                HStack {
                    Toggle("I am 18 years or older", isOn: $isUnderage.toggle())
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button("Start Registration") {
                    coordinator.currentScreen = .nfcScanning
                }
                .buttonStyle(.borderedProminent)
                .disabled(!deviceSupportsNFC || isUnderage)
                .frame(maxWidth: .infinity)
                
                NavigationLink("Learn More", destination: Text("Help & FAQ"))
                    .font(.caption)
            }
        }
        .padding()
        .navigationTitle("Welcome to TrustNet")
        .onAppear {
            deviceSupportsNFC = NFCTagReaderSession.readingAvailable
        }
    }
}
```

**Rationale**:
- Device check prevents dead-end scanning (error prevention)
- Age verification legal requirement (GDPR, legal compliance)
- Help link for users without NFC (guidance, not frustration)
- Accessibility: Toggle clear for screen readers

---

## Component Structure

```
Sources/
├── UI/
│   ├── Views/
│   │   ├── RegistrationCoordinator.swift      (Navigation hub)
│   │   ├── OnboardingView.swift               (Welcome & checks)
│   │   ├── NFCScanningView.swift              (Active scan screen)
│   │   ├── ErrorRecoveryView.swift            (Error handling)
│   │   ├── ConfirmationView.swift             (Review capture)
│   │   └── BlockchainReadyView.swift          (Success state)
│   │
│   ├── Components/
│   │   ├── ScanStepIndicator.swift            (Step progress item)
│   │   ├── ProgressOverlay.swift              (Loading states)
│   │   ├── ErrorDisplay.swift                 (Reusable error UI)
│   │   └── InfoCard.swift                     (Data display card)
│   │
│   └── Utilities/
│       ├── AccessibilityHelpers.swift         (VoiceOver support)
│       └── FormattingHelpers.swift            (Date/number display)
│
├── ViewModels/
│   ├── RegistrationViewModel.swift            (State orchestration)
│   ├── NFCScanViewModel.swift                 (Scan-specific logic)
│   └── ConfirmationViewModel.swift            (Confirmation logic)
│
└── (existing Phase 0-2 files remain)
```

---

## State Management in Detail

### RegistrationCoordinator (App-level state)
```swift
@MainActor
class RegistrationCoordinator: NSObject, ObservableObject {
    @Published var currentScreen: RegistrationScreen = .onboarding
    @Published var registrationData: RegistrationData?
    @Published var signedRegistration: SignedRegistration?
    @Published var lastError: GovernmentIDScannerError?
    
    enum RegistrationScreen {
        case onboarding
        case nfcScanning
        case errorRecovery(GovernmentIDScannerError)
        case confirmation(RegistrationData)
        case blockchainReady(SignedRegistration)
    }
    
    // Transitions
    func startScanning() {
        currentScreen = .nfcScanning
    }
    
    func handleScanSuccess(_ data: RegistrationData) {
        registrationData = data
        currentScreen = .confirmation(data)
    }
    
    func handleScanError(_ error: GovernmentIDScannerError) {
        lastError = error
        currentScreen = .errorRecovery(error)
    }
    
    func retryScanning() {
        currentScreen = .nfcScanning
    }
}
```

### NFCScanViewModel (Screen-level logic)
```swift
@MainActor
class NFCScanViewModel: NSObject, ObservableObject {
    @Published var scanProgress: Double = 0.0
    @Published var currentStep: String = "Initializing..."
    @Published var scanSteps: ScanStep = .initializing
    
    private let scanner = GovernmentIDScanner()
    private var progressTimer: Timer?
    
    enum ScanStep {
        case initializing
        case reading
        case validating
        case biometric
        case keyGeneration
        case complete
    }
    
    func startScan(completion: @escaping (Result<RegistrationData, GovernmentIDScannerError>) -> Void) {
        currentStep = "Hold ID near phone"
        scanSteps = .reading
        
        scanner.beginScan { [weak self] result in
            switch result {
            case .success(let data):
                self?.scanSteps = .complete
                self?.scanProgress = 1.0
                self?.currentStep = "Success!"
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func cancelScan() {
        scanner.cancelScan()
        progressTimer?.invalidate()
    }
}
```

---

## Navigation Flow Diagram

```
┌─────────────────┐
│   Onboarding    │  Device capability check
│   (Welcome)     │  Age verification
└────────┬────────┘
         │ "Start Registration"
         ↓
┌─────────────────┐
│  NFC Scanning   │  CoreNFC reading
│  (Active)       │  Progress steps
└────┬──────┬─────┘
     │      │
Success  Error
     │      │
     ↓ (OK) ↓ (Failed)
┌────────┐  ┌─────────────────┐
│Confirm │  │Error Recovery   │  Retry option
│Review  │  │(Show guidance)  │  Help/support
└────┬───┘  └────────┬────────┘
     │               │
     │         "Retry" / "Help"
     │               │
     └───────────┬───┘
                 │
     "Confirm" ──┤
                 │
                 ↓
┌─────────────────────┐
│Blockchain Ready     │  Signature complete
│(Success state)      │  Share/print receipt
└─────────────────────┘
```

---

## Accessibility & Localization

### VoiceOver Support
```swift
// Mark important elements for screen readers
Text("Scanning Government ID")
    .accessibilityLabel("Scanning Government ID")
    .accessibilityHint("Hold your government ID near the top of your iPhone")

// Step progress with semantic meaning
ScanStepIndicator(step: "Reading NFC", isComplete: true)
    .accessibilityLabel("Step 1 of 4: Reading NFC - Complete")

// Form fields
TextField("Search", text: $searchText)
    .accessibilityLabel("Search for help topics")
    .accessibilityHint("Type keywords to find relevant help")
```

### Text Size & High Contrast
- Use relative font sizes (`.body`, `.headline` not fixed points)
- Support dynamic type (SF Styles adapt to user size preference)
- High contrast mode aware (test with accessibility inspector)

### Localization Hooks (Future)
```swift
// All user-facing strings use localization keys
Text("NSLocalizedString("start_registration", comment: "Button text")
Text(NSLocalizedString("nfc_hold_id", comment: "NFC instruction"))
Text(error.errorDescription ?? NSLocalizedString("unknown_error"))
```

---

## Testing Strategy

### Unit Tests (ViewModel Logic)
```swift
class RegistrationViewModelTests: XCTestCase {
    func testOnboardingRequiresNFCAndAge() {
        let viewModel = OnboardingViewModel()
        viewModel.deviceSupportsNFC = false
        XCTAssertTrue(viewModel.isStartDisabled)
    }
    
    func testErrorRecoveryNavigatesBackToScanning() {
        let coordinator = RegistrationCoordinator()
        coordinator.handleScanError(.nfcTimeout)
        if case .errorRecovery = coordinator.currentScreen {
            XCTAssert(true)
        } else {
            XCTFail("Expected error recovery screen")
        }
    }
}
```

### UI Tests (SwiftUI Preview)
```swift
struct NFCScanningView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NFCScanViewModel()
        NFCScanningView()
            .environmentObject(viewModel)
            .previewDisplayName("Scanning in Progress")
    }
}
```

### Manual Testing
1. **Device capability check**: Test with iPhone without NFC
2. **Scan simulation**: Mock GovernmentIDScanner for UI testing
3. **Error paths**: Inject errors into scanner
4. **Accessibility**: Enable VoiceOver, navigate screens
5. **Navigation**: Verify back buttons work, state persists

---

## Performance Considerations

### Animation Performance
- Use `.linear` easing for progress bars (smooth, predictable)
- Limit shadow effects (GPU cost)
- Lazy load form sections (large confirmations)

### Memory Management
- @StateObject for long-lived objects (RegistrationCoordinator)
- @State for temporary values (animations, temporary state)
- Cleanup timers in `onDisappear`

### Network (Future Phase 4)
- Progressive UI updates as blockchain submission progresses
- Loading spinners prevent frozen perception
- Timeout handling (show retry option after 30s)

---

## Error State Reference (From Phase 2)

All `GovernmentIDScannerError` cases display with:
- User-facing description: "Hold ID still"
- Recovery suggestion: "Keep hand steady, try again"
- Actionable next step: Retry button

Error cases handled:
```swift
case .nfcNotAvailable       → Show onboarding help
case .nfcReadingFailed      → Error recovery with retry
case .nfcTimeout            → Error recovery with retry
case .invalidGovernmentID   → Error recovery with support link
case .invalidSignature      → Contact support (not user error)
case .biometricProcessingFailed → Retry scan
case .keyGenerationFailed   → Retry or contact support
case .keychainStorageError  → Device unlock suggestion
case .keyRetrievalFailed    → Device unlock suggestion
case .documentAlreadyRegistered → Show help for multiple IDs
case .userCancelled         → Return to onboarding
case .unknownError          → Generic error with support
```

---

## Design System Baseline

### Colors
- **Primary**: `.blue` (iOS system blue)
- **Error**: `.red` (system red for warnings)
- **Success**: `.green` (system green for completion)
- **Text**: `.primary`, `.secondary` (auto light/dark mode)

### Typography
- **Titles**: `.largeTitle`, `.title2`
- **Body**: `.body` (default reading text)
- **Caption**: `.caption` (helper text, smaller)
- **Monospaced**: `.system(.caption, design: .monospaced)` (IDs, hashes)

### Spacing
- **Default**: 16pt padding (iOS HIG standard)
- **Compact**: 8pt between related items
- **Large**: 20pt between sections

### Buttons
- **Primary action**: `.borderedProminent` (filled blue button)
- **Secondary action**: `.bordered` (outlined button)
- **Destructive**: `role: .destructive` (red styling)

---

## Next Steps (Phase 4)

Phase 4 will add:
- BlockchainReadyView (success state)
- BlockchainConnector integration (actual submission)
- Transaction receipt display
- Receipt sharing (email, screenshot)
- Retry logic for network failures
- Offline queueing

---

## Summary

Phase 3 builds production-ready SwiftUI interface with:
- **Navigation**: Type-safe enum-based routing
- **State**: Hierarchical (@StateObject parent, @State children)
- **UX**: Step-by-step guidance, error recovery, confirmation
- **Accessibility**: VoiceOver, dynamic type, high contrast ready
- **Testing**: ViewModel unit tests + SwiftUI preview testing
- **Performance**: Efficient animations, proper memory management

All screens reuse error descriptions and recovery suggestions from Phase 2 GovernmentIDScanner, ensuring consistency and leveraging existing guidance logic.

**Status**: Design complete, ready for implementation
**Dependencies**: Phase 2 (GovernmentIDScanner), all Phase 1 components
**Deployment**: TestFlight beta after implementation + basic UI tests
