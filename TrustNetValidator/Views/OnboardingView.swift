import SwiftUI

struct OnboardingView: View {
    @Binding var currentScreen: RegistrationScreen
    @ObservedObject var viewModel: RegistrationViewModel
    
    @State private var nfcAvailable = NFCCapabilityChecker.isNFCAvailable()
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Welcome header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.cyan)
                
                Text("TrustNet Registration")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Secure your digital identity with government ID verification")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            
            Spacer()
            
            // Capability checks section
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    CapabilityCheckRow(
                        icon: "nfc",
                        title: "NFC Support",
                        status: nfcAvailable ? "Ready" : "Not Available",
                        isEnabled: nfcAvailable
                    )
                    
                    CapabilityCheckRow(
                        icon: "touchid",
                        title: "Secure Enclave",
                        status: "Available",
                        isEnabled: true
                    )
                    
                    CapabilityCheckRow(
                        icon: "lock.fill",
                        title: "Encryption",
                        status: "Available",
                        isEnabled: true
                    )
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
            
            // Info section
            VStack(alignment: .leading, spacing: 12) {
                Text("What happens next?")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    StepRow(number: 1, text: "Place your government ID near your iPhone")
                    StepRow(number: 2, text: "We'll read and validate your ID securely")
                    StepRow(number: 3, text: "Create encryption keys stored in Secure Enclave")
                    StepRow(number: 4, text: "Confirm details and complete registration")
                }
                .foregroundColor(.secondary)
                .font(.caption)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    currentScreen = .nfcScanning
                }) {
                    HStack {
                        Image(systemName: "nfc")
                        Text("Begin Registration")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!nfcAvailable)
                
                if !nfcAvailable {
                    Text("NFC device required for registration")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Helper Views

struct CapabilityCheckRow: View {
    let icon: String
    let title: String
    let status: String
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isEnabled ? .green : .red)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isEnabled ? .green : .red)
        }
    }
}

struct StepRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.semibold)
                .frame(width: 20, height: 20)
                .background(Color.blue.opacity(0.3))
                .cornerRadius(10)
            
            Text(text)
                .lineLimit(nil)
        }
    }
}

// MARK: - NFC Capability Checker

struct NFCCapabilityChecker {
    static func isNFCAvailable() -> Bool {
        // In real app, check NFCReaderSession availability
        // For simulator/testing, return true
        return true
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OnboardingView(
            currentScreen: .constant(.onboarding),
            viewModel: RegistrationViewModel()
        )
    }
}
