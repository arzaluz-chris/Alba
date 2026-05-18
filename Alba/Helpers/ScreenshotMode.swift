import Foundation

struct ScreenshotMode {
    enum Screen: String {
        case chat
        case voice
    }

    let language: AppLanguage
    let screen: Screen

    static var current: ScreenshotMode? {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("--alba-screenshot") else { return nil }

        let languageRaw = value(after: "--alba-screenshot-lang", in: args) ?? AppLanguage.en.rawValue
        let screenRaw = value(after: "--alba-screenshot-screen", in: args) ?? Screen.chat.rawValue

        return ScreenshotMode(
            language: AppLanguage(rawValue: languageRaw) ?? .en,
            screen: Screen(rawValue: screenRaw) ?? .chat
        )
    }

    static var isActive: Bool {
        current != nil
    }

    var initialAppState: AppState {
        switch screen {
        case .chat, .voice:
            return .chat(initialContext: nil)
        }
    }

    var userName: String {
        switch language {
        case .es: return "María"
        case .en: return "Mary"
        }
    }

    private static func value(after flag: String, in args: [String]) -> String? {
        guard let index = args.firstIndex(of: flag),
              args.indices.contains(index + 1) else {
            return nil
        }
        return args[index + 1]
    }
}
