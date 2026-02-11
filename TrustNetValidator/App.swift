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
    
    // MARK: - State Management
    
    private func completeOnboarding() {
        // Check if user has valid session
        if checkLoginCookie() {
            appState = .dashboard
        } else {
            appState = .login
        }
    }
    
    /// Check if user has a valid login cookie
    private func checkLoginCookie() -> Bool {
        // Check UserDefaults for stored session token
        return UserDefaults.standard.string(forKey: "trustnet_session_token") != nil
    }
}

// MARK: - App State Enum
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
    @State private var userName: String = ""
    
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
                    VStack(alignment: .leading, spacing: 8) {
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
    @State private var animateGradient = false
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
                
                // Logo/Title
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
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.5)
            }
            .padding(40)
        }
        .onAppear {
            // Display splash for at least 3 seconds
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
                // Header
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
                
                // Form
                VStack(spacing: 16) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        TextField("Enter your email", text: $email)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding(12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        SecureField("Enter your password", text: $password)
                            .padding(12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    // Error message
                    if showError {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()
                
                // Login Button
                Button(action: performLogin) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.white)
                .foregroundColor(Color(red: 0.6, green: 0.3, blue: 0.8))
                .font(.system(size: 16, weight: .semibold))
                .cornerRadius(8)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                
                // Register button
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
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if email.contains("@") && password.count >= 6 {
                // Simulate successful login
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
                    // Header
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
                    
                    // Form
                    VStack(spacing: 16) {
                        // Full Name
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
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            TextField("Enter your email", text: $email)
                                .textContentType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            SecureField("At least 6 characters", text: $password)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            SecureField("Confirm your password", text: $confirmPassword)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        // Error message
                        if showError {
                            Text(errorMessage)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    Spacer()
                    
                    // Register Button
                    Button(action: performRegistration) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Create Account")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.white)
                    .foregroundColor(Color(red: 0.6, green: 0.3, blue: 0.8))
                    .font(.system(size: 16, weight: .semibold))
                    .cornerRadius(8)
                    .disabled(isLoading || fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                    
                    // Back to login
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
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if email.contains("@") {
                // Simulate successful registration
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
