import SwiftUI

// MARK: - App Navigation State
enum AppState: Equatable {
    case splash
    case intro
    case signIn
    case onboarding
    case welcome
    case chat(initialContext: String? = nil)
    case albaTest
    case newTestForFriend(friendName: String)
    case reEvaluate(friendName: String, friendGender: Gender)
    case albaBlocks
    case journal
}

// MARK: - Gender
enum Gender: String, Codable {
    case chico
    case chica
}

// MARK: - App Language
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case es, en

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .es: return "es"
        case .en: return "en"
        }
    }

    var displayName: String {
        switch self {
        case .es: return "Español"
        case .en: return "English"
        }
    }
}
