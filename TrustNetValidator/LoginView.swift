import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var onLoginSuccess: () -> Void
    var onRegisterTapped: () -> Void
    
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
            
            VStack(spacing: 24) {
                Spacer()
                
                // Title
                VStack(spacing: 8) {
                    Text("TrustNet")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                    Text("Decentralized Trust Network")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 20)
                
                // Login Form
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        TextField("Enter your email", text: $email)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .textContentType(.emailAddress)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        SecureField("Enter your password", text: $password)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    
                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Login Button
                    Button(action: performLogin) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Login")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.white)
                    .foregroundColor(Color(red: 0.08, green: 0.57, blue: 0.76))
                    .cornerRadius(8)
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Register Link
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    Button("Create one") {
                        onRegisterTapped()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    private func performLogin() {
        isLoading = true
        errorMessage = nil
        
        // Simulate login delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // TODO: Make actual API call here
            if validateInputs() {
                // Set login cookie (simplified for demo)
                HTTPCookieStorage.shared.cookieAcceptPolicy = .always
                let cookie = HTTPCookie(properties: [
                    .name: "trustnet_session",
                    .value: UUID().uuidString,
                    .domain: "trustnet.local",
                    .path: "/"
                ])
                if let cookie = cookie {
                    HTTPCookieStorage.shared.cookies(for: URL(string: "https://trustnet.local") ?? URL(fileURLWithPath: "/"))?.append(cookie)
                }
                
                isLoading = false
                onLoginSuccess()
            } else {
                errorMessage = "Invalid credentials. Please try again."
                isLoading = false
            }
        }
    }
    
    private func validateInputs() -> Bool {
        // TODO: Add proper validation and API call
        return !email.isEmpty && !password.isEmpty
    }
}

#Preview {
    LoginView(
        onLoginSuccess: {},
        onRegisterTapped: {}
    )
}
