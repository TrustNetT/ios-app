import SwiftUI

@main
struct TrustNetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Content View (Dashboard)
struct ContentView: View {
    @State private var refreshing = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.6, green: 0.3, blue: 0.8),
                    Color(red: 0.1, green: 0.6, blue: 0.95)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TrustNet Node")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        Text("Node Operator Dashboard")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Status Card
                    VStack(spacing: 12) {
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                            Text("Node Status: Synced")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Block Height")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                Text("12,456")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Last Update")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                Text("2 min ago")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    
                    // Reputation Card
                    VStack(spacing: 12) {
                        Text("Reputation Score")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.black)
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("75 / 100")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color(red: 0.08, green: 0.57, blue: 0.76))
                                Text("Good Standing")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .trim(from: 0, to: 0.75)
                                    .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .frame(width: 80, height: 80)
                                    .rotationEffect(.degrees(-90))
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    
                    // TRUST Balance Card
                    VStack(spacing: 12) {
                        Text("TRUST Balance: 1,250.5")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.black)
                        Text("≈ $5,120.00 USD")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    
                    // Refresh Button
                    Button(action: {
                        refreshing = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            refreshing = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .rotationEffect(.degrees(refreshing ? 360 : 0))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: refreshing)
                            Text("Refresh")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.white)
                        .foregroundColor(Color(red: 0.08, green: 0.57, blue: 0.76))
                        .font(.system(size: 14, weight: .semibold))
                        .cornerRadius(8)
                    }
                    .disabled(refreshing)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    Spacer().frame(height: 20)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
