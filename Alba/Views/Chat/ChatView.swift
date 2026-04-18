import SwiftUI

struct ChatView: View {
    @Binding var currentView: AppState
    @StateObject private var viewModel: ChatViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var userViewModel: UserViewModel

    let initialContext: String?

    @State private var showHistory = false
    @State private var showAIOnboarding = false
    @State private var showVoiceCall = false
    @State private var showVoiceLimitAlert = false
    @State private var hasInitializedSession = false
    @ObservedObject private var voiceLimiter = VoiceRateLimiter.shared

    init(currentView: Binding<AppState>, userViewModel: UserViewModel, initialContext: String?) {
        self._currentView = currentView
        self._viewModel = StateObject(wrappedValue: ChatViewModel(userViewModel: userViewModel))
        self.initialContext = initialContext
    }

    private var lang: AppLanguage { languageManager.language }

    var body: some View {
        ZStack {
            AnimatedMeshBackground()
                .opacity(0.4)

            Color.albaBackground
                .ignoresSafeArea()
                .opacity(0.6)

            VStack(spacing: 0) {
                // MARK: - Top Bar
                HStack {
                    Button {
                        HapticManager.shared.lightImpact()
                        viewModel.saveCurrentConversation()
                        currentView = .welcome
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.albaText)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text(L10n.t(.chatTitle, lang))
                            .font(AlbaFont.serif(20, weight: .bold))
                            .foregroundColor(.albaText)

                        Text(lang == .es
                             ? "\(viewModel.messagesRemaining) mensajes restantes hoy"
                             : "\(viewModel.messagesRemaining) messages left today")
                            .font(AlbaFont.rounded(11, weight: .medium))
                            .foregroundColor(viewModel.messagesRemaining <= 5 ? .red.opacity(0.8) : .gray.opacity(0.6))
                    }

                    Spacer()

                    Button {
                        HapticManager.shared.lightImpact()
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.albaAccent)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)

                // MARK: - Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if viewModel.messages.isEmpty && !viewModel.isTyping {
                                VStack(spacing: 16) {
                                    Spacer().frame(height: 60)
                                    AlbaAvatar(size: 64)
                                    Text(lang == .es
                                         ? "Hola, \(userViewModel.userName). ¿En qué te puedo ayudar hoy?"
                                         : "Hi, \(userViewModel.userName). How can I help you today?")
                                        .font(AlbaFont.rounded(16, weight: .medium))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                                .frame(maxWidth: .infinity)
                            }

                            ForEach(viewModel.messages) { message in
                                ChatBubble(
                                    message: message,
                                    onTakeTest: { friendName in
                                        viewModel.saveCurrentConversation()
                                        currentView = .newTestForFriend(friendName: friendName)
                                    },
                                    onDeclineTest: { friendName in
                                        viewModel.declineTest(messageId: message.id, friendName: friendName)
                                    }
                                )
                                .id(message.id)
                            }

                            if viewModel.isTyping {
                                HStack(alignment: .bottom, spacing: 8) {
                                    AlbaAvatar(size: 32)
                                    TypingIndicator()
                                    Spacer(minLength: 50)
                                }
                                .id("typing")
                                .transition(.opacity)
                            }

                            // Invisible anchor at the very bottom for auto-scroll
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: viewModel.messages.count) {
                        scrollToBottom(proxy)
                    }
                    .onChange(of: viewModel.isTyping) {
                        scrollToBottom(proxy)
                    }
                }

                // MARK: - Smart Suggestion Chips
                if !viewModel.isTyping && !viewModel.smartSuggestions.isEmpty {
                    SuggestionChipsView(suggestions: viewModel.smartSuggestions) { chip in
                        viewModel.currentInput = chip
                        sendMessage()
                    }
                    .padding(.vertical, 6)
                }

                // MARK: - Input Bar
                if viewModel.limitReached {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.orange)
                        Text(lang == .es
                             ? "Límite diario alcanzado. Vuelve mañana."
                             : "Daily limit reached. Come back tomorrow.")
                            .font(AlbaFont.rounded(14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                } else {
                    HStack(spacing: 12) {
                        TextField(L10n.t(.typeHere, lang), text: $viewModel.currentInput)
                            .font(AlbaFont.rounded(15))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                            .onSubmit { sendMessage() }

                        // Voice mode button — only visible if feature is enabled via RemoteConfig
                        if RemoteConfigService.shared.isVoiceModeEnabled {
                            Button {
                                HapticManager.shared.mediumImpact()
                                if voiceLimiter.hasReachedLimit {
                                    showVoiceLimitAlert = true
                                    HapticManager.shared.notification(.warning)
                                } else {
                                    viewModel.saveCurrentConversation()
                                    showVoiceCall = true
                                }
                            } label: {
                                Image(systemName: "waveform")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        voiceLimiter.hasReachedLimit
                                            ? AnyShapeStyle(Color.gray.opacity(0.35))
                                            : AnyShapeStyle(LinearGradient.albaAccentGradient)
                                    )
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel(L10n.t(.voiceModeButton, lang))
                        }

                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? AnyShapeStyle(Color.gray.opacity(0.3))
                                        : AnyShapeStyle(LinearGradient.albaAccentGradient)
                                )
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                }
            }
        }
        .onAppear {
            viewModel.language = lang
            if !userViewModel.hasCompletedAIOnboarding {
                showAIOnboarding = true
                // Don't call Gemini until onboarding is done
                return
            }
            initializeChatIfNeeded()
        }
        .onChange(of: languageManager.language) {
            viewModel.language = languageManager.language
        }
        .sheet(isPresented: $showHistory) {
            ChatHistoryView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showVoiceCall) {
            VoiceCallView(
                viewModel: VoiceCallViewModel(
                    chatViewModel: viewModel,
                    language: lang,
                    userName: userViewModel.userName
                )
            )
            .environmentObject(languageManager)
        }
        .alert(
            voiceLimitAlertTitle,
            isPresented: $showVoiceLimitAlert
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(voiceLimitAlertMessage)
        }
        .fullScreenCover(isPresented: $showAIOnboarding, onDismiss: {
            // After onboarding completes, now initialize chat with user's chosen style
            initializeChatIfNeeded()
        }) {
            AlbaAIOnboardingView()
        }
    }

    private func sendMessage() {
        guard !viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        HapticManager.shared.mediumImpact()
        viewModel.sendMessage()
    }

    // MARK: - Voice limit alert copy

    /// True when the minutes-cap was the reason — different title from calls-cap.
    private var voiceLimitAlertTitle: String {
        if voiceLimiter.hasReachedSecondsLimit {
            return L10n.t(.voiceCallDailyMinutesReached, lang)
        }
        return L10n.t(.voiceCallDailyLimitReached, lang)
    }

    private var voiceLimitAlertMessage: String {
        if voiceLimiter.hasReachedSecondsLimit {
            let mins = voiceLimiter.dailyTotalSecondsLimit / 60
            return lang == .es
                ? "Agotaste los \(mins) minutos diarios de voz. El contador se reinicia mañana."
                : "You've used your \(mins) daily voice minutes. The counter resets tomorrow."
        }
        return lang == .es
            ? "Usaste tus \(voiceLimiter.dailyCallLimit) llamadas de voz de hoy. El contador se reinicia mañana."
            : "You've used your \(voiceLimiter.dailyCallLimit) voice calls for today. The counter resets tomorrow."
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.3)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }

    private func initializeChatIfNeeded() {
        // Only run once per ChatView lifetime. Without this guard, the view's
        // .onAppear re-fires when a fullScreenCover (voice mode, AI onboarding)
        // dismisses — which would wipe the current conversation and create a
        // fresh one, losing any voice call summary that was just appended.
        guard !hasInitializedSession else { return }
        hasInitializedSession = true

        guard viewModel.messages.isEmpty else { return }

        if let context = initialContext {
            // Coming from test results - always start a fresh conversation
            viewModel.startNewConversation()
            viewModel.setInitialMessage(userName: userViewModel.userName, context: context)
        } else {
            // Regular chat - start fresh and empty. User can load history manually.
            viewModel.startNewConversation()
        }
    }
}

// MARK: - Chat History View
struct ChatHistoryView: View {
    @ObservedObject var viewModel: ChatViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    @State private var conversations: [SavedConversation] = []
    @State private var renameConvoId: UUID? = nil
    @State private var renameText: String = ""
    @State private var showRenameAlert: Bool = false

    private var lang: AppLanguage { languageManager.language }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.albaAccent)
                    }
                    Spacer()
                    Text(lang == .es ? "Historial" : "History")
                        .font(AlbaFont.serif(22, weight: .bold))
                        .foregroundColor(.albaText)
                    Spacer()
                    if !conversations.isEmpty {
                        Button(action: {
                            ConversationStore.shared.deleteAll()
                            conversations = []
                            HapticManager.shared.notification(.warning)
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(.red.opacity(0.7))
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)

                if conversations.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.3))
                        Text(lang == .es ? "Sin conversaciones guardadas" : "No saved conversations")
                            .font(AlbaFont.rounded(16, weight: .medium))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(conversations) { convo in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(convo.displayTitle)
                                    .font(AlbaFont.rounded(14, weight: .bold))
                                    .foregroundColor(.albaText)
                                    .lineLimit(1)
                                Text(cleanPreview(convo.preview))
                                    .font(AlbaFont.rounded(13))
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                HStack {
                                    Text(convo.displayDate)
                                        .font(AlbaFont.rounded(11))
                                        .foregroundColor(.albaAccent.opacity(0.7))
                                    Spacer()
                                    Text(lang == .es
                                         ? "\(convo.messages.count) msgs"
                                         : "\(convo.messages.count) msgs")
                                        .font(AlbaFont.rounded(11))
                                        .foregroundColor(.gray.opacity(0.6))
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.loadConversation(convo)
                                dismiss()
                            }
                            .contextMenu {
                                Button {
                                    renameConvoId = convo.id
                                    renameText = convo.title ?? ""
                                    showRenameAlert = true
                                } label: {
                                    Label(lang == .es ? "Renombrar" : "Rename", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    ConversationStore.shared.deleteConversation(id: convo.id)
                                    conversations = ConversationStore.shared.loadAllConversations()
                                } label: {
                                    Label(lang == .es ? "Eliminar" : "Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.albaBackground)
            .onAppear {
                conversations = ConversationStore.shared.loadAllConversations()
            }
            .alert(lang == .es ? "Renombrar conversación" : "Rename conversation", isPresented: $showRenameAlert) {
                TextField(lang == .es ? "Nombre" : "Title", text: $renameText)
                Button(lang == .es ? "Guardar" : "Save") {
                    if let id = renameConvoId, !renameText.isEmpty {
                        ConversationStore.shared.updateTitle(id: id, title: renameText)
                        conversations = ConversationStore.shared.loadAllConversations()
                    }
                }
                Button(lang == .es ? "Cancelar" : "Cancel", role: .cancel) {}
            }
        }
    }

    private func cleanPreview(_ text: String) -> String {
        text.replacingOccurrences(of: "**", with: "")
    }
}
