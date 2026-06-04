import SwiftUI

struct ErrorRecoveryView: View {
    let error: GovernmentIDScannerError
    @Binding var currentScreen: RegistrationScreen
    @ObservedObject var viewModel: RegistrationViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Error icon
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            // Error title
            Text("Scan Failed")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Error description
            VStack(alignment: .center, spacing: 12) {
                Text(errorTitle)
                    .font(.headline)
                
                Text(errorDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
            
            // Recovery suggestions
            VStack(alignment: .leading, spacing: 12) {
                Text("Recovery Steps:")
                    .font(.headline)
                
                ForEach(recoverySuggestions, id: \.self) { suggestion in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                            .padding(.top, 2)
                        
                        Text(suggestion)
                            .font(.body)
                            .lineLimit(nil)
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    viewModel.resetScan()
                    currentScreen = .nfcScanning
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
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
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Return to Start")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
                
                Link(destination: URL(string: "https://trustnet.help/support")!) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("Get Help")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
    }
    
    var errorTitle: String {
        switch error {
        case .nfcReadError:
            return "Unable to Read ID"
        case .invalidSignature:
            return "Invalid ID Signature"
        case .nfcTimeoutError:
            return "Scan Timed Out"
        case .deviceCapabilityError:
            return "Device Not Supported"
        case .cryptoError:
            return "Encryption Error"
        case .biometricProcessingError:
            return "Biometric Processing Failed"
        case .keyGenerationError:
            return "Key Generation Failed"
        case .keychainError:
            return "Storage Error"
        case .unknown:
            return "Unknown Error"
        }
    }
    
    var errorDescription: String {
        switch error {
        case .nfcReadError:
            return "The NFC reader couldn't read your government ID. Make sure the ID chip is intact and your phone supports NFC."
        case .invalidSignature:
            return "The ID signature validation failed. This could mean the ID is counterfeit or corrupted."
        case .nfcTimeoutError:
            return "The scan took too long. The NFC connection was lost."
        case .deviceCapabilityError:
            return "Your device doesn't have NFC support required for this registration."
        case .cryptoError:
            return "An encryption error occurred during processing."
        case .biometricProcessingError:
            return "Failed to process your biometric data from the ID."
        case .keyGenerationError:
            return "Failed to generate encryption keys."
        case .keychainError:
            return "Failed to securely store your encryption keys."
        case .unknown:
            return "An unexpected error occurred."
        }
    }
    
    var recoverySuggestions: [String] {
        switch error {
        case .nfcReadError:
            return [
                "Ensure your government ID chip is clean and undamaged",
                "Remove any metal cases or protective covers from your iPhone",
                "Hold the ID firmly near the top of your iPhone",
                "Avoid moving the ID during the scan"
            ]
        case .nfcTimeoutError:
            return [
                "Keep the ID steady and close to your phone",
                "Try scanning again with better contact",
                "Ensure the NFC chip has power (some IDs require activation)"
            ]
        case .invalidSignature:
            return [
                "Check that your government ID is current and valid",
                "Try a different government-issued ID",
                "Contact support if the ID is legitimate"
            ]
        case .deviceCapabilityError:
            return [
                "This device must have NFC capability",
                "Try using a newer iPhone model",
                "Contact support for alternative verification methods"
            ]
        default:
            return [
                "Try the scan again",
                "If issues persist, restart your iPhone",
                "Contact support for further assistance"
            ]
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ErrorRecoveryView(
            error: .nfcReadError,
            currentScreen: .constant(.errorRecovery(.nfcReadError)),
            viewModel: RegistrationViewModel()
        )
    }
}
