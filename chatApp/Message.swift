import Foundation

struct Message: Identifiable, Codable {
    let id = UUID()
    var senderId: UUID
    var receiverId: UUID
    var content: String
    let timestamp: Date = Date()
} 