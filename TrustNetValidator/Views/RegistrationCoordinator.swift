import SwiftUI

enum RegistrationScreen {
    case onboarding
    case nfcScanning
    case errorRecovery(GovernmentIDScannerError)
    case confirmation(RegistrationData)
    case blockchainReady
}

struct RegistrationCoordinator: View {
    @StateObject private var viewModel = RegistrationViewModel()
    @State private var currentScreen: RegistrationScreen = .onboarding
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.05, blue: 0.25),
                        Color(red: 0.0, green: 0.1, blue: 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Screen content
                VStack {
                    switch currentScreen {
                    case .onboarding:
                        OnboardingView(
                            currentScreen: $currentScreen,
                            viewModel: viewModel
                        )
                    case .nfcScanning:
                        NFCScanningView(
                            currentScreen: $currentScreen,
                            viewModel: viewModel
                        )
                    case .errorRecovery(let error):
                        ErrorRecoveryView(
                            error: error,
                            currentScreen: $currentScreen,
                            viewModel: viewModel
                        )
                    case .confirmation(let data):
                        ConfirmationView(
                            registrationData: data,
                            currentScreen: $currentScreen,
                            viewModel: viewModel
                        )
                    case .blockchainReady:
                        BlockchainReadyView(currentScreen: $currentScreen)
                    }
                }
            }
        }
        .environmentObject(viewModel)
    }
}

// MARK: - Preview
#Preview {
    RegistrationCoordinator()
}
