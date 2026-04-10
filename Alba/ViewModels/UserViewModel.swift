import Combine
import SwiftUI

final class UserViewModel: ObservableObject {
    @Published var userName: String = "" {
        didSet { UserDefaults.standard.set(userName, forKey: "user_name") }
    }
    @Published var selectedGender: Gender? = nil {
        didSet {
            if let g = selectedGender {
                UserDefaults.standard.set(g.rawValue, forKey: "user_gender")
            }
        }
    }
    @Published var hasCompletedOnboarding: Bool = false {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "has_completed_onboarding") }
    }
    @Published var hasCompletedAIOnboarding: Bool = false {
        didSet { UserDefaults.standard.set(hasCompletedAIOnboarding, forKey: "has_completed_ai_onboarding") }
    }

    init() {
        self.userName = UserDefaults.standard.string(forKey: "user_name") ?? ""
        if let genderRaw = UserDefaults.standard.string(forKey: "user_gender") {
            self.selectedGender = Gender(rawValue: genderRaw)
        }
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "has_completed_onboarding")
        self.hasCompletedAIOnboarding = UserDefaults.standard.bool(forKey: "has_completed_ai_onboarding")
    }

    var isNameValid: Bool {
        guard userName.count >= 3 else { return false }
        guard userName.prefix(1).uppercased() == userName.prefix(1) else { return false }

        let forbiddenSymbols = CharacterSet(charactersIn: "@#$&*()'\"%\\-+=/;:,.!?¿¡€£¥_^[]{}><\\…~|§").union(.decimalDigits)
        if userName.rangeOfCharacter(from: forbiddenSymbols) != nil { return false }

        var emojiCount = 0
        for scalar in userName.unicodeScalars {
            if scalar.properties.isEmoji { emojiCount += 1 }
        }
        if emojiCount > 1 { return false }

        return true
    }

    var isGenderSelected: Bool { selectedGender != nil }
    var isFormValid: Bool { isNameValid && isGenderSelected }

    func cleanName(_ name: String) -> String {
        let forbidden = "@#$&*()'\"%\\-+=/;:,.!?¿¡€£¥_^[]{}><\\…~|§"
        let set = CharacterSet(charactersIn: forbidden).union(.decimalDigits)
        var cleaned = name.components(separatedBy: set).joined()

        var emojiFound = false
        cleaned = cleaned.filter { char in
            if char.unicodeScalars.contains(where: { $0.properties.isEmoji }) {
                if !emojiFound {
                    emojiFound = true
                    return true
                }
                return false
            }
            return true
        }
        return cleaned
    }
}
