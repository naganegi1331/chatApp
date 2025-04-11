import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var messageText: String = ""
    
    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { scrollViewProxy in
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            // Determine if the message is from the current user or the connected user
                            let isCurrentUser = message.senderId == viewModel.currentUser.id
                            
                            HStack {
                                if isCurrentUser {
                                    Spacer() // Push sent messages to the right
                                }
                                
                                Text(message.content)
                                    .padding(10)
                                    .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.3))
                                    .foregroundColor(isCurrentUser ? .white : .primary)
                                    .cornerRadius(10)
                                
                                if !isCurrentUser {
                                    Spacer() // Push received messages to the left
                                }
                            }
                            .id(message.id) // Add ID for scrolling
                        }
                    }
                    .padding()
                    .onChange(of: viewModel.messages.count) { _, _ in
                        // Scroll to the bottom when new messages arrive
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            HStack {
                TextField("Enter message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .padding(.horizontal)
                }
                // Disable button if not connected or message is empty
                .disabled(viewModel.connectionState != .connected || messageText.isEmpty)
            }
            .padding(.bottom)
        }
        .navigationTitle(viewModel.connectedUser?.username ?? "Chat") // Use connected user's name
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // Optional: Decide if you want to disconnect when leaving the chat view
            // viewModel.disconnect() 
        }
    }

    func sendMessage() {
        viewModel.sendMessage(content: messageText)
        messageText = "" // Clear the input field
    }
}

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            Text(message.content)
                .padding()
                .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isCurrentUser ? .white : .primary)
                .cornerRadius(16)
            
            if !isCurrentUser { Spacer() }
        }
    }
} 