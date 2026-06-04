import SwiftUI

struct BlockchainReadyView: View {
    @Binding var currentScreen: RegistrationScreen
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Success animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(isAnimating ? 1.0 : 0.7)
                    .opacity(isAnimating ? 1.0 : 0.5)
                    .onAppear {
                        withAnimation(
                            Animation.easeOut(duration: 0.6)
                        ) {
                            isAnimating = true
                        }
                    }
            }
            
            // Success message
            VStack(spacing: 12) {
                Text("Registration Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Your digital identity is now secured")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Status summary
            VStack(spacing: 16) {
                StatusRow(
                    icon: "nfc",
                    title: "Government ID",
                    subtitle: "Verified & Encrypted"
                )
                StatusRow(
                    icon: "face.smiling",
                    title: "Biometric",
                    subtitle: "Hashed & Stored"
                )
                StatusRow(
                    icon: "key.fill",
                    title: "Keys Generated",
                    subtitle: "Stored in Secure Enclave"
                )
                StatusRow(
                    icon: "network",
                    title: "Ready for Blockchain",
                    subtitle: "Next: Submit to network"
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Info section
            VStack(alignment: .leading, spacing: 12) {
                Text("What's Next?")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(number: 1, text: "Your registration data is now secured with encryption")
                    InfoRow(number: 2, text: "Keys are stored in your iPhone's Secure Enclave")
                    InfoRow(number: 3, text: "Ready to submit to blockchain for authentication")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    currentScreen = .onboarding
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Done")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                NavigationLink(destination: EmptyView()) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("View Certificate")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Helper Views

struct StatusRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 14))
        }
        .padding(.vertical, 8)
    }
}

struct InfoRow: View {
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

// MARK: - Preview

#Preview {
    NavigationStack {
        BlockchainReadyView(currentScreen: .constant(.blockchainReady))
    }
}
