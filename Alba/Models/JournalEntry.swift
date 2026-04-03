import Foundation

// MARK: - Journal Mood

enum JournalMood: String, Codable, CaseIterable, Identifiable {
    case positive, negative, neutral

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .positive: return "face.smiling"
        case .negative: return "cloud.rain"
        case .neutral: return "minus.circle"
        }
    }

    var color: String {
        switch self {
        case .positive: return "green"
        case .negative: return "red"
        case .neutral: return "gray"
        }
    }

    func label(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.positive, .es): return "Positivo"
        case (.positive, .en): return "Positive"
        case (.negative, .es): return "Negativo"
        case (.negative, .en): return "Negative"
        case (.neutral, .es): return "Neutral"
        case (.neutral, .en): return "Neutral"
        }
    }
}

// MARK: - Journal Entry

struct JournalEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let friendName: String
    let text: String
    let mood: JournalMood?

    init(id: UUID = UUID(), date: Date = Date(), friendName: String, text: String, mood: JournalMood? = nil) {
        self.id = id
        self.date = date
        self.friendName = friendName
        self.text = text
        self.mood = mood
    }

    var displayDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    var shortDate: String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f.string(from: date)
    }
}
