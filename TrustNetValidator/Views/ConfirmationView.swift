import SwiftUI

struct ConfirmationView: View {
    let registrationData: RegistrationData
    @Binding var currentScreen: RegistrationScreen
    @ObservedObject var viewModel: RegistrationViewModel
    
    @State private var isConfirming = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Header
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Registration Details")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Scrollable content
            ScrollView {
                VStack(spacing: 16) {
                    // Government ID Section
                    DetailSection(
                        title: "Government ID",
                        details: [
                            ("Type", registrationData.governmentID?.idType ?? "N/A"),
                            ("Holder", registrationData.governmentID?.holderName ?? "N/A"),
                            ("Document Number", registrationData.governmentID?.documentNumber ?? "N/A"),
                            ("Expiration", formatDate(registrationData.governmentID?.expirationDate))
                        ]
                    )
                    
                    // Biometric Section
                    DetailSection(
                        title: "Biometric Hash",
                        details: [
                            ("Status", registrationData.biometricHash != nil ? "Captured" : "Pending"),
                            ("Algorithm", "SHA-256")
                        ]
                    )
                    
                    // Key Generation Section
                    DetailSection(
                        title: "Encryption Keys",
                        details: [
                            ("Status", registrationData.publicKey != nil ? "Generated" : "Pending"),
                            ("Type", "RSA-2048"),
                            ("Storage", "Secure Enclave")
                        ]
                    )
                    
                    // Registration Meta
                    DetailSection(
                        title: "Registration",
                        details: [
                            ("User ID", registrationData.userID.prefix(12) + "..."),
                            ("Timestamp", formatDate(registrationData.timestamp))
                        ]
                    )
                    
                    // Confirmation message
                    VStack(spacing: 12) {
                        Image(systemName: "shield.checkmark.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("Ready for Blockchain Submission")
                            .font(.headline)
                        
                        Text("Your registration data is secure and ready to be submitted to the blockchain for permanent authentication.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: completeRegistration) {
                    if isConfirming {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                            Text("Confirming...")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Confirm & Continue")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .disabled(isConfirming)
                
                Button(action: {
                    viewModel.resetScan()
                    currentScreen = .nfcScanning
                }) {
                    Text("Scan Again")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                .disabled(isConfirming)
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
    }
    
    func completeRegistration() {
        isConfirming = true
        
        Task {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
            
            await MainActor.run {
                isConfirming = false
                currentScreen = .blockchainReady
            }
        }
    }
    
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Helper Views

struct DetailSection: View {
    let title: String
    let details: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(details, id: \.0) { label, value in
                    HStack {
                        Text(label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(value)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConfirmationView(
            registrationData: RegistrationData(
                governmentID: GovernmentID(
                    idType: "Passport",
                    holderName: "John Doe",
                    documentNumber: "PP123456789",
                    expirationDate: Date().addingTimeInterval(86400 * 365),
                    issueDate: Date(),
                    country: "US",
                    mrz: "PPPPPPPPPPPPPPP"
                ),
                biometricHash: nil,
                publicKey: nil,
                userID: UUID().uuidString,
                timestamp: Date()
            ),
            currentScreen: .constant(.confirmation(RegistrationData(governmentID: nil, biometricHash: nil, publicKey: nil, userID: UUID().uuidString, timestamp: Date()))),
            viewModel: RegistrationViewModel()
        )
    }
}
