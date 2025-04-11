import SwiftUI
import MultipeerConnectivity // Needed for MCSessionState comparison

struct ConnectView: View {
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        // Use NavigationStack for newer navigation features if needed, NavigationView is okay too
        NavigationView {
            VStack(spacing: 20) {
                
                // Show different UI based on connection state
                switch viewModel.connectionState {
                case .notConnected:
                    if viewModel.isConnecting { // Started browsing but not yet connecting/connected
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Searching for nearby devices...")
                                .padding(.top)
                        }
                    } else {
                        // Initial state or after explicit disconnect before search restarts
                        VStack(spacing: 30) {
                            Image(systemName: "person.2.wave.2.fill") // Updated icon
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("Ready to connect")
                                .font(.title2)
                            Text("Ensure Wi-Fi or Bluetooth is enabled.")
                                .font(.caption)
                                .foregroundColor(.gray)
                            // Button removed - searching starts automatically
                        }
                    }
                case .connecting:
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Connecting...")
                            .padding(.top)
                    }
                    
                case .connected:
                    if let connectedUser = viewModel.connectedUser {
                        VStack(spacing: 20) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            Text("Connected with:")
                                .font(.headline)
                            Text(connectedUser.username)
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            // Navigate to ChatView only when connected
                            NavigationLink(destination: ChatView(viewModel: viewModel)) {
                                Text("Start Chatting")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            
                            Button(action: {
                                viewModel.disconnect() // Disconnect action
                            }) {
                                Text("Disconnect")
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                         // Should briefly show connecting then transition here if user info not yet received
                         ProgressView()
                         Text("Finalizing connection...")
                    }
                    
                @unknown default:
                    Text("Unknown connection state.")
                }
            }
            .padding()
            .navigationTitle("Connect Nearby") // Updated title
            // Optional: Add toolbar items if needed later
        }
    }
}

#Preview {
    ConnectView(viewModel: ChatViewModel())
} 