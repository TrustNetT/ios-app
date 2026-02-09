import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var isRefreshing = false
    
    var body: some View {
        ZStack {
            // Purple to blue gradient background
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
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Status Card
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            
                            Text("Node Status")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Text("Synced")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Block Height")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                                Text("12,456")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Last Update")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                                Text("2 min ago")
                                    .font(.system(size: 18, weight: .semibold))
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
                            VStack(alignment: .leading, spacing: 8) {
                                Text("75 / 100")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color(red: 0.08, green: 0.57, blue: 0.76))
                                
                                Text("Good Standing")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // Circular progress
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                                
                                Circle()
                                    .trim(from: 0, to: 0.75)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.34, green: 0.80, blue: 0.38),
                                                Color(red: 0.08, green: 0.57, blue: 0.76)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                            }
                            .frame(width: 80, height: 80)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    
                    // TRUST Balance Card
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "wallet.pass")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.08, green: 0.57, blue: 0.76))
                            
                            Text("TRUST Balance")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1,250.5 TRUST")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(red: 0.08, green: 0.57, blue: 0.76))
                            
                            Text("≈ $5,120.00 USD")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: { /* TODO: Register Identity */ }) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.badge.plus")
                                Text("Register Identity")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.white)
                            .foregroundColor(Color(red: 0.08, green: 0.57, blue: 0.76))
                            .font(.system(size: 14, weight: .semibold))
                            .cornerRadius(8)
                        }
                        
                        Button(action: { /* TODO: Verify Documents */ }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.shield")
                                Text("Verify Documents")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.white)
                            .foregroundColor(Color(red: 0.08, green: 0.57, blue: 0.76))
                            .font(.system(size: 14, weight: .semibold))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Refresh button
                    Button(action: {
                        isRefreshing = true
                        Task {
                            await viewModel.refreshNodeStatus()
                            isRefreshing = false
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRefreshing)
                            
                            Text("Refresh Status")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.white.opacity(0.9))
                        .foregroundColor(Color(red: 0.08, green: 0.57, blue: 0.76))
                        .font(.system(size: 14, weight: .semibold))
                        .cornerRadius(8)
                    }
                    .disabled(isRefreshing)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    Spacer().frame(height: 20)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.refreshNodeStatus()
            }
        }
    }
}

#Preview {
    let viewModel = AppViewModel()
    return DashboardView(viewModel: viewModel)
}
