import SwiftUI

struct IntroView: View {
    @Binding var currentView: AppState
    @EnvironmentObject var languageManager: LanguageManager

    @State private var currentSlide: Int = 0
    @State private var slideOpacity: Double = 0
    @State private var slideOffset: CGFloat = 30
    @State private var iconScale: Double = 1.0

    private let totalSlides = 6

    private var slides: [(icon: String, text: String)] {
        if languageManager.language == .es {
            return [
                ("person.3.fill", "Estar rodeado de gente"),
                ("person.crop.circle.badge.exclamationmark", "no es lo mismo que estar acompañado"),
                ("heart.fill", "Y eso puede doler"),
                ("sparkles", "Pero no tienes que estar solo"),
                ("quote.bubble.fill", "Porque a veces")
            ]
        } else {
            return [
                ("person.3.fill", "Being surrounded by people"),
                ("person.crop.circle.badge.exclamationmark", "is not the same as being accompanied"),
                ("heart.fill", "And that can hurt"),
                ("sparkles", "But you don't have to be alone"),
                ("quote.bubble.fill", "Because sometimes")
            ]
        }
    }

    var body: some View {
        ZStack {
            IntroAnimatedBackground()

            VStack {
                // Slide counter pill
                HStack {
                    Spacer()
                    Text("\(currentSlide + 1)/\(totalSlides)")
                        .font(AlbaFont.rounded(13, weight: .semibold))
                        .foregroundColor(.albaText.opacity(0.6))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)

                Spacer()

                // Slide content
                TabView(selection: $currentSlide) {
                    ForEach(0..<5, id: \.self) { index in
                        textSlide(index: index)
                            .tag(index)
                    }

                    finalSlide
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 420)
                .onChange(of: currentSlide) { _ in
                    animateSlideIn()
                }

                Spacer()

                // Bottom button
                if currentSlide < 5 {
                    GlassActionButton(
                        languageManager.language == .es ? "Siguiente" : "Next",
                        icon: "chevron.right",
                        action: {
                            HapticManager.shared.lightImpact()
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentSlide += 1
                            }
                        }
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }

                if currentSlide == 5 {
                    GlassActionButton(
                        languageManager.language == .es ? "Listo para empezar" : "Ready to begin",
                        icon: "arrow.right",
                        action: {
                            HapticManager.shared.mediumImpact()
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentView = .signIn
                            }
                        }
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
            }
        }
        .onAppear {
            animateSlideIn()
        }
    }

    // MARK: - Text Slide

    private func textSlide(index: Int) -> some View {
        VStack(spacing: 32) {
            // Icon in gradient circle
            ZStack {
                Circle()
                    .fill(LinearGradient.albaWarm)
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.albaAccent.opacity(0.3), radius: 20, y: 10)

                Image(systemName: slides[index].icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(LinearGradient.albaAccentGradient)
                    .scaleEffect(iconScale)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                ) {
                    iconScale = 1.08
                }
            }

            // Text in glass card
            VStack(spacing: 12) {
                Text(slides[index].text)
                    .font(AlbaFont.serif(24, weight: .bold))
                    .foregroundColor(.albaText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .padding(28)
            .glassCard(cornerRadius: 24)
            .padding(.horizontal, 30)
        }
        .opacity(currentSlide == index ? slideOpacity : 0.5)
        .offset(y: currentSlide == index ? 0 : slideOffset)
    }

    // MARK: - Final Slide

    private var finalSlide: some View {
        VStack(spacing: 32) {
            // Logo in ring
            ZStack {
                Circle()
                    .strokeBorder(
                        LinearGradient.albaAccentGradient,
                        lineWidth: 3
                    )
                    .frame(width: 160, height: 160)
                    .shadow(color: Color.albaAccent.opacity(0.2), radius: 20)

                Image("ALBA_LOGO")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
            }

            VStack(spacing: 12) {
                Text("Alba")
                    .font(AlbaFont.serif(32, weight: .heavy))
                    .foregroundColor(.albaText)

                Text(languageManager.language == .es
                     ? "todo empieza con alguien\nque se queda"
                     : "everything starts with someone\nwho stays")
                    .font(AlbaFont.serif(18, weight: .medium))
                    .foregroundColor(.albaText.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(28)
            .glassCard(cornerRadius: 24)
            .padding(.horizontal, 30)
        }
        .opacity(currentSlide == 5 ? slideOpacity : 0.5)
        .offset(y: currentSlide == 5 ? 0 : slideOffset)
    }

    // MARK: - Animation Helper

    private func animateSlideIn() {
        slideOpacity = 0
        slideOffset = 30
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            slideOpacity = 1.0
            slideOffset = 0
        }
    }
}
