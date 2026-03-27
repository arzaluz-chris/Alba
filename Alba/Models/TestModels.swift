import SwiftUI

// MARK: - Question Types
enum QuestionType {
    case singleChoice
    case textInput
    case genderSelection
}

// MARK: - Category
enum CategoryKey: String {
    case friendGender
    case support
    case trust
    case limits
    case assertiveness
    case name
}

// MARK: - Option
struct Option: Identifiable, Equatable {
    let id = UUID()
    let iconName: String
    let labelKey: String
    let labelFallback: String
    let value: Int

    init(iconName: String, label: String, value: Int) {
        self.iconName = iconName
        self.labelKey = ""
        self.labelFallback = label
        self.value = value
    }

    init(iconName: String, labelKey: String, labelFallback: String, value: Int) {
        self.iconName = iconName
        self.labelKey = labelKey
        self.labelFallback = labelFallback
        self.value = value
    }
}

// MARK: - Question
struct Question: Identifiable, Equatable {
    let id: UUID
    let rawTextEs: String
    let rawTextEn: String
    let type: QuestionType
    let optionsEs: [Option]?
    let optionsEn: [Option]?
    let category: CategoryKey

    init(rawTextEs: String, rawTextEn: String, type: QuestionType, optionsEs: [Option]?, optionsEn: [Option]?, category: CategoryKey) {
        self.id = UUID()
        self.rawTextEs = rawTextEs
        self.rawTextEn = rawTextEn
        self.type = type
        self.optionsEs = optionsEs
        self.optionsEn = optionsEn
        self.category = category
    }

    func rawText(for lang: AppLanguage) -> String {
        lang == .es ? rawTextEs : rawTextEn
    }

    func options(for lang: AppLanguage) -> [Option]? {
        lang == .es ? optionsEs : optionsEn
    }
}

// MARK: - Test Result
struct TestResult {
    let summaryAnalysis: String
    let summaryRecommendation: String
    let finalRating: String
    let color: Color
    let focusAreaKey: CategoryKey
    let focusAreaDisplay: String
    let friendName: String
}
