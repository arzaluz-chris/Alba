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
}
