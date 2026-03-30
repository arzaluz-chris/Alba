import SwiftUI

struct TestResultsView: View {
    let result: TestResult
    @Binding var currentView: AppState
    @EnvironmentObject var languageManager: LanguageManager

    let onExploreWithAlba: (String) -> Void
    let onBack: () -> Void

    @State private var appeared = false

    private var lang: AppLanguage { languageManager.language }

    private var ratingIcon: String {
        result.color == .resultHigh ? "heart.fill" : "person.2.fill"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                // MARK: - Rating Badge
                Text(result.finalRating)
                    .font(AlbaFont.rounded(15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(result.color)
                    .clipShape(Capsule())
                    .shadow(color: result.color.opacity(0.4), radius: 12, x: 0, y: 6)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)

                // MARK: - Icon
                Image(systemName: ratingIcon)
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(result.color)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.2), value: appeared)

                // MARK: - Analysis Card
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(result.summaryAnalysis)
                            .font(AlbaFont.serif(16))
                            .foregroundColor(.albaText)
                            .lineSpacing(5)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)

                Divider()
                    .padding(.horizontal, 20)

                // MARK: - Recommendation Card
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(result.summaryRecommendation)
                            .font(AlbaFont.rounded(15))
                            .foregroundColor(.albaText)
                            .lineSpacing(5)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)
                .animation(.easeOut(duration: 0.5).delay(0.45), value: appeared)

                // MARK: - Perception Disclaimer
                Text(L10n.t(.basedOnPerception, lang))
                    .font(AlbaFont.caption())
                    .foregroundColor(.albaText.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                // MARK: - Actions
                VStack(spacing: 12) {
                    let context = lang == .es
                        ? "Estos son mis resultados del Alba Test sobre mi amistad con \(result.friendName): \(result.finalRating). Área de enfoque: \(result.focusAreaDisplay). Análisis: \(result.summaryAnalysis). Recomendación: \(result.summaryRecommendation). ¿Puedes ayudarme a explorar esto?"
                        : "These are my Alba Test results about my friendship with \(result.friendName): \(result.finalRating). Focus area: \(result.focusAreaDisplay). Analysis: \(result.summaryAnalysis). Recommendation: \(result.summaryRecommendation). Can you help me explore this?"

                    GlassActionButton(L10n.t(.exploreWithAlba, lang), icon: "bubble.left.and.text.bubble.right", style: .primary) {
                        onExploreWithAlba(context)
                    }

                    GlassActionButton(L10n.t(.backToHome, lang), icon: nil, style: .subtle) {
                        onBack()
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.6), value: appeared)

                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 28)
        }
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }
}
