import Foundation

public struct PatternCategory: Sendable, Codable {
    let name: String
    let description: String
    let patterns: [SecurePattern]
}
