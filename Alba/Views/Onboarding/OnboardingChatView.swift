import SwiftUI

struct OnboardingChatView: View {
    @Binding var currentView: AppState
    @ObservedObject var userViewModel: UserViewModel
    @EnvironmentObject var languageManager: LanguageManager

    @State private var chatStep: Int = 0
    @State private var messages: [(String, Bool)] = [] // (text, isUser)
    @State private var showGenderButtons: Bool = false
    @State private var showNameInput: Bool = false
    @State private var showStartButton: Bool = false
    @State private var nameInput: String = ""
    @State private var isTyping: Bool = false

    private var isES: Bool { languageManager.language == .es }

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 0) {
                // Header
                HStack {
                    AlbaAvatar(size: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Alba")
                            .font(AlbaFont.serif(18, weight: .bold))
                            .foregroundColor(.albaText)

                        if isTyping {
                            Text(isES ? "escribiendo..." : "typing...")
                                .font(AlbaFont.rounded(12))
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 12)

                Divider().opacity(0.2)

                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                                chatBubble(text: message.0, isUser: message.1)
                                    .id(index)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .offset(y: 20)),
                                        removal: .opacity
                                    ))
                            }

                            // Typing indicator
                            if isTyping {
                                typingIndicator
                                    .id("typing")
                                    .transition(.opacity)
                            }

                            // Gender buttons
                            if showGenderButtons {
                                genderButtonsView
                                    .id("gender")
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.9)),
                                        removal: .opacity
                                    ))
                            }

                            // Name input
                            if showNameInput {
                                nameInputView
                                    .id("nameInput")
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.9)),
                                        removal: .opacity
                                    ))
                            }

                            // Start button
                            if showStartButton {
                                startButtonView
                                    .id("startBtn")
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.9)),
                                        removal: .opacity
                                    ))
                            }

                            // Bottom spacer for scroll
                            Color.clear.frame(height: 20)
                                .id("bottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    .onChange(of: messages.count) {
                        withAnimation(.spring(response: 0.4)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                    .onChange(of: showGenderButtons) {
                        withAnimation(.spring(response: 0.4)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                    .onChange(of: showNameInput) {
                        withAnimation(.spring(response: 0.4)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                    .onChange(of: showStartButton) {
                        withAnimation(.spring(response: 0.4)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
        }
        .onAppear {
            startConversation()
        }
    }

    // MARK: - Chat Bubble

    private func chatBubble(text: String, isUser: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            if !isUser {
                AlbaAvatar(size: 30)
            }

            Text(text)
                .font(AlbaFont.rounded(16))
                .foregroundColor(isUser ? .white : .albaText)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if isUser {
                            LinearGradient.albaAccentGradient
                        } else {
                            Color.albaSurface.opacity(0.8)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 8, y: 4)

            if !isUser { Spacer(minLength: 60) }
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(alignment: .bottom, spacing: 8) {
            AlbaAvatar(size: 30)

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .offset(y: typingDotOffset(for: i))
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(i) * 0.15),
                            value: isTyping
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.albaSurface.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Spacer(minLength: 60)
        }
    }

    private func typingDotOffset(for index: Int) -> CGFloat {
        isTyping ? -4 : 0
    }

    // MARK: - Gender Buttons

    private var genderButtonsView: some View {
        HStack(spacing: 12) {
            Spacer(minLength: 40)

            Button(action: { selectGender(.chico) }) {
                Text(isES ? "Hombre" : "Male")
                    .font(AlbaFont.rounded(15, weight: .semibold))
                    .foregroundColor(.albaText)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .glassCard(cornerRadius: 20)
            }

            Button(action: { selectGender(.chica) }) {
                Text(isES ? "Mujer" : "Female")
                    .font(AlbaFont.rounded(15, weight: .semibold))
                    .foregroundColor(.albaText)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .glassCard(cornerRadius: 20)
            }
        }
    }

    // MARK: - Name Input

    private var nameInputView: some View {
        HStack(spacing: 10) {
            Spacer(minLength: 40)

            HStack(spacing: 10) {
                TextField(isES ? "Tu nombre..." : "Your name...", text: $nameInput)
                    .font(AlbaFont.rounded(16))
                    .foregroundColor(.albaText)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)

                Button(action: submitName) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(LinearGradient.albaAccentGradient)
                }
                .disabled(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1.0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassCard(cornerRadius: 24)
        }
    }

    // MARK: - Start Button

    private var startButtonView: some View {
        HStack {
            Spacer()

            GlassActionButton(
                isES ? "Empezar" : "Let's begin",
                icon: "arrow.right") {
                    HapticManager.shared.mediumImpact()
                    userViewModel.hasCompletedOnboarding = true
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentView = .welcome
                    }
                }
            .frame(maxWidth: 200)

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Conversation Flow

    private func startConversation() {
        // Step 0: Greeting
        showTyping()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            hideTypingAndAdd(isES ? "¡Hola! Soy Alba 👋" : "Hi! I'm Alba 👋")
        }

        // Step 1: Ask gender (combined with intro)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            showTyping()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            hideTypingAndAdd(isES
                ? "Antes de comenzar, ¿cómo te identificas?"
                : "Before we start, how do you identify?")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showGenderButtons = true
                }
            }
        }
    }

    private func selectGender(_ gender: Gender) {
        HapticManager.shared.lightImpact()
        userViewModel.selectedGender = gender

        let label = gender == .chico
            ? (isES ? "Hombre" : "Male")
            : (isES ? "Mujer" : "Female")

        withAnimation(.spring(response: 0.4)) {
            showGenderButtons = false
            messages.append((label, true))
        }

        // Check if we already have the name from Apple Sign In or from prior auth
        let appleName = UserDefaults.standard.string(forKey: "appleUserGivenName")
            ?? UserDefaults.standard.string(forKey: "appleUserName")
        if let appleName, !appleName.isEmpty {
            // Pre-fill name and skip the name question
            userViewModel.userName = appleName

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showTyping()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                hideTypingAndAdd(isES
                    ? "Mucho gusto, \(appleName) ✨"
                    : "Nice to meet you, \(appleName) ✨")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showTyping()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                hideTypingAndAdd(isES
                    ? "Estoy lista para ayudarte. ¿Empezamos?"
                    : "I'm ready to help you. Shall we begin?")

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showStartButton = true
                    }
                }
            }
        } else {
            // No Apple name - ask for name
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showTyping()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                hideTypingAndAdd(isES ? "¡Genial! ¿Y cómo te llamas?" : "Great! And what's your name?")

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showNameInput = true
                    }
                }
            }
        }
    }

    private func submitName() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        HapticManager.shared.lightImpact()
        userViewModel.userName = trimmed

        withAnimation(.spring(response: 0.4)) {
            showNameInput = false
            messages.append((trimmed, true))
        }

        // Alba responds with greeting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showTyping()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            hideTypingAndAdd(isES
                ? "Mucho gusto, \(userViewModel.userName) ✨"
                : "Nice to meet you, \(userViewModel.userName) ✨")
        }

        // Final message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showTyping()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            hideTypingAndAdd(isES
                ? "Estoy lista para ayudarte. ¿Empezamos?"
                : "I'm ready to help you. Shall we begin?")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showStartButton = true
                }
            }
        }
    }

    // MARK: - Helpers

    private func showTyping() {
        withAnimation(.easeIn(duration: 0.2)) {
            isTyping = true
        }
    }

    private func hideTypingAndAdd(_ text: String) {
        HapticManager.shared.lightImpact()
        withAnimation(.spring(response: 0.4)) {
            isTyping = false
            messages.append((text, false))
        }
    }
}
