import SwiftUI

struct ChatView: View {
    @Binding var currentView: AppState
    @StateObject private var viewModel: ChatViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var userViewModel: UserViewModel

    let initialContext: String?

    @State private var showHistory = false

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
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message) { friendName in
                                    viewModel.saveCurrentConversation()
                                    currentView = .albaTest
                                }
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
            if viewModel.messages.isEmpty {
                // Try to resume the current conversation from disk
                if initialContext == nil, let saved = ConversationStore.shared.loadAllConversations().first(where: { $0.id == viewModel.conversationId }) {
                    viewModel.loadConversation(saved)
                } else {
                    viewModel.setInitialMessage(userName: userViewModel.userName, context: initialContext)
                }
            }
        }
        .onChange(of: languageManager.language) {
            viewModel.language = languageManager.language
        }
        .sheet(isPresented: $showHistory) {
            ChatHistoryView(viewModel: viewModel)
        }
    }

    private func sendMessage() {
        guard !viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        HapticManager.shared.mediumImpact()
        viewModel.sendMessage()
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.3)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
}

// MARK: - Chat History View
struct ChatHistoryView: View {
    @ObservedObject var viewModel: ChatViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    @State private var conversations: [SavedConversation] = []

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
                            Button {
                                viewModel.loadConversation(convo)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(convo.displayDate)
                                        .font(AlbaFont.rounded(13, weight: .semibold))
                                        .foregroundColor(.albaAccent)
                                    Text(convo.preview)
                                        .font(AlbaFont.rounded(14))
                                        .foregroundColor(.albaText)
                                        .lineLimit(2)
                                    Text(lang == .es
                                         ? "\(convo.messages.count) mensajes"
                                         : "\(convo.messages.count) messages")
                                        .font(AlbaFont.rounded(12))
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                ConversationStore.shared.deleteConversation(id: conversations[index].id)
                            }
                            conversations.remove(atOffsets: indexSet)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.albaBackground)
            .onAppear {
                conversations = ConversationStore.shared.loadAllConversations()
            }
        }
    }
}
