import SwiftUI

struct RegistrationView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var onRegistrationSuccess: () -> Void
    var onBackToLogin: () -> Void
    
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
                    Text("Create Account")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("Join TrustNet")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 20)
                
                // Registration Form
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
                        SecureField("Enter password", text: $password)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        SecureField("Confirm password", text: $confirmPassword)
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
                    
                    // Register Button
                    Button(action: performRegistration) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Create Account")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.white)
                    .foregroundColor(Color(red: 0.08, green: 0.57, blue: 0.76))
                    .cornerRadius(8)
                    .disabled(isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Back to Login Link
                Button("Back to Login") {
                    onBackToLogin()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.bottom, 30)
            }
        }
    }
    
    private func performRegistration() {
        isLoading = true
        errorMessage = nil
        
        if !validateInputs() {
            isLoading = false
            return
        }
        
        // Simulate registration delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // TODO: Make actual API call here
            
            // Set login cookie after successful registration
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
            onRegistrationSuccess()
        }
    }
    
    private func validateInputs() -> Bool {
        if email.isEmpty {
            errorMessage = "Email is required"
            return false
        }
        if password.isEmpty {
            errorMessage = "Password is required"
            return false
        }
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            return false
        }
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        return true
    }
}

#Preview {
    RegistrationView(
        onRegistrationSuccess: {},
        onBackToLogin: {}
    )
}
