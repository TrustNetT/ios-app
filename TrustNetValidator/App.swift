import SwiftUI

@main
struct TrustNetApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.05, blue: 0.25),  // Dark purple
                        Color(red: 0.0, green: 0.1, blue: 0.3)     // Dark blue
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 8) {
                        Text("TrustNet")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Digital Identity Registration")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Status Card
                    VStack(spacing: 16) {
                        HStack {
                            Text("Backend Status")
                                .font(.headline)
                            Spacer()
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                            Text("Ready")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(.bottom, 8)
                        
                        Divider()
                            .opacity(0.3)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ComponentStatus(
                                name: "Phase 0: Models & Errors",
                                status: "✅ Complete",
                                lines: "438 lines"
                            )
                            
                            ComponentStatus(
                                name: "Phase 1A: ICAO9303 Validator",
                                status: "✅ Complete",
                                lines: "238 lines"
                            )
                            
                            ComponentStatus(
                                name: "Phase 1B: Biometric Hasher",
                                status: "✅ Complete",
                                lines: "316 lines"
                            )
                            
                            ComponentStatus(
                                name: "Phase 1C: Key Generator",
                                status: "✅ Complete",
                                lines: "362 lines"
                            )
                            
                            ComponentStatus(
                                name: "Phase 1D: Keychain Manager",
                                status: "✅ Complete",
                                lines: "438 lines"
                            )
                            
                            ComponentStatus(
                                name: "Phase 2: NFC Scanner",
                                status: "✅ Complete",
                                lines: "438 lines"
                            )
                            
                            ComponentStatus(
                                name: "Phase 3: SwiftUI Interface",
                                status: "⏳ Design Ready",
                                lines: "Design: 755 lines"
                            )
                        }
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    
                    Spacer()
                    
                    // Action Button
                    VStack(spacing: 12) {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Begin Registration")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue,
                                        Color(red: 0.0, green: 1.0, blue: 1.0)  // cyan-like color
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Text("Phase 3 UI coming next")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(24)
            }
        }
    }
}

struct ComponentStatus: View {
    let name: String
    let status: String
    let lines: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(lines)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text(status)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(status.contains("Complete") ? .green : .orange)
        }
    }
}
