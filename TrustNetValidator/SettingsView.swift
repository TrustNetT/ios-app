import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var editingEndpoint = false
    @State private var tempEndpoint = ""
    
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
            
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Settings")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Configure your node connection")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // API Endpoint Setting
                VStack(spacing: 12) {
                    HStack {
                        Text("API Endpoint")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button(action: {
                            editingEndpoint = true
                            tempEndpoint = viewModel.apiEndpoint
                        }) {
                            Text("Edit")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(red: 0.08, green: 0.57, blue: 0.76))
                        }
                    }
                    
                    Text(viewModel.apiEndpoint)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(8)
                .padding(.horizontal, 20)
                
                VStack(spacing: 12) {
                    Text("Version")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.black)
                    
                    Text("TrustNet iOS 1.0.0")
                        .font(.system(size: 14, weight: .regular))
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
        .sheet(isPresented: $editingEndpoint) {
            EditEndpointSheet(
                endpoint: $tempEndpoint,
                isPresented: $editingEndpoint,
                onSave: {
                    viewModel.updateApiEndpoint(tempEndpoint)
                    editingEndpoint = false
                }
            )
        }
    }
}

struct EditEndpointSheet: View {
    @Binding var endpoint: String
    @Binding var isPresented: Bool
    var onSave: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("API Endpoint", text: $endpoint)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Edit API Endpoint")
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false },
                trailing: Button("Save") {
                    onSave()
                }
            )
        }
    }
}

#Preview {
    let viewModel = AppViewModel()
    return SettingsView(viewModel: viewModel)
}
