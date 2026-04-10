import Foundation

// MARK: - AI Personalization (simplified - no longer user-configurable)

struct AIPersonalization: Codable, Equatable {
    var style: String = "amigable"
    var length: String = "corta"
    var useEmojis: Bool = false
}
