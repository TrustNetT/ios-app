import SwiftUI

struct NFCScanningView: View {
    @Binding var currentScreen: RegistrationScreen
    @ObservedObject var viewModel: RegistrationViewModel
    
    @State private var isScanning = false
    @State private var scanTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Header
            Text("Scan Government ID")
                .font(.title2)
                .fontWeight(.semibold)
            
            // NFC Icon Animation
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 2)
                    .frame(width: 180, height: 180)
                
                Image(systemName: "nfc")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .scaleEffect(isScanning ? 1.1 : 1.0)
                    .animation(
                        isScanning ?
                        Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                        .default,
                        value: isScanning
                    )
            }
            .padding(.vertical, 20)
            
            // Step indicators
            VStack(alignment: .leading, spacing: 12) {
                ScanStepIndicator(
                    step: "Reading NFC",
                    isActive: viewModel.currentStep >= .reading,
                    isComplete: viewModel.currentStep > .reading
                )
                ScanStepIndicator(
                    step: "Validating Signature",
                    isActive: viewModel.currentStep >= .validating,
                    isComplete: viewModel.currentStep > .validating
                )
                ScanStepIndicator(
                    step: "Processing Biometric",
                    isActive: viewModel.currentStep >= .biometric,
                    isComplete: viewModel.currentStep > .biometric
                )
                ScanStepIndicator(
                    step: "Generating Keys",
                    isActive: viewModel.currentStep >= .keyGeneration,
                    isComplete: viewModel.currentStep > .keyGeneration
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: viewModel.scanProgress)
                    .tint(.blue)
                
                Text("\(Int(viewModel.scanProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Status message
            Text(viewModel.currentStepMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(height: 40)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                if !isScanning {
                    Button(action: startScan) {
                        HStack {
                            Image(systemName: "nfc")
                            Text("Start Scan")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        currentScreen = .onboarding
                    }) {
                        Text("Back")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                } else {
                    Button(action: stopScan) {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("Cancel Scan")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.3))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                    
                    Text("Hold ID near top of iPhone")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.registrationData) { oldValue, newValue in
            if newValue != nil {
                currentScreen = .confirmation(newValue!)
            }
        }
        .onChange(of: viewModel.scanError) { oldValue, newValue in
            if let error = newValue {
                currentScreen = .errorRecovery(error)
            }
        }
        .onDisappear {
            stopScan()
        }
    }
    
    func startScan() {
        isScanning = true
        viewModel.resetScan()
        
        scanTask = Task {
            await viewModel.startScan()
            isScanning = false
        }
    }
    
    func stopScan() {
        isScanning = false
        scanTask?.cancel()
        viewModel.resetScan()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NFCScanningView(
            currentScreen: .constant(.nfcScanning),
            viewModel: RegistrationViewModel()
        )
    }
}
