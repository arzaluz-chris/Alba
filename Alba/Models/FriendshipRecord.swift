import Foundation

struct FriendshipRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let friendName: String
    let friendGender: String // "chico" or "chica"
    let overallScore: Double
    let categoryScores: [String: Double]
    let rating: String
    let focusArea: String
    let language: String
    /// Maps question index (0-based, singleChoice only) to the selected option value (1-3)
    var answersByIndex: [Int: Int]?

    var displayDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    var ratingColor: String {
        if overallScore >= 2.8 { return "high" }
        else if overallScore <= 1.8 { return "low" }
        else { return "neutral" }
    }

    func localizedRating(for language: AppLanguage) -> String {
        switch normalizedRating {
        case "very strong friendship", "amistad muy solida", "amistad muy sólida":
            return language == .es ? "Amistad Muy Sólida" : "Very Strong Friendship"
        case "unstable friendship", "amistad inestable":
            return language == .es ? "Amistad Inestable" : "Unstable Friendship"
        case "friendship in progress", "amistad en progreso":
            return language == .es ? "Amistad en Progreso" : "Friendship in Progress"
        default:
            return rating
        }
    }

    func localizedFocusArea(for language: AppLanguage) -> String {
        switch normalizedFocusArea {
        case "support", "apoyo":
            return language == .es ? "Apoyo" : "Support"
        case "trust", "confianza":
            return language == .es ? "Confianza" : "Trust"
        case "boundaries", "limits", "limites", "límites":
            return language == .es ? "Límites" : "Boundaries"
        case "assertiveness", "asertividad":
            return language == .es ? "Asertividad" : "Assertiveness"
        default:
            return focusArea
        }
    }

    private var normalizedRating: String {
        rating.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private var normalizedFocusArea: String {
        focusArea.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
