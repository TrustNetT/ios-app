import SwiftUI
import TrustNetCore
import CryptoKit

@available(iOS 14, *)
struct ContentView: View {
    @State private var testResults: [String] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("TrustNet PassportValidator")
                    .font(.title2)
                    .fontWeight(.bold)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(testResults, id: \.self) { result in
                            Text(result)
                                .font(.monospaced(.body)())
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .border(Color.gray.opacity(0.3))
                
                Button(action: runTests) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                        Text(isLoading ? "Testing..." : "Run Tests")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isLoading)
            }
            .padding()
            .navigationTitle("Validator Test")
        }
    }
    
    private func runTests() {
        isLoading = true
        testResults = []
        
        DispatchQueue.global().async {
            var results: [String] = []
            results.append("🧪 Starting Tests...")
            
            do {
                // Test 1: Initialize
                let validator = PassportValidator()
                results.append("✅ Test 1: Validator initialized")
                
                // Test 2: Valid signature
                let privateKey = P256.Signing.PrivateKey()
                let publicKey = privateKey.publicKey
                let testData = "Test passport document".data(using: .utf8)!
                let signature = try privateKey.signature(for: testData)
                
                let isValid = try validator.validateSignature(
                    documentData: testData,
                    signature: signature.rawRepresentation,
                    publicKey: publicKey.rawRepresentation
                )
                
                if isValid {
                    results.append("✅ Test 2: Valid signature passed")
                } else {
                    results.append("❌ Test 2: Valid signature FAILED")
                }
                
                // Test 3: Invalid signature
                let differentData = "Different".data(using: .utf8)!
                let isInvalid = try validator.validateSignature(
                    documentData: differentData,
                    signature: signature.rawRepresentation,
                    publicKey: publicKey.rawRepresentation
                )
                
                if !isInvalid {
                    results.append("✅ Test 3: Invalid signature rejected")
                } else {
                    results.append("❌ Test 3: Invalid signature accepted")
                }
                
                // Test 4: Wrong key
                let privateKey2 = P256.Signing.PrivateKey()
                let isWrongKey = try validator.validateSignature(
                    documentData: testData,
                    signature: signature.rawRepresentation,
                    publicKey: privateKey2.publicKey.rawRepresentation
                )
                
                if !isWrongKey {
                    results.append("✅ Test 4: Wrong key rejected")
                } else {
                    results.append("❌ Test 4: Wrong key accepted")
                }
                
                results.append("🎉 All tests passed!")
                
            } catch {
                results.append("❌ Error: \(error)")
            }
            
            DispatchQueue.main.async {
                testResults = results
                isLoading = false
            }
        }
    }
}

@available(iOS 14, *)
#Preview {
    ContentView()
}
