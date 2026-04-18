import Foundation

enum MessageAction: Equatable {
    case none
    case takeTest(friendName: String) // Embed "Take Test" card for this friend
    case testDeclined(friendName: String) // User dismissed the offer for this friend
    case voiceCallSummary(durationSeconds: Int) // Pill summarizing a finished voice call
}

struct Message: Identifiable, Equatable {
    let id = UUID()
    var text: String
    let isUser: Bool
    let date = Date()
    var action: MessageAction = .none
}

struct APIMessageContent: Codable {
    let role: String
    let parts: [APIPart]
}

struct APIPart: Codable {
    let text: String
}
