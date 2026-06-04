import SwiftUI
import Combine

class RegistrationViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var registrationData: RegistrationData?
    @Published var currentStep: ScanStep = .initializing
    @Published var scanProgress: Double = 0.0
    @Published var currentStepMessage: String = "Initializing..."
    @Published var isScanning: Bool = false
    @Published var scanError: GovernmentIDScannerError?
    
    // MARK: - Lifecycle
    private var scanner: GovernmentIDScanner?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        self.scanner = GovernmentIDScanner()
    }
    
    // MARK: - Scan Steps Enum
    enum ScanStep: Int, Comparable {
        case initializing = 0
        case reading = 1
        case validating = 2
        case biometric = 3
        case keyGeneration = 4
        case complete = 5
        
        static func < (lhs: ScanStep, rhs: ScanStep) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        var description: String {
            switch self {
            case .initializing:
                return "Preparing NFC reader..."
            case .reading:
                return "Reading government ID..."
            case .validating:
                return "Validating signature..."
            case .biometric:
                return "Processing biometric data..."
            case .keyGeneration:
                return "Generating encryption keys..."
            case .complete:
                return "Registration complete!"
            }
        }
        
        var progress: Double {
            Double(self.rawValue) / Double(ScanStep.complete.rawValue)
        }
    }
    
    // MARK: - Scan Operations
    func startScan() async {
        await MainActor.run {
            self.isScanning = true
            self.currentStep = .initializing
            self.scanProgress = 0.0
            self.scanError = nil
        }
        
        do {
            // Simulate step progression with delays
            await updateStep(.reading, progress: 0.2)
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await updateStep(.validating, progress: 0.4)
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            await updateStep(.biometric, progress: 0.6)
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            await updateStep(.keyGeneration, progress: 0.8)
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            await updateStep(.complete, progress: 1.0)
            
            // Create sample registration data (will be replaced by actual scanner)
            let sampleData = RegistrationData(
                governmentID: nil,
                biometricHash: nil,
                publicKey: nil,
                userID: UUID().uuidString,
                timestamp: Date()
            )
            
            await MainActor.run {
                self.registrationData = sampleData
                self.isScanning = false
            }
        } catch {
            await MainActor.run {
                self.isScanning = false
                self.scanError = GovernmentIDScannerError.nfcTimeoutError
            }
        }
    }
    
    func resetScan() {
        self.currentStep = .initializing
        self.scanProgress = 0.0
        self.currentStepMessage = "Ready to scan"
        self.isScanning = false
        self.scanError = nil
        self.registrationData = nil
    }
    
    // MARK: - Private Helpers
    private func updateStep(_ step: ScanStep, progress: Double) async {
        await MainActor.run {
            self.currentStep = step
            self.scanProgress = progress
            self.currentStepMessage = step.description
        }
    }
}

// MARK: - ScanStep View Helper
struct ScanStepIndicator: View {
    let step: String
    let isActive: Bool
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.green)
                } else if isActive {
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .background(
                            Circle()
                                .foregroundColor(.blue.opacity(0.2))
                        )
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                }
            }
            .frame(width: 28, height: 28)
            
            Text(step)
                .font(.body)
                .foregroundColor(isActive || isComplete ? .primary : .secondary)
        }
    }
}
