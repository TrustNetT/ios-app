import SwiftUI

struct SplashScreenView: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    var onSplashComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.7, blue: 0.5),
                    Color(red: 0.05, green: 0.5, blue: 0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // Logo
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .opacity(opacity)
                    .scaleEffect(scale)
                
                // App Name
                VStack(spacing: 8) {
                    Text("TrustNet")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Distributed Trust Network")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(opacity)
                
                Spacer()
                
                // Loading indicator
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2, anchor: .center)
                    .opacity(opacity)
                    .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // Animate logo and text
            withAnimation(.easeInOut(duration: 0.8)) {
                opacity = 1
                scale = 1
            }
            
            // Dismiss splash after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    onSplashComplete()
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(onSplashComplete: {})
}
