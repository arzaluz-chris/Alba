import Combine
import SwiftUI
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Alba", category: "ChatViewModel")

final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var currentInput: String = ""
    @Published var isTyping: Bool = false
    @Published var limitReached: Bool = false
    @Published var smartSuggestions: [String] = []

    private let geminiService = GeminiService()
    private let userViewModel: UserViewModel
    private let rateLimiter = RateLimiter.shared
    private var hiddenContext: String?
    private(set) var conversationId: UUID
    private var hasGeneratedTitle: Bool = false
    var language: AppLanguage = .es

    private static let conversationIdKey = "alba_current_conversation_id"
    private static let conversationTimestampKey = "alba_current_conversation_timestamp"
    /// Minutes of inactivity before starting a new conversation
    private static let sessionTimeoutMinutes: Double = 30

    var messagesRemaining: Int { rateLimiter.messagesRemaining }
    var dailyLimit: Int { rateLimiter.dailyLimit }

    init(userViewModel: UserViewModel) {
        self.userViewModel = userViewModel
        self.conversationId = Self.resolveConversationId()
        self.limitReached = rateLimiter.isLimitReached
        logger.info("🟢 ChatViewModel init. ConversationId: \(self.conversationId). Remaining: \(self.rateLimiter.messagesRemaining)/\(self.rateLimiter.dailyLimit)")
    }

    /// Reuses the current conversation ID if the last activity was recent, otherwise creates a new one.
    private static func resolveConversationId() -> UUID {
        let defaults = UserDefaults.standard
        if let idString = defaults.string(forKey: conversationIdKey),
           let existingId = UUID(uuidString: idString),
           let lastTimestamp = defaults.object(forKey: conversationTimestampKey) as? Date,
           Date().timeIntervalSince(lastTimestamp) < sessionTimeoutMinutes * 60 {
            logger.info("♻️ Resuming conversation \(existingId)")
            return existingId
        }
        let newId = UUID()
        defaults.set(newId.uuidString, forKey: conversationIdKey)
        defaults.set(Date(), forKey: conversationTimestampKey)
        logger.info("🆕 New conversation \(newId)")
        return newId
    }

    /// Call when the user explicitly starts a fresh conversation
    func startNewConversation() {
        conversationId = UUID()
        UserDefaults.standard.set(conversationId.uuidString, forKey: Self.conversationIdKey)
        UserDefaults.standard.set(Date(), forKey: Self.conversationTimestampKey)
        messages = []
        smartSuggestions = []
    }

    func setInitialMessage(userName: String, context: String? = nil) {
        if let context = context {
            let msg = language == .es
                ? "Estoy analizando los resultados de tu Alba Test..."
                : "I'm analyzing your Alba Test results..."
            messages.append(Message(text: msg, isUser: false))

            callGemini(
                prompt: language == .es
                    ? "Analiza estos resultados. Dame un análisis breve y un ejercicio concreto."
                    : "Analyze these results. Give a brief analysis and a concrete exercise.",
                history: [],
                hiddenContext: context
            )
        } else {
            let greeting = language == .es
                ? "Hola \(userName), soy Alba. Estoy aquí para ayudarte a mejorar tus amistades. Cuéntame, ¿cómo están tus relaciones hoy?"
                : "Hi \(userName), I'm Alba. I'm here to help you improve your friendships. Tell me—how are your relationships today?"
            messages.append(Message(text: greeting, isUser: false))
            smartSuggestions = language == .es
                ? ["Tuve un problema con un amigo", "¿Cómo poner límites?", "Necesito hablar"]
                : ["I had a problem with a friend", "How to set boundaries?", "I need to talk"]
        }
    }

    func loadConversation(_ saved: SavedConversation) {
        messages = saved.messages.map { Message(text: $0.text, isUser: $0.isUser) }
        conversationId = saved.id
        UserDefaults.standard.set(conversationId.uuidString, forKey: Self.conversationIdKey)
        UserDefaults.standard.set(Date(), forKey: Self.conversationTimestampKey)
        smartSuggestions = []
    }

    func saveCurrentConversation() {
        ConversationStore.shared.saveConversation(id: conversationId, messages: messages, language: language)
        UserDefaults.standard.set(Date(), forKey: Self.conversationTimestampKey)
    }

    func sendMessage() {
        let text = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if rateLimiter.isLimitReached {
            limitReached = true
            withAnimation {
                messages.append(Message(text: language == .es
                    ? "Has alcanzado el limite de \(dailyLimit) mensajes por hoy."
                    : "Daily limit of \(dailyLimit) messages reached.", isUser: false))
            }
            HapticManager.shared.notification(.warning)
            return
        }

        withAnimation(.spring(response: 0.3)) {
            messages.append(Message(text: text, isUser: true))
        }
        currentInput = ""
        smartSuggestions = []
        HapticManager.shared.lightImpact()

        callGemini(prompt: text, history: messages, hiddenContext: hiddenContext)
        hiddenContext = nil
    }

    // MARK: - Core Gemini Call

    private func callGemini(prompt: String, history: [Message], hiddenContext: String?) {
        isTyping = true
        logger.info("🔄 Calling Gemini...")

        Task { @MainActor in
            defer {
                isTyping = false
                logger.info("⌨️ isTyping → false")
            }

            do {
                let rawResponse = try await geminiService.sendMessage(
                    prompt, history: history, language: language,
                    personalization: userViewModel.aiPersonalization,
                    hiddenContext: hiddenContext,
                    userName: userViewModel.userName
                )
                rateLimiter.recordMessage()
                limitReached = rateLimiter.isLimitReached

                // Parse suggestions and evaluate tags from response
                let (displayText, suggestions) = parseSuggestions(from: rawResponse)
                let (cleanText, evaluateFriend) = parseEvaluateTag(from: displayText)

                withAnimation(.spring(response: 0.4)) {
                    if let friendName = evaluateFriend {
                        // Only show test card if friend is NOT already evaluated
                        let alreadyEvaluated = FriendshipStore.shared.uniqueFriends().contains(where: {
                            $0.lowercased() == friendName.lowercased()
                        })

                        messages.append(Message(text: cleanText, isUser: false))

                        if !alreadyEvaluated {
                            var testMsg = Message(
                                text: language == .es
                                    ? "¿Quieres evaluar tu amistad con \(friendName)? Haz el Alba Test para obtener un análisis completo."
                                    : "Want to evaluate your friendship with \(friendName)? Take the Alba Test for a full analysis.",
                                isUser: false
                            )
                            testMsg.action = .takeTest(friendName: friendName)
                            messages.append(testMsg)
                        }
                    } else {
                        messages.append(Message(text: cleanText, isUser: false))
                    }
                }

                // Haptic: text arrived (strong → light, based on length)
                let pulses = min(max(displayText.count / 80, 2), 6)
                HapticManager.shared.textArrivedPattern(pulses: pulses)

                saveCurrentConversation()
                smartSuggestions = suggestions

                // Auto-generate title after first meaningful exchange (at least 2 messages total)
                if !hasGeneratedTitle && messages.count >= 2 {
                    hasGeneratedTitle = true
                    Task {
                        if let title = await geminiService.generateTitle(from: messages, language: language) {
                            ConversationStore.shared.updateTitle(id: conversationId, title: title)
                        }
                    }
                }

            } catch GeminiError.rateLimited {
                logger.error("⚠️ Gemini rate limited")
                withAnimation {
                    messages.append(Message(text: L10n.t(.chatRateLimited, language), isUser: false))
                }
                HapticManager.shared.notification(.warning)
            } catch {
                logger.error("❌ Gemini error: \(error.localizedDescription)")
                withAnimation {
                    messages.append(Message(text: L10n.t(.chatConnectionError, language), isUser: false))
                }
                HapticManager.shared.notification(.error)
            }
        }
    }

    // MARK: - Parse [EVALUAR: name] / [EVALUATE: name] tag

    private func parseEvaluateTag(from text: String) -> (String, String?) {
        let patterns = ["[EVALUAR:", "[EVALUATE:", "[evaluar:", "[evaluate:"]
        for pattern in patterns {
            if let range = text.range(of: pattern) {
                let beforeTag = String(text[text.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let afterPattern = String(text[range.upperBound...])
                // Extract name before the closing ]
                if let closeBracket = afterPattern.firstIndex(of: "]") {
                    let name = String(afterPattern[afterPattern.startIndex..<closeBracket]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty {
                        logger.info("🔍 Detected unevaluated friend: \(name)")
                        return (beforeTag, name)
                    }
                }
            }
        }
        return (text, nil)
    }

    // MARK: - Parse AI-generated suggestions from response

    /// Gemini is instructed to end responses with [SUGERENCIAS: "a", "b", "c"]
    /// This parses them out and returns clean display text + suggestions array
    private func parseSuggestions(from response: String) -> (String, [String]) {
        // Look for the suggestions tag
        let patterns = ["[SUGERENCIAS:", "[SUGGESTIONS:", "[sugerencias:", "[suggestions:"]
        for pattern in patterns {
            if let range = response.range(of: pattern) {
                let beforeTag = String(response[response.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let tagContent = String(response[range.lowerBound...])

                // Extract quoted strings
                var suggestions: [String] = []
                let regex = try? NSRegularExpression(pattern: "\"([^\"]+)\"")
                let nsRange = NSRange(tagContent.startIndex..<tagContent.endIndex, in: tagContent)
                if let matches = regex?.matches(in: tagContent, range: nsRange) {
                    for match in matches {
                        if let r = Range(match.range(at: 1), in: tagContent) {
                            suggestions.append(String(tagContent[r]))
                        }
                    }
                }

                if !suggestions.isEmpty {
                    logger.info("💡 Parsed \(suggestions.count) AI suggestions")
                    return (beforeTag, Array(suggestions.prefix(4)))
                }
            }
        }

        // No suggestions tag found - return as-is with empty suggestions
        // Fall back to basic context suggestions
        let fallback = language == .es
            ? ["Cuéntame más", "Dame un ejercicio", "¿Qué más puedo hacer?"]
            : ["Tell me more", "Give me an exercise", "What else can I do?"]
        return (response, fallback)
    }

}
