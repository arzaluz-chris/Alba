import Combine
import SwiftUI

final class TestViewModel: ObservableObject {
    private let userViewModel: UserViewModel

    @Published var friendGenderSelection: Gender? = nil
    @Published var selectedAnswers: [UUID: Option] = [:]
    @Published var friendNameInput: String = ""
    @Published var shouldSkipName: Bool = false
    @Published var currentQuestionIndex: Int = 0
    @Published var language: AppLanguage = .es
    @Published var questions: [Question] = []

    /// Re-evaluation mode: stores previous answer values by question index
    var previousAnswers: [Int: Int] = [:]
    /// True if this is a re-evaluation of an existing friend
    var isReEvaluation: Bool = false

    init(userViewModel: UserViewModel) {
        self.userViewModel = userViewModel
        self.questions = Self.buildQuestions()
    }

    /// Set up for a new test with a pre-known friend name (from chat [EVALUATE: name])
    func setupNewTestForFriend(name: String) {
        friendNameInput = name
        shouldSkipName = true
    }

    /// Set up for re-evaluating an existing friend (skips gender + name questions)
    func setupReEvaluation(friendName: String, friendGender: Gender) {
        isReEvaluation = true
        friendGenderSelection = friendGender
        friendNameInput = friendName
        shouldSkipName = false

        // Load previous answers from journal
        if let lastRecord = FriendshipStore.shared.latestRecord(for: friendName),
           let prev = lastRecord.answersByIndex {
            previousAnswers = prev
        }

        // Skip gender question (index 0), start at question 1
        currentQuestionIndex = 1
    }

    // MARK: - Question Bank
    static func buildQuestions() -> [Question] {
        [
            Question(rawTextEs: "La persona de la que estas pensando es...",
                     rawTextEn: "The person you're thinking of is...",
                     type: .genderSelection, optionsEs: nil, optionsEn: nil, category: .friendGender),

            Question(rawTextEs: "¿Te esfuerzas en hacer que tu amig(@) se sienta feliz y comod(@) contigo?",
                     rawTextEn: "Do you try to make your friend feel happy and comfortable with you?",
                     type: .singleChoice,
                     optionsEs: [Option(iconName: "circle", label: "Si", value: 3),
                                 Option(iconName: "circle", label: "A veces", value: 2),
                                 Option(iconName: "circle", label: "No", value: 1)],
                     optionsEn: [Option(iconName: "circle", label: "Yes", value: 3),
                                 Option(iconName: "circle", label: "Sometimes", value: 2),
                                 Option(iconName: "circle", label: "No", value: 1)],
                     category: .support),

            Question(rawTextEs: "¿Cuando tienes un problema, puedes confiar en el(la)?",
                     rawTextEn: "When you have a problem, can you trust them?",
                     type: .singleChoice,
                     optionsEs: [Option(iconName: "circle", label: "Siempre", value: 3),
                                 Option(iconName: "circle", label: "Solo si no es nada importante", value: 2),
                                 Option(iconName: "circle", label: "No", value: 1)],
                     optionsEn: [Option(iconName: "circle", label: "Always", value: 3),
                                 Option(iconName: "circle", label: "Only if it's nothing important", value: 2),
                                 Option(iconName: "circle", label: "No", value: 1)],
                     category: .trust),

            Question(rawTextEs: "¿Crees que pueda confiar en ti?",
                     rawTextEn: "Do you think they can trust you?",
                     type: .singleChoice,
                     optionsEs: [Option(iconName: "circle", label: "Si", value: 3),
                                 Option(iconName: "circle", label: "No se", value: 2),
                                 Option(iconName: "circle", label: "No", value: 1)],
                     optionsEn: [Option(iconName: "circle", label: "Yes", value: 3),
                                 Option(iconName: "circle", label: "I'm not sure", value: 2),
                                 Option(iconName: "circle", label: "No", value: 1)],
                     category: .trust),

            Question(rawTextEs: "¿Disfrutas pasar tiempo con el(la)?",
                     rawTextEn: "Do you enjoy spending time with them?",
                     type: .singleChoice,
                     optionsEs: [Option(iconName: "circle", label: "Obvio", value: 3),
                                 Option(iconName: "circle", label: "No mucho", value: 2),
                                 Option(iconName: "circle", label: "No", value: 1)],
                     optionsEn: [Option(iconName: "circle", label: "Of course", value: 3),
                                 Option(iconName: "circle", label: "Not much", value: 2),
                                 Option(iconName: "circle", label: "No", value: 1)],
                     category: .support),

            Question(rawTextEs: "Cuando un(_) de ustedes se siente mal...",
                     rawTextEn: "When one of you feels bad...",
                     type: .singleChoice,
                     optionsEs: [Option(iconName: "circle", label: "Siempre se apoyan en lo que sea necesario", value: 3),
                                 Option(iconName: "circle", label: "Solo se preguntan \"¿estas bien?\"", value: 2),
                                 Option(iconName: "circle", label: "Fingen que no pasa nada", value: 1)],
                     optionsEn: [Option(iconName: "circle", label: "You always support each other", value: 3),
                                 Option(iconName: "circle", label: "You only ask \"Are you okay?\"", value: 2),
                                 Option(iconName: "circle", label: "You pretend nothing happened", value: 1)],
                     category: .support),

            Question(rawTextEs: "¿Celebran con entusiasmo los logros del_a otr(_)?",
                     rawTextEn: "Do you enthusiastically celebrate each other's achievements?",
                     type: .singleChoice,
                     optionsEs: [Option(iconName: "circle", label: "Siempre", value: 3),
                                 Option(iconName: "circle", label: "Solo lo importante", value: 2),
                                 Option(iconName: "circle", label: "No", value: 1)],
                     optionsEn: [Option(iconName: "circle", label: "Always", value: 3),
                                 Option(iconName: "circle", label: "Only the important ones", value: 2),
                                 Option(iconName: "circle", label: "No", value: 1)],
                     category: .support),

            Question(rawTextEs: "¿Sientes que esta amistad te ha ayudado en tu crecimiento emocional?",
                     rawTextEn: "Do you feel this friendship has helped you grow emotionally?",
                     type: .singleChoice,
                     optionsEs: [Option(iconName: "circle", label: "Si", value: 3),
                                 Option(iconName: "circle", label: "En algunas cosas", value: 2),
                                 Option(iconName: "circle", label: "No", value: 1)],
                     optionsEn: [Option(iconName: "circle", label: "Yes", value: 3),
                                 Option(iconName: "circle", label: "In some ways", value: 2),
                                 Option(iconName: "circle", label: "No", value: 1)],
                     category: .support),

            Question(rawTextEs: "¿Respetas los limites de tu amig(@)?",
                     rawTextEn: "Do you respect your friend's boundaries?",
                     type: .singleChoice,
                     optionsEs: [Option(iconName: "circle", label: "Si", value: 3),
                                 Option(iconName: "circle", label: "A veces", value: 2),
                                 Option(iconName: "circle", label: "No", value: 1)],
                     optionsEn: [Option(iconName: "circle", label: "Yes", value: 3),
                                 Option(iconName: "circle", label: "Sometimes", value: 2),
                                 Option(iconName: "circle", label: "No", value: 1)],
                     category: .limits),

            Question(rawTextEs: "¿Crees que el(la) respeta los tuyos?",
                     rawTextEn: "Do you think they respect yours?",
                     type: .singleChoice,
                     optionsEs: [Option(iconName: "circle", label: "Si", value: 3),
                                 Option(iconName: "circle", label: "A veces", value: 2),
                                 Option(iconName: "circle", label: "No", value: 1)],
                     optionsEn: [Option(iconName: "circle", label: "Yes", value: 3),
                                 Option(iconName: "circle", label: "Sometimes", value: 2),
                                 Option(iconName: "circle", label: "No", value: 1)],
                     category: .limits),

            Question(rawTextEs: "Cuando alguien habla mal de un(_) de ustedes...",
                     rawTextEn: "When someone speaks badly about one of you...",
                     type: .singleChoice,
                     optionsEs: [Option(iconName: "circle", label: "Se defienden", value: 3),
                                 Option(iconName: "circle", label: "Escuchan y no hacen nada", value: 2),
                                 Option(iconName: "circle", label: "Tambien hablan mal", value: 1)],
                     optionsEn: [Option(iconName: "circle", label: "You defend each other", value: 3),
                                 Option(iconName: "circle", label: "You listen and do nothing", value: 2),
                                 Option(iconName: "circle", label: "You also talk badly", value: 1)],
                     category: .limits),

            Question(rawTextEs: "Si alguien de tu grupo de amigos, excluye a un(_) de ustedes...",
                     rawTextEn: "If someone in your friend group excludes one of you...",
                     type: .singleChoice,
                     optionsEs: [Option(iconName: "circle", label: "Hacen todo lo posible para incluirse", value: 3),
                                 Option(iconName: "circle", label: "No hacen nada", value: 2),
                                 Option(iconName: "circle", label: "Tambien se excluyen", value: 1)],
                     optionsEn: [Option(iconName: "circle", label: "You do everything you can to include them", value: 3),
                                 Option(iconName: "circle", label: "You do nothing", value: 2),
                                 Option(iconName: "circle", label: "You also exclude them", value: 1)],
                     category: .support),

            Question(rawTextEs: "¿Eres honest(#) con el(la)?",
                     rawTextEn: "Are you honest with them?",
                     type: .singleChoice,
                     optionsEs: [Option(iconName: "circle", label: "Siempre", value: 3),
                                 Option(iconName: "circle", label: "A veces", value: 2),
                                 Option(iconName: "circle", label: "Nunca", value: 1)],
                     optionsEn: [Option(iconName: "circle", label: "Always", value: 3),
                                 Option(iconName: "circle", label: "Sometimes", value: 2),
                                 Option(iconName: "circle", label: "Never", value: 1)],
                     category: .assertiveness),

            Question(rawTextEs: "¿Le dices lo que sientes y lo que quieres con respeto, sin importar que sea?",
                     rawTextEn: "Do you tell them what you feel and what you want respectfully, no matter what it is?",
                     type: .singleChoice,
                     optionsEs: [Option(iconName: "circle", label: "Siempre", value: 3),
                                 Option(iconName: "circle", label: "A veces", value: 2),
                                 Option(iconName: "circle", label: "Nunca", value: 1)],
                     optionsEn: [Option(iconName: "circle", label: "Always", value: 3),
                                 Option(iconName: "circle", label: "Sometimes", value: 2),
                                 Option(iconName: "circle", label: "Never", value: 1)],
                     category: .assertiveness),

            Question(rawTextEs: "¿Cual es el nombre de tu amig(@)?",
                     rawTextEn: "What's your friend's name?",
                     type: .textInput, optionsEs: nil, optionsEn: nil, category: .name)
        ]
    }

    // MARK: - Computed Properties
    var currentQuestion: Question {
        guard currentQuestionIndex >= 0 && currentQuestionIndex < questions.count else {
            return Question(rawTextEs: "Error", rawTextEn: "Error", type: .singleChoice, optionsEs: [], optionsEn: [], category: .support)
        }
        return questions[currentQuestionIndex]
    }

    var isLastQuestion: Bool {
        // In re-evaluation, skip the last question (name) since we already know it
        if isReEvaluation {
            return currentQuestionIndex == questions.count - 2 // Skip name question
        }
        return currentQuestionIndex == questions.count - 1
    }

    var isAnswerSelected: Bool {
        switch currentQuestion.type {
        case .genderSelection: return friendGenderSelection != nil
        case .textInput: return shouldSkipName || isValidName(friendNameInput)
        case .singleChoice: return selectedAnswers[currentQuestion.id] != nil
        }
    }

    // MARK: - Validation
    func isValidName(_ name: String) -> Bool {
        guard name.count >= 3 else { return false }
        guard name.prefix(1).uppercased() == name.prefix(1) else { return false }
        let regexLetters = try! NSRegularExpression(pattern: "^[a-zA-ZáéíóúÁÉÍÓÚñÑ\\s]+$")
        let range = NSRange(location: 0, length: name.utf16.count)
        guard regexLetters.firstMatch(in: name, options: [], range: range) != nil else { return false }
        let forbiddenSymbols = CharacterSet(charactersIn: "@#$&*()'\"%\\-+=/;:,.!?¿¡€£¥_^[]{}><\\…~|§").union(.decimalDigits)
        return name.rangeOfCharacter(from: forbiddenSymbols) == nil
    }

    func cleanName(_ name: String) -> String {
        let forbidden = "@#$&*()'\"%\\-+=/;:,.!?¿¡€£¥_^[]{}><\\…~|§"
        let set = CharacterSet(charactersIn: forbidden).union(.decimalDigits)
        return name.components(separatedBy: set).joined()
    }

    // MARK: - Actions
    func selectOption(option: Option) {
        selectedAnswers[currentQuestion.id] = option
        HapticManager.shared.selection()
    }

    func nextQuestion() {
        if !isLastQuestion {
            currentQuestionIndex += 1
            HapticManager.shared.lightImpact()
        }
    }

    // MARK: - Text Processing (Gender Pronouns)
    func getProcessedQuestionText() -> String {
        guard currentQuestion.type == .singleChoice || currentQuestion.type == .textInput else {
            return currentQuestion.rawText(for: language)
        }
        let rawText = currentQuestion.rawText(for: language)

        if language == .en {
            guard let friendGender = friendGenderSelection else { return rawText }
            let subject = (friendGender == .chica) ? "she" : "he"
            let object = (friendGender == .chica) ? "her" : "him"
            return rawText.replacingPronounWord("them", with: object)
                          .replacingPronounWord("they", with: subject)
        }

        let base: (at: String, ell: String, ala: String, uno: String, otro: String, lo: String)
        switch friendGenderSelection {
        case .chico: base = ("o", "el", "al", "uno", "otro", "Lo")
        case .chica: base = ("a", "ella", "a la", "una", "otra", "La")
        case .none: return rawText
        }

        let isAllFemale = userViewModel.selectedGender == .chica && friendGenderSelection == .chica
        let underscore = isAllFemale ? "a" : "o"
        let dela = isAllFemale ? "de la" : "del"
        let hash: String = (userViewModel.selectedGender == .chica) ? "a" : "o"

        var text = rawText
        text = text.replacingOccurrences(of: "(@)", with: base.at)
        text = text.replacingOccurrences(of: "el(la)", with: base.ell)
        text = text.replacingOccurrences(of: "a(la)", with: base.ala)
        text = text.replacingOccurrences(of: "un(@)", with: base.uno)
        text = text.replacingOccurrences(of: "otr(@)", with: base.otro)
        text = text.replacingOccurrences(of: "L(@)", with: base.lo)
        text = text.replacingOccurrences(of: "(_)", with: underscore)
        text = text.replacingOccurrences(of: "del_a", with: dela)
        text = text.replacingOccurrences(of: "(#)", with: hash)
        return text
    }

    // MARK: - Results
    func analyzeCategories() -> (category: CategoryKey, averageScore: Double) {
        var categoryScores: [CategoryKey: [Int]] = [:]
        for (questionId, option) in selectedAnswers {
            guard let question = questions.first(where: { $0.id == questionId }) else { continue }
            if question.type == .singleChoice {
                categoryScores[question.category, default: []].append(option.value)
            }
        }

        var categoryAverages: [CategoryKey: Double] = [:]
        for (category, scores) in categoryScores {
            categoryAverages[category] = Double(scores.reduce(0, +)) / Double(scores.count)
        }

        let sorted = categoryAverages.sorted { $0.value < $1.value }
        if let lowest = sorted.first, lowest.value < 3.0 {
            return (lowest.key, lowest.value)
        }

        let totalScore = selectedAnswers.values.reduce(0) { $0 + $1.value }
        let totalQ = questions.filter { $0.type == .singleChoice }.count
        let overall = Double(totalScore) / Double(max(totalQ, 1))
        return (.support, overall)
    }

    func displayCategory(_ key: CategoryKey) -> String {
        switch language {
        case .es:
            switch key {
            case .support: return "Apoyo"
            case .trust: return "Confianza"
            case .limits: return "Limites"
            case .assertiveness: return "Asertividad"
            case .friendGender: return "Genero"
            case .name: return "Nombre"
            }
        case .en:
            switch key {
            case .support: return "Support"
            case .trust: return "Trust"
            case .limits: return "Boundaries"
            case .assertiveness: return "Assertiveness"
            case .friendGender: return "Gender"
            case .name: return "Name"
            }
        }
    }

    func generateDynamicSummary() -> TestResult {
        let (focusAreaKey, averageScore) = analyzeCategories()
        let friendName = friendNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (language == .es ? "Esta persona" : "This person")
            : friendNameInput.trimmingCharacters(in: .whitespacesAndNewlines)

        var analysis = ""
        var recommendation = ""
        var rating = ""
        var color = Color.resultNeutral

        if averageScore >= 2.8 {
            rating = language == .es ? "Amistad Muy Solida" : "Very Strong Friendship"
            color = .resultHigh
            analysis = language == .es
                ? "Siento que tu amistad con \(friendName) es muy solida y estable. Las respuestas muestran que se tienen muchisima confianza, se apoyan en todo y hay mucho respeto."
                : "It feels like your friendship with \(friendName) is very strong and stable. Your answers suggest there's a lot of trust, mutual support, and respect."
            recommendation = language == .es
                ? "Sigue invirtiendo en esta amistad tan valiosa. Es clave que mantengan sus momentos especiales, celebren sus exitos de corazon y sigan comunicandose con mucha honestidad."
                : "Keep investing in this valuable friendship. Protect your special moments, celebrate each other sincerely, and keep communicating with honesty."
        } else if averageScore <= 1.8 {
            rating = language == .es ? "Amistad Inestable" : "Unstable Friendship"
            color = .resultLow
            analysis = language == .es
                ? "Tu amistad con \(friendName) parece ser agotadora para ambas partes, lo mejor es ver en que cosas no estan bien y mejorarlas o cortar la amistad."
                : "Your friendship with \(friendName) seems exhausting for both of you. It may help to identify what isn't working and either improve it or consider stepping away."
            recommendation = language == .es
                ? "Una amistad inestable es mala para ambas partes de la relacion, puede causar inseguridad e incluso, efectos negativos en la salud."
                : "An unstable friendship can hurt both people. It can create insecurity and even negative effects on your well-being."
        } else if focusAreaKey == .trust {
            rating = language == .es ? "Amistad en Progreso" : "Friendship in Progress"
            analysis = language == .es
                ? "La relacion con \(friendName) va muy bien en muchas areas, pero podrian mejorar la confianza. Tus respuestas indican que todavia no se sienten libres de abrirse por completo."
                : "Your relationship with \(friendName) is doing well in many areas, but trust could improve. Your answers suggest you may not feel fully free to open up."
            recommendation = language == .es
                ? "Si quieres que esta amistad tenga mas Confianza, debe de haber compromiso en ambas partes y una buena comunicacion."
                : "If you want more trust in this friendship, both of you need commitment and good communication."
        } else if focusAreaKey == .limits {
            rating = language == .es ? "Amistad en Progreso" : "Friendship in Progress"
            analysis = language == .es
                ? "Tu amistad con \(friendName) es valiosa, pero deberian de mejorar en definir y respetar los Limites personales."
                : "Your friendship with \(friendName) is valuable, but defining and respecting personal boundaries could improve."
            recommendation = language == .es
                ? "Si quieres que esta amistad tenga mejores Limites, debe de haber compromiso en ambas partes y una buena comunicacion."
                : "If you want healthier boundaries, both of you need commitment and good communication."
        } else if focusAreaKey == .assertiveness {
            rating = language == .es ? "Amistad en Progreso" : "Friendship in Progress"
            analysis = language == .es
                ? "Tienes un gran cariño por \(friendName), pero tu punto de crecimiento es la Asertividad. Podrias estar guardandote lo que sientes por miedo al conflicto."
                : "You care a lot about \(friendName), but your growth area is assertiveness. You might be holding back what you feel out of fear of conflict."
            recommendation = language == .es
                ? "Si quieres que esta amistad tenga mas Asertividad, debe de haber compromiso en ambas partes y una buena comunicacion."
                : "If you want more assertiveness, both of you need commitment and good communication."
        } else {
            rating = language == .es ? "Amistad en Progreso" : "Friendship in Progress"
            analysis = language == .es
                ? "Te la pasas bien con \(friendName), pero los resultados indican que podrian mejorar en el Apoyo Mutuo y en invertir mas energia de calidad."
                : "You have a good time with \(friendName), but the results suggest you could improve mutual support and invest more quality energy."
            recommendation = language == .es
                ? "Si quieres que esta amistad tenga mas Apoyo Mutuo, debe de haber compromiso en ambas partes y una buena comunicacion."
                : "If you want more mutual support, both of you need commitment and good communication."
        }

        return TestResult(
            summaryAnalysis: analysis,
            summaryRecommendation: recommendation,
            finalRating: rating,
            color: color,
            focusAreaKey: focusAreaKey,
            focusAreaDisplay: displayCategory(focusAreaKey),
            friendName: friendName
        )
    }

    func calculateResult() -> TestResult {
        let result = generateDynamicSummary()

        // Save to Friendship Journal
        let (_, avgScore) = analyzeCategories()
        var catScores: [String: Double] = [:]
        var categoryScoreLists: [CategoryKey: [Int]] = [:]
        for (qId, option) in selectedAnswers {
            guard let q = questions.first(where: { $0.id == qId }), q.type == .singleChoice else { continue }
            categoryScoreLists[q.category, default: []].append(option.value)
        }
        for (cat, scores) in categoryScoreLists {
            catScores[cat.rawValue] = Double(scores.reduce(0, +)) / Double(scores.count)
        }

        // Build answers by question index for future re-evaluation comparison
        var answersByIdx: [Int: Int] = [:]
        for (qId, option) in selectedAnswers {
            if let idx = questions.firstIndex(where: { $0.id == qId }) {
                answersByIdx[idx] = option.value
            }
        }

        let record = FriendshipRecord(
            id: UUID(),
            date: Date(),
            friendName: result.friendName,
            friendGender: friendGenderSelection?.rawValue ?? "chico",
            overallScore: avgScore,
            categoryScores: catScores,
            rating: result.finalRating,
            focusArea: result.focusAreaDisplay,
            language: language.rawValue,
            answersByIndex: answersByIdx
        )
        FriendshipStore.shared.save(record: record)

        // Schedule re-evaluation notification in 30 days
        NotificationManager.shared.scheduleReEvaluationReminder(friendName: result.friendName)

        return result
    }

    func resetTest() {
        currentQuestionIndex = 0
        selectedAnswers = [:]
        friendNameInput = ""
        shouldSkipName = false
        friendGenderSelection = nil
    }
}
