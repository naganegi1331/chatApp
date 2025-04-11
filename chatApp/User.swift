import Foundation

// Make User conform to Codable and Identifiable
struct User: Identifiable, Codable {
    let id = UUID()
    var username: String
    var email: String // Keep email, although it might not be used in anonymous chat
} 