import Foundation

public struct SecurePattern: Sendable, Codable {
    let pattern: String
    let replacement: String
    let description: String
    let priority: Int
}
