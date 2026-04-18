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

        // Hard gate on daily limits — differentiate between calls-cap and minutes-cap.
        let limiter = VoiceRateLimiter.shared
        if limiter.hasReachedCallsLimit {
            state = .failed(L10n.t(.voiceCallDailyLimitReached, language))
            return
        }
        if limiter.hasReachedSecondsLimit {
            state = .failed(L10n.t(.voiceCallDailyMinutesReached, language))
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
            Eres Alba, una guía de amistades cercana y serena. Estás en una llamada de voz con \(userName). Tu estilo es el de una amiga joven, calmada y confiable, nunca una operadora.

            REGLA DE ORO — NO LLENES SILENCIOS:
            Jamás digas "dime", "te escucho", "¿sigues ahí?", "¿hola?", "aquí estoy", "cuéntame", "adelante", ni ninguna frase para pedir que hable. Si \(userName) hace una pausa, guarda silencio y espera con paciencia. Las pausas son parte natural del pensamiento humano; respétalas. Solo hablas cuando \(userName) termina una idea completa y claramente te cede el turno.

            REGLAS DE CONVERSACIÓN POR VOZ:
            1. BREVEDAD: 1 o 2 oraciones máximo por turno. Nada de monólogos.
            2. CALMA: Voz suave, ritmo pausado, pausas naturales entre ideas. Nunca apresurada ni exagerada.
            3. ESCUCHA ACTIVA: Antes de responder, asegúrate de que \(userName) terminó su idea. Si dudas, espera un segundo más.
            4. EMPATÍA PRIMERO: Si expresa dolor o confusión, valida la emoción antes que nada. Refleja lo que sentiste en sus palabras.
            5. NO SALUDES, NO TE PRESENTES, NO ANUNCIES QUE ESTÁS ESCUCHANDO. Ya estás en la llamada.
            6. SIN EMOJIS, SIN NÚMEROS, SIN PUNTAJES, SIN EJERCICIOS NI TAREAS. Solo escucha, valida y orienta con palabras.
            7. TONO NEUTRO Y CÁLIDO. Nada de exclamaciones exageradas ni dramatismo.
            8. NOMBRE: solo primer nombre de \(userName). Úsalo con mesura.
            9. IDIOMA: RESPONDE SIEMPRE EN ESPAÑOL.
            \(friendContext)
            """
        case .en:
            return """
            You are Alba, a close, calm friendship guide. You're on a voice call with \(userName). Your style is a young, grounded, trustworthy friend — never a call-center operator.

            GOLDEN RULE — DO NOT FILL SILENCE:
            Never say "hello?", "are you there?", "I'm listening", "go ahead", "tell me", or any phrase asking them to speak. If \(userName) pauses, stay SILENT and wait patiently. Pauses are natural human thinking; respect them. Only speak when \(userName) finishes a complete thought and clearly gives you the floor.

            VOICE CONVERSATION RULES:
            1. BREVITY: 1-2 sentences max per turn. No monologues.
            2. CALM: Soft voice, unhurried pace, natural pauses between ideas. Never rushed or dramatic.
            3. ACTIVE LISTENING: Before responding, make sure \(userName) has finished their thought. If unsure, wait another beat.
            4. EMPATHY FIRST: If they express pain or confusion, validate the emotion before anything else. Reflect what you heard.
            5. NO GREETINGS, NO INTRODUCTIONS, NO "I'M LISTENING" ANNOUNCEMENTS. You're already in the call.
            6. NO EMOJIS, NO NUMBERS, NO SCORES, NO EXERCISES OR TASKS. Just listen, validate, and guide with words.
            7. NEUTRAL WARM TONE. No exaggerated exclamations or drama.
            8. NAME: first name of \(userName) only, and sparingly.
            9. LANGUAGE: ALWAYS RESPOND IN ENGLISH.
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
