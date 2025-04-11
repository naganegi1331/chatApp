import Foundation
import SwiftUI
import MultipeerConnectivity

class ChatViewModel: NSObject, ObservableObject {
    private let serviceType = "hiro-chatapp"
    private var myPeerID: MCPeerID
    private var session: MCSession
    private var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser
    private var nearbyServiceBrowser: MCNearbyServiceBrowser
    private var connectedPeerID: MCPeerID?

    @Published var currentUser: User
    @Published var connectedUser: User?
    @Published var messages: [Message] = []
    @Published var isConnecting: Bool = false
    @Published var connectionState: MCSessionState = .notConnected
    
    override init() {
        let username = "Anon-\(Int.random(in: 100...999))"
        self.currentUser = User(username: username, email: "")
        self.myPeerID = MCPeerID(displayName: username)

        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)

        let discoveryInfo = ["username": username]
        self.nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        self.nearbyServiceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)

        super.init()

        self.session.delegate = self
        self.nearbyServiceAdvertiser.delegate = self
        self.nearbyServiceBrowser.delegate = self

        startAdvertisingAndBrowsing()
    }

    deinit {
        stopSession()
    }

    func startAdvertisingAndBrowsing() {
        print("Starting advertising and browsing...")
        nearbyServiceAdvertiser.startAdvertisingPeer()
        nearbyServiceBrowser.startBrowsingForPeers()
        isConnecting = true
        connectionState = .connecting
    }

    func stopSession() {
        print("Stopping session...")
        nearbyServiceAdvertiser.stopAdvertisingPeer()
        nearbyServiceBrowser.stopBrowsingForPeers()
        session.disconnect()
        connectedPeerID = nil
        connectedUser = nil
        messages.removeAll()
        isConnecting = false
        connectionState = .notConnected
    }
    
    func disconnect() {
        stopSession()
        startAdvertisingAndBrowsing()
    }

    func sendMessage(content: String) {
        guard let peerID = connectedPeerID, connectionState == .connected else {
            print("Error: Not connected to anyone.")
            return
        }
        
        let message = Message(senderId: currentUser.id, receiverId: connectedUser?.id ?? UUID(), content: content)
        messages.append(message)

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)
            try session.send(data, toPeers: [peerID], with: .reliable)
            print("Message sent.")
        } catch {
            print("Error sending message: \(error.localizedDescription)")
            messages.removeLast()
        }
    }

    private func sendCurrentUser(to peerID: MCPeerID) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(currentUser)
            try session.send(data, toPeers: [peerID], with: .reliable)
            print("Sent current user info to \(peerID.displayName)")
        } catch {
            print("Error sending user info: \(error.localizedDescription)")
        }
    }
}

extension ChatViewModel: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectionState = state
            switch state {
            case .connected:
                print("Connected to: \(peerID.displayName)")
                self.connectedPeerID = peerID
                self.isConnecting = false
                self.nearbyServiceBrowser.stopBrowsingForPeers()
                self.sendCurrentUser(to: peerID)
            case .connecting:
                print("Connecting to: \(peerID.displayName)")
                self.isConnecting = true
            case .notConnected:
                print("Not connected: \(peerID.displayName)")
                if self.connectedPeerID == peerID {
                    self.connectedPeerID = nil
                    self.connectedUser = nil
                    self.isConnecting = false
                    self.messages.removeAll()
                    self.nearbyServiceBrowser.startBrowsingForPeers()
                    self.isConnecting = true
                }
            @unknown default:
                print("Unknown state received: \(state)")
                self.isConnecting = false
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            print("Received data from \(peerID.displayName)")
            let decoder = JSONDecoder()
            if let message = try? decoder.decode(Message.self, from: data) {
                print("Decoded as Message: \(message.content)")
                if peerID == self.connectedPeerID {
                    self.messages.append(message)
                } else {
                    print("Received message from unexpected peer: \(peerID.displayName)")
                }
            } else if let user = try? decoder.decode(User.self, from: data) {
                print("Decoded as User: \(user.username)")
                if peerID == self.connectedPeerID {
                    self.connectedUser = user
                } else {
                    print("Received user info from unexpected peer: \(peerID.displayName)")
                }
            } else {
                print("Could not decode received data.")
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Received stream")
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Started receiving resource: \(resourceName)")
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("Finished receiving resource: \(resourceName)")
    }
}

extension ChatViewModel: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Received invitation from \(peerID.displayName)")
        DispatchQueue.main.async {
            if self.connectionState == .notConnected && self.connectedPeerID == nil {
                print("Accepting invitation from \(peerID.displayName)")
                invitationHandler(true, self.session)
                self.isConnecting = true
            } else {
                print("Rejecting invitation from \(peerID.displayName) (already connecting/connected)")
                invitationHandler(false, nil)
            }
        }
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to start advertising: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isConnecting = false
        }
    }
}

extension ChatViewModel: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName)")
        DispatchQueue.main.async {
            if self.connectionState == .notConnected && self.connectedPeerID == nil && !self.isConnecting {
                print("Inviting peer: \(peerID.displayName)")
                browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 30)
                self.isConnecting = true
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Failed to start browsing: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isConnecting = false
        }
    }
} 
