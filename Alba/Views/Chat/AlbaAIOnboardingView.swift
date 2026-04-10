import SwiftUI

struct AlbaAIOnboardingView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - State Machine

    enum OnboardingStep: Int, CaseIterable {
        case agreement = 0
        case tourChat = 1
        case tourTest = 2
        case done = 3
    }

    @State private var currentStep: OnboardingStep = .agreement

    private var lang: AppLanguage { languageManager.language }
    private var totalSteps: Int { OnboardingStep.allCases.count }

    var body: some View {
        ZStack {
            AnimatedMeshBackground()
                .opacity(0.4)

            Color.albaBackground
                .ignoresSafeArea()
                .opacity(0.6)

            VStack(spacing: 0) {
                topBar

                // Step content with transitions
                ZStack {
                    switch currentStep {
                    case .agreement:
                        agreementStep
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                    case .tourChat:
                        tourChatStep
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                    case .tourTest:
                        tourTestStep
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                    case .done:
                        doneStep
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                    }
                }
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: currentStep)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            if currentStep != .agreement {
                Button { goBack() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.albaText)
                }
            } else {
                Color.clear.frame(width: 16, height: 16)
            }

            Spacer()

            Text("\(currentStep.rawValue + 1)/\(totalSteps)")
                .font(AlbaFont.rounded(12, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.gray.opacity(0.1)))

            Spacer()

            Color.clear.frame(width: 16, height: 16)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    // MARK: - Step 1: Agreement

    private var agreementStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 12)

                AlbaAvatarSquare(size: 56)

                Text(L10n.t(.aiOnboardingPrivacyTitle, lang))
                    .font(AlbaFont.serif(26, weight: .bold))
                    .foregroundColor(.albaText)
                    .multilineTextAlignment(.center)

                // Privacy card
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.albaAccent)

                        Text(lang == .es ? "Privacidad" : "Privacy")
                            .font(AlbaFont.rounded(16, weight: .bold))
                            .foregroundColor(.albaText)
                    }

                    Text(L10n.t(.aiOnboardingPrivacyBody, lang))
                        .font(AlbaFont.rounded(15))
                        .foregroundColor(.albaText.opacity(0.85))
                        .lineSpacing(5)
                }
                .padding(20)
                .glassCard()
                .padding(.horizontal, 24)

                // AI Disclaimer card
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)

                        Text(lang == .es ? "Aviso importante" : "Important notice")
                            .font(AlbaFont.rounded(16, weight: .bold))
                            .foregroundColor(.albaText)
                    }

                    Text(markdownToAttributed(L10n.t(.aiOnboardingDisclaimerBody, lang)))
                        .font(AlbaFont.rounded(15))
                        .foregroundColor(.albaText.opacity(0.85))
                        .lineSpacing(5)
                }
                .padding(20)
                .glassCard()
                .padding(.horizontal, 24)

                Spacer().frame(height: 8)

                GlassActionButton(L10n.t(.aiOnboardingAccept, lang), icon: "checkmark.shield.fill") {
                    advanceStep()
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 32)
            }
        }
    }

    // MARK: - Step 2: Tour Chat

    private var tourChatStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                // Mock chat preview
                VStack(spacing: 12) {
                    // Mock top bar
                    HStack {
                        Spacer()
                        Text(L10n.t(.chatTitle, lang))
                            .font(AlbaFont.serif(16, weight: .bold))
                            .foregroundColor(.albaText)
                        Spacer()
                    }
                    .padding(.vertical, 10)

                    // Mock messages
                    mockUserBubble(lang == .es
                        ? "Siento que mi amiga ya no me busca como antes..."
                        : "I feel like my friend doesn't reach out like before...")

                    mockAlbaBubble(lang == .es
                        ? "Entiendo cómo te sientes. Eso puede afectar la dimensión de **Compromiso** en tu amistad. Te propongo algo: esta semana intenta iniciar una conversación y expresar lo que sientes."
                        : "I understand how you feel. That can affect the **Engagement** dimension of your friendship. Here's an idea: this week, try starting a conversation and expressing how you feel.")
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                .padding(.horizontal, 24)

                // Explanation card
                explanationCard(
                    title: L10n.t(.aiOnboardingTourChatTitle, lang),
                    body: L10n.t(.aiOnboardingTourChatBody, lang)
                )

                GlassActionButton(L10n.t(.aiOnboardingContinue, lang), icon: "arrow.right") {
                    advanceStep()
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 32)
            }
        }
    }

    // MARK: - Step 3: Tour Test

    private var tourTestStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                // Mock conversation showing the test card
                VStack(spacing: 12) {
                    mockAlbaBubble(lang == .es
                        ? "Podría evaluar tu amistad con Laura. Parece que es alguien importante para ti."
                        : "I could evaluate your friendship with Laura. It seems like she's someone important to you.")

                    // Actual TakeTestCard component
                    TakeTestCard(friendName: "Laura") {
                        HapticManager.shared.lightImpact()
                    }
                    .padding(.leading, 40)
                    .allowsHitTesting(false)
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                .padding(.horizontal, 24)

                // Explanation card
                explanationCard(
                    title: L10n.t(.aiOnboardingTourTestTitle, lang),
                    body: L10n.t(.aiOnboardingTourTestBody, lang)
                )

                GlassActionButton(L10n.t(.aiOnboardingContinue, lang), icon: "arrow.right") {
                    advanceStep()
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 32)
            }
        }
    }

    // MARK: - Step 4: Done

    @State private var doneAvatarScale: CGFloat = 0.5
    @State private var doneAvatarOpacity: Double = 0

    private var doneStep: some View {
        VStack(spacing: 28) {
            Spacer()

            AlbaAvatar(size: 80)
                .scaleEffect(doneAvatarScale)
                .opacity(doneAvatarOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        doneAvatarScale = 1.0
                        doneAvatarOpacity = 1.0
                    }
                }

            Text(L10n.t(.aiOnboardingDoneTitle, lang))
                .font(AlbaFont.serif(28, weight: .bold))
                .foregroundColor(.albaText)

            Text(L10n.t(.aiOnboardingDoneBody, lang))
                .font(AlbaFont.rounded(16, weight: .medium))
                .foregroundColor(.albaText.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            GlassActionButton(L10n.t(.aiOnboardingGetStarted, lang), icon: "sparkles") {
                completeOnboarding()
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 40)
        }
    }

    // MARK: - Shared Components

    private func explanationCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                AlbaAvatarSquare(size: 34)

                Text(title)
                    .font(AlbaFont.serif(20, weight: .heavy))
                    .foregroundColor(.albaText)
            }

            Text(body)
                .font(AlbaFont.rounded(15, weight: .medium))
                .foregroundColor(.albaText.opacity(0.85))
                .lineSpacing(5)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.14), radius: 18, x: 0, y: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.albaAccent.opacity(0.20), lineWidth: 1.2)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.albaAccent.opacity(0.28))
                .frame(height: 5)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 24)
    }

    private func mockUserBubble(_ text: String) -> some View {
        HStack {
            Spacer(minLength: 50)
            Text(text)
                .font(AlbaFont.rounded(14))
                .lineSpacing(4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(LinearGradient.albaAccentGradient)
                .foregroundColor(.white)
                .clipShape(
                    RoundedCorner(radius: 18, corners: [.topLeft, .topRight, .bottomLeft])
                )
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
    }

    private func mockAlbaBubble(_ text: String) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            AlbaAvatar(size: 28)

            Text(markdownToAttributed(text))
                .font(AlbaFont.rounded(14))
                .lineSpacing(4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .foregroundColor(.albaText)
                .clipShape(
                    RoundedCorner(radius: 18, corners: [.topLeft, .topRight, .bottomRight])
                )
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)

            Spacer(minLength: 50)
        }
    }

    // MARK: - Navigation

    private func advanceStep() {
        HapticManager.shared.lightImpact()
        guard let nextIndex = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentStep = nextIndex
        }
    }

    private func goBack() {
        HapticManager.shared.lightImpact()
        guard let prevIndex = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentStep = prevIndex
        }
    }

    private func completeOnboarding() {
        HapticManager.shared.notification(.success)
        userViewModel.hasCompletedAIOnboarding = true
        dismiss()
    }

    // MARK: - Helpers

    private func markdownToAttributed(_ text: String) -> AttributedString {
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributed
        }
        return AttributedString(text)
    }
}
