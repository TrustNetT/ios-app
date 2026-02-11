import SwiftUI

@main
struct TrustNetApp: App {
    @State private var appState: AppState = .splash
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appState {
                case .splash:
                    SplashScreenView {
                        completeOnboarding()
                    }
                case .login:
                    LoginView(appState: $appState)
                case .registration:
                    RegistrationView(appState: $appState)
                case .dashboard:
                    ContentView(appState: $appState)
                }
            }
        }
    }
    
    private func completeOnboarding() {
        if checkLoginCookie() {
            appState = .dashboard
        } else {
            appState = .login
        }
    }
    
    private func checkLoginCookie() -> Bool {
        return UserDefaults.standard.string(forKey: "trustnet_session_token") != nil
    }
}

enum AppState {
    case splash
    case login
    case registration
    case dashboard
}

// MARK: - Content View (Dashboard)
struct ContentView: View {
    @Binding var appState: AppState
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
                    // Header with Logout
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TrustNet Node")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            Text("Node Operator Dashboard")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                        Button(action: logout) {
                            Image(systemName: "power")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
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
                    
                    Spacer()
                }
            }
        }
    }
    
    private func logout() {
        UserDefaults.standard.removeObject(forKey: "trustnet_session_token")
        UserDefaults.standard.removeObject(forKey: "trustnet_user_name")
        withAnimation {
            appState = .login
        }
    }
}

// MARK: - Splash Screen
struct SplashScreenView: View {
    let onComplete: () -> Void
    
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
            
            VStack(spacing: 20) {
                Spacer()
                
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("TrustNet")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Node Operator")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
            }
            .padding(40)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    onComplete()
                }
            }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @Binding var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
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
                VStack(spacing: 8) {
                    Text("Welcome Back")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("Sign in to your TrustNet account")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 24)
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        TextField("Enter your email", text: $email)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        SecureField("Enter your password", text: $password)
                            .padding(12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    if showError {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()
                
                Button(action: performLogin) {
                    Text(isLoading ? "Signing in..." : "Sign In")
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.white)
                        .foregroundColor(Color(red: 0.6, green: 0.3, blue: 0.8))
                        .font(.system(size: 16, weight: .semibold))
                        .cornerRadius(8)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                
                Button(action: {
                    withAnimation {
                        appState = .registration
                    }
                }) {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.white.opacity(0.7))
                        Text("Register")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .font(.system(size: 14))
                }
            }
            .padding(24)
        }
    }
    
    private func performLogin() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if email.contains("@") && password.count >= 6 {
                UserDefaults.standard.set("mock_session_token_123", forKey: "trustnet_session_token")
                UserDefaults.standard.set(email.components(separatedBy: "@")[0], forKey: "trustnet_user_name")
                
                withAnimation {
                    appState = .dashboard
                }
            } else {
                showError = true
                errorMessage = "Invalid email or password"
                isLoading = false
            }
        }
    }
}

// MARK: - Registration View
struct RegistrationView: View {
    @Binding var appState: AppState
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
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
                VStack(spacing: 24) {
                    HStack {
                        Button(action: {
                            withAnimation {
                                appState = .login
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        Text("Join the TrustNet network")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            TextField("Enter your name", text: $fullName)
                                .textContentType(.name)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            TextField("Enter your email", text: $email)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            SecureField("At least 6 characters", text: $password)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            SecureField("Confirm your password", text: $confirmPassword)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        if showError {
                            Text(errorMessage)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: performRegistration) {
                        Text(isLoading ? "Creating..." : "Create Account")
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color.white)
                            .foregroundColor(Color(red: 0.6, green: 0.3, blue: 0.8))
                            .font(.system(size: 16, weight: .semibold))
                            .cornerRadius(8)
                    }
                    .disabled(isLoading || fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                    
                    Button(action: {
                        withAnimation {
                            appState = .login
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundColor(.white.opacity(0.7))
                            Text("Sign In")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 14))
                    }
                }
                .padding(24)
            }
        }
    }
    
    private func performRegistration() {
        if password != confirmPassword {
            showError = true
            errorMessage = "Passwords do not match"
            return
        }
        
        if password.count < 6 {
            showError = true
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if email.contains("@") {
                UserDefaults.standard.set("mock_session_token_123", forKey: "trustnet_session_token")
                UserDefaults.standard.set(fullName, forKey: "trustnet_user_name")
                
                withAnimation {
                    appState = .dashboard
                }
            } else {
                showError = true
                errorMessage = "Invalid email address"
                isLoading = false
            }
        }
    }
}
