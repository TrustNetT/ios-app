import SwiftUI

@main
struct TrustNetApp: App {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView(viewModel: viewModel)
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.pie")
                    }
                
                SettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .preferredColorScheme(nil)
        }
    }
}

// MARK: - App ViewModel
@MainActor
class AppViewModel: ObservableObject {
    @Published var nodeStatus: NodeStatus = .loading
    @Published var apiEndpoint: String = UserDefaults.standard.string(forKey: "nodeApiEndpoint") ?? "http://localhost:1317"
    @Published var hasError: Bool = false
    @Published var errorMessage: String = ""
    
    func updateApiEndpoint(_ endpoint: String) {
        self.apiEndpoint = endpoint
        UserDefaults.standard.set(endpoint, forKey: "nodeApiEndpoint")
    }
    
    func refreshNodeStatus() async {
        nodeStatus = .loading
        
        // Simulate API call - replace with real NodeAPIService later
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            
            // Mock data for testing
            nodeStatus = .loaded(
                NodeData(
                    address: "trustnet1x5q6g6wqm0q7x5q6g6wqm0q7x5q6g6wqk95mzr",
                    status: "synced",
                    reputation: 75,
                    trustBalance: 1250.5,
                    height: 12_456,
                    lastUpdate: Date()
                )
            )
        } catch {
            nodeStatus = .error("Failed to load node status")
            errorMessage = error.localizedDescription
            hasError = true
        }
    }
    
    func clearError() {
        hasError = false
        errorMessage = ""
    }
}

// MARK: - Data Models
enum NodeStatus {
    case idle
    case loading
    case loaded(NodeData)
    case error(String)
}

struct NodeData: Codable {
    let address: String
    let status: String // "synced", "syncing", "offline"
    let reputation: Int // 0-100
    let trustBalance: Double
    let height: Int // block height
    let lastUpdate: Date
}
