import Foundation
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Alba", category: "DeclinedFriendsStore")

/// Tracks friend names the user has explicitly declined to evaluate via the chat.
/// Once a name is here, AlbaAI must stop offering the Alba Test for that person.
final class DeclinedFriendsStore {
    static let shared = DeclinedFriendsStore()

    private let defaults = UserDefaults.standard
    private let key = "alba_declined_friends"

    private init() {}

    /// Loads the persisted list, normalized to lowercase for comparison.
    func declinedNames() -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    func isDeclined(_ name: String) -> Bool {
        let target = name.lowercased()
        return declinedNames().contains { $0.lowercased() == target }
    }

    func decline(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var current = declinedNames()
        guard !current.contains(where: { $0.lowercased() == trimmed.lowercased() }) else { return }
        current.append(trimmed)
        defaults.set(current, forKey: key)
        logger.info("🚫 Friend declined for evaluation: \(trimmed)")
    }

    /// Removes a name from the declined list (e.g., if the user later evaluates them manually).
    func remove(_ name: String) {
        let target = name.lowercased()
        let current = declinedNames().filter { $0.lowercased() != target }
        defaults.set(current, forKey: key)
    }

    func clearAll() {
        defaults.removeObject(forKey: key)
        logger.info("🗑️ Cleared declined friends list")
    }
}
