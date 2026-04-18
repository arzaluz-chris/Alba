import Foundation
import SwiftUI
import Combine
import AVFoundation
import os.log

private let vcLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Alba", category: "VoiceCallViewModel")

// MARK: - Voice Call State
enum VoiceCallState: Equatable {
    case idle
    case requestingPermission
    case permissionDenied
    case connecting
    case active
    case paused
    case ending
    case ended
    case failed(String)
}

// MARK: - Voice Call ViewModel
@MainActor
final class VoiceCallViewModel: ObservableObject {
    // MARK: - Dependencies
    @Published private(set) var liveService: GeminiLiveService
    private weak var chatViewModel: ChatViewModel?
    private let language: AppLanguage
    private let userName: String

    // MARK: - Published UI state
    @Published var state: VoiceCallState = .idle
    @Published var elapsedSeconds: Int = 0

    // MARK: - Private
    private var timerTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    var maxSessionSeconds: Int { VoiceRateLimiter.shared.maxSessionSeconds }

    // MARK: - Derived
    var orbState: VoiceOrbState {
        switch state {
        case .idle, .ended: return .idle
        case .requestingPermission, .permissionDenied, .failed: return .idle
        case .connecting: return .connecting
        case .paused: return .paused
        case .active, .ending:
            if liveService.isModelSpeaking { return .speaking }
            if liveService.isUserSpeaking { return .listening }
            return .idle
        }
    }

    var formattedElapsed: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// Level (0-1) used to drive the orb — uses the model's output while Alba
    /// speaks, the user's mic input while the user speaks, or a gentle baseline.
    var orbAudioLevel: Float {
        if liveService.isModelSpeaking { return liveService.outputAudioLevel }
        if liveService.isUserSpeaking { return liveService.inputAudioLevel * 0.6 }
        return 0
    }

    // MARK: - Init
    init(chatViewModel: ChatViewModel, language: AppLanguage, userName: String) {
        self.chatViewModel = chatViewModel
        self.language = language
        self.userName = userName
        self.liveService = GeminiLiveService()

        // Re-emit whenever the nested live service publishes — keeps SwiftUI views
        // observing this VM in sync with audio-thread state changes.
        liveService.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.objectWillChange.send() }
            }
            .store(in: &cancellables)
    }

    // MARK: - Lifecycle

    func startCall() async {
        guard state == .idle else { return }

        // Hard gate on daily limit
        if VoiceRateLimiter.shared.hasReachedLimit {
            state = .failed(L10n.t(.voiceCallDailyLimitReached, language))
            return
        }

        // 1. Permission
        state = .requestingPermission
        let granted = await requestMicPermission()
        guard granted else {
            state = .permissionDenied
            HapticManager.shared.notification(.warning)
            return
        }

        // 2. Connect
        state = .connecting
        HapticManager.shared.heavyImpact()

        do {
            let systemInstruction = buildSystemInstruction()
            let voice = RemoteConfigService.shared.geminiLiveVoiceName
            try await liveService.connect(systemInstruction: systemInstruction, voiceName: voice)
            state = .active
            HapticManager.shared.notification(.success)
            startTimer()
        } catch {
            vcLogger.error("❌ Failed to start voice call: \(error.localizedDescription)")
            state = .failed(L10n.t(.voiceCallErrorGeneric, language))
            HapticManager.shared.notification(.error)
            await liveService.disconnect()
        }
    }

    func pause() {
        guard state == .active else { return }
        liveService.pause()
        state = .paused
        HapticManager.shared.mediumImpact()
    }

    func resume() {
        guard state == .paused else { return }
        liveService.resume()
        state = .active
        HapticManager.shared.mediumImpact()
    }

    /// User tapped the red end button, or session timed out.
    func endCall(reason: EndReason = .user) async {
        guard state != .ended, state != .ending else { return }
        state = .ending
        timerTask?.cancel()
        timerTask = nil

        await liveService.disconnect()

        // Persist usage + summary (only if we actually had a real session)
        let duration = elapsedSeconds
        if duration > 0 {
            VoiceRateLimiter.shared.recordCall(durationSeconds: duration)
            appendSummaryToChat(durationSeconds: duration, reason: reason)
        }

        HapticManager.shared.notification(.success)
        state = .ended
    }

    enum EndReason {
        case user
        case maxDuration
        case error
    }

    // MARK: - Timer

    private func startTimer() {
        timerTask?.cancel()
        elapsedSeconds = 0
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self, !Task.isCancelled else { break }
                // Pause stops the counter
                if self.state == .active {
                    self.elapsedSeconds += 1
                    if self.elapsedSeconds >= self.maxSessionSeconds {
                        vcLogger.info("⏱️ Max session duration reached, auto-ending")
                        await self.endCall(reason: .maxDuration)
                        break
                    }
                }
            }
        }
    }

    // MARK: - Permission

    private func requestMicPermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return true
        case .denied: return false
        case .undetermined:
            return await AVAudioApplication.requestRecordPermission()
        @unknown default:
            return false
        }
    }

    // MARK: - Summary message

    private func appendSummaryToChat(durationSeconds: Int, reason: EndReason) {
        guard let chat = chatViewModel else { return }

        // Embed the duration into the text itself so it still renders correctly
        // after a conversation is re-loaded from history (SavedMessage only
        // persists text + isUser, not the .voiceCallSummary action).
        let durationString = Self.formatDuration(seconds: durationSeconds)
        let label = L10n.t(.voiceCallDurationLabel, language)
        let summaryText: String
        switch reason {
        case .user:
            summaryText = "\(label) · \(durationString)"
        case .maxDuration:
            summaryText = "\(label) · \(durationString) — " + L10n.t(.voiceCallMaxDurationReached, language)
        case .error:
            summaryText = "\(label) · \(durationString) — " + L10n.t(.voiceCallErrorGeneric, language)
        }

        var msg = Message(text: summaryText, isUser: false)
        msg.action = .voiceCallSummary(durationSeconds: durationSeconds)
        withAnimation(.spring(response: 0.4)) {
            chat.messages.append(msg)
        }
        chat.saveCurrentConversation()
    }

    private static func formatDuration(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m > 0 {
            return "\(m)m \(s)s"
        }
        return "\(s)s"
    }

    // MARK: - System instruction

    /// Builds the system prompt for voice. Mirrors the text chat personality
    /// but enforces maximum brevity (1–2 sentences) because everything is spoken.
    private func buildSystemInstruction() -> String {
        let friendContext = buildFriendContext()

        switch language {
        case .es:
            return """
            Eres Alba, una guía experta en amistades basada en psicología positiva. Estás en una llamada de voz con \(userName).

            REGLAS DE CONVERSACIÓN POR VOZ:
            1. BREVEDAD ABSOLUTA: Responde en 1 o 2 oraciones como máximo. Esto es una llamada, no un ensayo.
            2. CALIDEZ: Habla con ternura y calma, como una amiga cercana. Ritmo pausado.
            3. EMPATÍA PRIMERO: Si expresa dolor o confusión, valida la emoción antes de cualquier otra cosa.
            4. NO SALUDES: Ya estás en la llamada. Respondes directo a lo que \(userName) dice.
            5. SIN EMOJIS: Nunca menciones emojis ni símbolos.
            6. SIN EJERCICIOS: No sugieras retos, tareas ni acciones concretas. Solo escucha, valida y orienta con palabras.
            7. SIN PUNTAJES: Nunca menciones números, escalas ni calificaciones. Habla en términos cualitativos.
            8. TONO NEUTRAL: Amigable pero sin dramatismo. Sin exclamaciones exageradas.
            9. NOMBRE: Refiérete a \(userName) solo por su primer nombre, nunca apellidos.
            10. IDIOMA: RESPONDE SIEMPRE EN ESPAÑOL.
            \(friendContext)
            """
        case .en:
            return """
            You are Alba, an expert friendship guide based on positive psychology. You're in a voice call with \(userName).

            VOICE CONVERSATION RULES:
            1. ABSOLUTE BREVITY: Respond in 1 or 2 sentences maximum. This is a call, not an essay.
            2. WARMTH: Speak gently and calmly, like a close friend. Unhurried pace.
            3. EMPATHY FIRST: If they express pain or confusion, validate the emotion before anything else.
            4. DON'T GREET: You're already in the call. Respond directly to what \(userName) says.
            5. NO EMOJIS: Never mention emojis or symbols.
            6. NO EXERCISES: Don't suggest challenges, tasks, or concrete actions. Just listen, validate, and guide with words.
            7. NO SCORES: Never mention numbers, scales, or ratings. Speak qualitatively.
            8. NEUTRAL TONE: Friendly but not dramatic. No exaggerated exclamations.
            9. NAME: Refer to \(userName) only by their first name, never last names.
            10. LANGUAGE: ALWAYS RESPOND IN ENGLISH.
            \(friendContext)
            """
        }
    }

    private func buildFriendContext() -> String {
        let friends = FriendshipStore.shared.uniqueFriends()
        guard !friends.isEmpty else { return "" }

        let header = language == .es
            ? "\nAMIGOS YA EVALUADOS DEL USUARIO (contexto): "
            : "\nUSER'S ALREADY-EVALUATED FRIENDS (context): "
        return header + friends.joined(separator: ", ")
    }
}
