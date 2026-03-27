import Combine
import SwiftUI

final class LanguageManager: ObservableObject {
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "app_language")
        }
    }

    init() {
        // Default to system language or Spanish
        let preferredLang = Locale.current.language.languageCode?.identifier ?? "es"
        let savedLang = UserDefaults.standard.string(forKey: "app_language")
        if let saved = savedLang, let lang = AppLanguage(rawValue: saved) {
            self.language = lang
        } else {
            self.language = preferredLang.hasPrefix("en") ? .en : .es
        }
    }

    var locale: Locale {
        Locale(identifier: language.localeIdentifier)
    }
}
