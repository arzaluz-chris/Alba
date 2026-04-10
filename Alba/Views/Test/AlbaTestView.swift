import SwiftUI

struct AlbaTestView: View {
    @Binding var currentView: AppState
    @ObservedObject var viewModel: TestViewModel
    @ObservedObject var userViewModel: UserViewModel
    @EnvironmentObject var languageManager: LanguageManager

    @State private var showingInstructions = true
    @State private var showingResults = false
    @State private var testResult: TestResult?
    @State private var questionTransition = false

    private var lang: AppLanguage { languageManager.language }

    var body: some View {
        ZStack {
            Color.albaBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top Bar
                ZStack {
                    HStack {
                        Button {
                            HapticManager.shared.lightImpact()
                            viewModel.resetTest()
                            currentView = .welcome
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.albaText)
                        }
                        Spacer()
                    }

                    Text(L10n.t(.albaTestTitle, lang))
                        .font(AlbaFont.serif(20, weight: .bold))
                        .foregroundColor(.albaText)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)

                // MARK: - Content
                if showingResults, let result = testResult {
                    TestResultsView(
                        result: result,
                        currentView: $currentView,
                        onExploreWithAlba: { context in
                            currentView = .chat(initialContext: context)
                        },
                        onBack: {
                            viewModel.resetTest()
                            currentView = .welcome
                        }
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                } else if showingInstructions {
                    instructionsView
                        .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
                } else {
                    questionView
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                }
            }
        }
        .onAppear {
            viewModel.language = lang
        }
        .onChange(of: languageManager.language) { newLang in
            viewModel.language = newLang
        }
    }

    // MARK: - Instructions View
    private var instructionsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Image(systemName: "checklist.rtl")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.albaAccent)

                let genderSuffix = userViewModel.selectedGender == .chica
                    ? (lang == .es ? "a" : "")
                    : (lang == .es ? "o" : "")

                Text(L10n.t(.welcomeGendered, lang, genderSuffix, userViewModel.userName))
                    .font(AlbaFont.serif(26, weight: .bold))
                    .foregroundColor(.albaText)
                    .multilineTextAlignment(.center)

                Text(L10n.t(.testIntro, lang))
                    .font(AlbaFont.rounded(15))
                    .foregroundColor(.albaText.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 8)

                Text(L10n.t(.instructionChoose, lang))
                    .font(AlbaFont.rounded(14, weight: .medium))
                    .foregroundColor(.albaAccent)

                GlassActionButton(L10n.t(.startTest, lang), icon: "play.fill", style: .primary) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showingInstructions = false
                    }
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Question View
    private var questionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 16)

                // Progress
                Text(L10n.t(.questionProgress, lang, viewModel.currentQuestionIndex + 1, viewModel.questions.count))
                    .font(AlbaFont.caption())
                    .foregroundColor(.albaText.opacity(0.5))

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient.albaAccentGradient)
                            .frame(width: geo.size.width * CGFloat(viewModel.currentQuestionIndex + 1) / CGFloat(viewModel.questions.count), height: 6)
                            .animation(.spring(response: 0.4), value: viewModel.currentQuestionIndex)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 4)

                // Question Text
                Text(viewModel.getProcessedQuestionText())
                    .font(AlbaFont.serif(22, weight: .semibold))
                    .foregroundColor(.albaText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .id(viewModel.currentQuestionIndex)

                Divider()
                    .padding(.horizontal, 20)

                // MARK: - Answer Area
                switch viewModel.currentQuestion.type {
                case .genderSelection:
                    genderSelectionView

                case .singleChoice:
                    singleChoiceView

                case .textInput:
                    textInputView
                }

                Spacer().frame(height: 10)

                // MARK: - Next / See Results
                let buttonTitle = viewModel.isLastQuestion
                    ? L10n.t(.seeResults, lang)
                    : L10n.t(.nextQuestion, lang)

                GlassActionButton(buttonTitle, icon: viewModel.isLastQuestion ? "star.fill" : "arrow.right", style: .primary) {
                    guard viewModel.isAnswerSelected else { return }
                    if viewModel.isLastQuestion {
                        let result = viewModel.calculateResult()
                        testResult = result
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showingResults = true
                        }
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.nextQuestion()
                        }
                    }
                }
                .opacity(viewModel.isAnswerSelected ? 1 : 0.4)
                .disabled(!viewModel.isAnswerSelected)
                .allowsHitTesting(viewModel.isAnswerSelected)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Gender Selection
    private var genderSelectionView: some View {
        HStack(spacing: 16) {
            GenderButton(
                label: L10n.t(.man, lang),
                icon: "figure.stand",
                gender: .chico,
                selectedGender: $viewModel.friendGenderSelection
            )

            GenderButton(
                label: L10n.t(.woman, lang),
                icon: "figure.stand.dress",
                gender: .chica,
                selectedGender: $viewModel.friendGenderSelection
            )
        }
    }

    // MARK: - Single Choice
    private var singleChoiceView: some View {
        VStack(spacing: 12) {
            if let options = viewModel.currentQuestion.options(for: lang) {
                ForEach(options) { option in
                    OptionButton(
                        option: option,
                        isSelected: viewModel.selectedAnswers[viewModel.currentQuestion.id]?.id == option.id,
                        wasPreviousAnswer: viewModel.previousAnswers[viewModel.currentQuestionIndex] == option.value
                    ) {
                        viewModel.selectOption(option: option)
                    }
                }
            }
        }
    }

    // MARK: - Text Input
    private var textInputView: some View {
        VStack(spacing: 16) {
            TextField(L10n.t(.friendNamePlaceholder, lang), text: $viewModel.friendNameInput)
                .font(AlbaFont.rounded(16))
                .padding(16)
                .background(Color.white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
                .disabled(viewModel.shouldSkipName)
                .opacity(viewModel.shouldSkipName ? 0.4 : 1)
                .onChange(of: viewModel.friendNameInput) { newValue in
                    viewModel.friendNameInput = viewModel.cleanName(newValue)
                }

            if !viewModel.friendNameInput.isEmpty && !viewModel.isValidName(viewModel.friendNameInput) && !viewModel.shouldSkipName {
                Text(L10n.t(.friendNameValidation, lang))
                    .font(AlbaFont.caption())
                    .foregroundColor(.resultLow)
                    .multilineTextAlignment(.center)
            }

            Button {
                HapticManager.shared.selection()
                viewModel.shouldSkipName.toggle()
                if viewModel.shouldSkipName {
                    viewModel.friendNameInput = ""
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.shouldSkipName ? "checkmark.square.fill" : "square")
                        .foregroundColor(.albaAccent)
                    Text(L10n.t(.preferNotName, lang))
                        .font(AlbaFont.rounded(14))
                        .foregroundColor(.albaText.opacity(0.7))
                }
            }
        }
    }
}
