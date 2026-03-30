import Combine
import Foundation
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Alba", category: "ConversationStore")

// MARK: - Persisted Conversation
struct SavedConversation: Codable, Identifiable {
    let id: UUID
    let date: Date
    let messages: [SavedMessage]
    let language: String

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var preview: String {
        messages.last(where: { !$0.isUser })?.text.prefix(80).description ?? ""
    }
}

struct SavedMessage: Codable {
    let text: String
    let isUser: Bool
    let timestamp: Date
}

// MARK: - Conversation Store
final class ConversationStore {
    static let shared = ConversationStore()
    private let fileURL: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("alba_conversations.json")
        logger.info("📂 ConversationStore path: \(self.fileURL.path)")
    }

    /// Save or update a conversation by its ID (one entry per chat session)
    func saveConversation(id: UUID, messages: [Message], language: AppLanguage) {
        guard messages.count > 1 else { return }

        let saved = SavedConversation(
            id: id,
            date: Date(),
            messages: messages.map { SavedMessage(text: $0.text, isUser: $0.isUser, timestamp: $0.date) },
            language: language.rawValue
        )

        var existing = loadAllConversations()

        // Update existing conversation or insert new one
        if let idx = existing.firstIndex(where: { $0.id == id }) {
            existing[idx] = saved
        } else {
            existing.insert(saved, at: 0)
        }

        // Keep only last 50
        if existing.count > 50 {
            existing = Array(existing.prefix(50))
        }

        do {
            let data = try JSONEncoder().encode(existing)
            try data.write(to: fileURL)
            logger.info("💾 Saved conversation \(id) with \(messages.count) msgs. Total: \(existing.count)")
        } catch {
            logger.error("❌ Failed to save: \(error.localizedDescription)")
        }
    }

    func loadAllConversations() -> [SavedConversation] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logger.info("📭 No conversations file found")
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let conversations = try JSONDecoder().decode([SavedConversation].self, from: data)
            logger.info("📖 Loaded \(conversations.count) conversations")
            return conversations
        } catch {
            logger.error("❌ Failed to load conversations: \(error.localizedDescription)")
            return []
        }
    }

    func deleteConversation(id: UUID) {
        var conversations = loadAllConversations()
        conversations.removeAll { $0.id == id }
        do {
            let data = try JSONEncoder().encode(conversations)
            try data.write(to: fileURL)
            logger.info("🗑️ Deleted conversation \(id)")
        } catch {
            logger.error("❌ Failed to delete conversation: \(error.localizedDescription)")
        }
    }

    func deleteAll() {
        try? FileManager.default.removeItem(at: fileURL)
        logger.info("🗑️ All conversations deleted")
    }
}

// MARK: - Daily Rate Limiter
final class RateLimiter: ObservableObject {
    static let shared = RateLimiter()

    @Published var messagesUsedToday: Int = 0

    private let countKey = "alba_daily_message_count"
    private let dateKey = "alba_daily_message_date"

    private init() {
        resetIfNewDay()
    }

    /// Limit depends on whether the user signed in with Apple
    var dailyLimit: Int {
        let isRegistered = KeychainHelper.load(key: "appleUserIdentifier") != nil
        return isRegistered
            ? RemoteConfigService.shared.maxDailyChatMessages
            : RemoteConfigService.shared.maxDailyUnregisteredMessages
    }

    var messagesRemaining: Int {
        max(0, dailyLimit - messagesUsedToday)
    }

    var isLimitReached: Bool {
        messagesUsedToday >= dailyLimit
    }

    var usagePercentage: Double {
        guard dailyLimit > 0 else { return 0.0 }
        return Double(messagesUsedToday) / Double(dailyLimit)
    }

    func recordMessage() {
        resetIfNewDay()
        messagesUsedToday += 1
        UserDefaults.standard.set(messagesUsedToday, forKey: countKey)
        logger.info("📊 Message recorded. Used today: \(self.messagesUsedToday)/\(self.dailyLimit)")
    }

    private func resetIfNewDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let savedDate = UserDefaults.standard.object(forKey: dateKey) as? Date {
            let savedDay = calendar.startOfDay(for: savedDate)
            if today > savedDay {
                messagesUsedToday = 0
                UserDefaults.standard.set(0, forKey: countKey)
                UserDefaults.standard.set(today, forKey: dateKey)
                logger.info("🔄 New day detected. Counter reset.")
                return
            }
        } else {
            UserDefaults.standard.set(today, forKey: dateKey)
        }

        messagesUsedToday = UserDefaults.standard.integer(forKey: countKey)
    }
}
