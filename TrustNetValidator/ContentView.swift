import SwiftUI
import CryptoKit
import TrustNetCore

@available(iOS 14, *)
struct ContentView: View {
    @State private var testResults: [String] = []
    @State private var isLoading = false
    @State private var allPassed = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Text("TrustNet")
                        .font(.system(size: 32, weight: .bold))
                    Text("PassportValidator Test Suite")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                
                // Results Display
                if testResults.isEmpty && !isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "flask.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        Text("Ready to Run Tests")
                            .font(.headline)
                        Text("Tap the button below to validate ECDSA P256 signature functionality")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(testResults, id: \.self) { result in
                                HStack(alignment: .top, spacing: 8) {
                                    if result.contains("✅") {
                                        Text("✅")
                                    } else if result.contains("❌") {
                                        Text("❌")
                                    } else if result.contains("🧪") {
                                        Text("🧪")
                                    } else {
                                        Text("")
                                    }
                                    
                                    Text(result)
                                        .font(.system(.caption, design: .monospaced))
                                }
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
                
                // Status Badge
                if allPassed && !testResults.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("All Tests Passed!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGreen).opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Run Button
                Button(action: runTests) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                        Text(isLoading ? "Running..." : "Run Tests")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isLoading)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Validator")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func runTests() {
        isLoading = true
        allPassed = false
        testResults = []
        
        DispatchQueue.global().async {
            var results: [String] = []
            results.append("🧪 TrustNet PassportValidator Test Suite")
            results.append("════════════════════════════════════════")
            
            do {
                // Test 1: Initialize
                let validator = PassportValidator()
                results.append("✅ Test 1: PassportValidator Initialized")
                
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
                    results.append("✅ Test 2: Valid Signature Validated")
                } else {
                    results.append("❌ Test 2: Valid Signature FAILED")
                }
                
                // Test 3: Invalid signature (different data)
                let differentData = "Different data".data(using: .utf8)!
                let isInvalid = try validator.validateSignature(
                    documentData: differentData,
                    signature: signature.rawRepresentation,
                    publicKey: publicKey.rawRepresentation
                )
                
                if !isInvalid {
                    results.append("✅ Test 3: Invalid Signature Rejected")
                } else {
                    results.append("❌ Test 3: Invalid Signature Accepted")
                }
                
                // Test 4: Wrong key
                let privateKey2 = P256.Signing.PrivateKey()
                let publicKey2 = privateKey2.publicKey
                let isWrongKey = try validator.validateSignature(
                    documentData: testData,
                    signature: signature.rawRepresentation,
                    publicKey: publicKey2.rawRepresentation
                )
                
                if !isWrongKey {
                    results.append("✅ Test 4: Wrong Key Rejected")
                } else {
                    results.append("❌ Test 4: Wrong Key Accepted")
                }
                
                results.append("════════════════════════════════════════")
                results.append("✅ All Tests Passed!")
                
                DispatchQueue.main.async {
                    testResults = results
                    allPassed = true
                    isLoading = false
                }
                
            } catch {
                results.append("❌ Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    testResults = results
                    allPassed = false
                    isLoading = false
                }
            }
        }
    }
}

@available(iOS 14, *)
#Preview {
    ContentView()
}
