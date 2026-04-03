import Combine
import SwiftUI

// MARK: - Frame Capture (.global coordinate space)

struct SpotlightFramePreference: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    func spotlightAnchor(_ id: String) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: SpotlightFramePreference.self,
                    value: [id: proxy.frame(in: .global)]
                )
            }
        )
    }
}

// MARK: - Spotlight Mask (Path + eoFill)
// Identical technique to the original playground SpotlightMaskView.

private struct SpotlightMaskView: View {
    let holeRect: CGRect
    let cornerRadius: CGFloat
    let dimOpacity: Double

    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.addRect(CGRect(origin: .zero, size: geo.size))
                path.addRoundedRect(in: holeRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            }
            .fill(Color.black.opacity(dimOpacity), style: FillStyle(eoFill: true))
            .ignoresSafeArea()
        }
    }
}

// MARK: - Tutorial Manager

final class TutorialManager: ObservableObject {
    static let shared = TutorialManager()
    @Published var isActive = false
    @Published var currentStep = 0
    private let key = "alba_tutorial_completed"
    var hasSeenTutorial: Bool { UserDefaults.standard.bool(forKey: key) }

    func startIfFirstTime() {
        guard !hasSeenTutorial else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.4)) { self.isActive = true; self.currentStep = 0 }
        }
    }

    func next(_ total: Int) {
        HapticManager.shared.lightImpact()
        if currentStep < total - 1 {
            withAnimation(.easeInOut(duration: 0.25)) { currentStep += 1 }
        } else { dismiss() }
    }

    func dismiss() {
        HapticManager.shared.mediumImpact()
        withAnimation(.easeInOut(duration: 0.25)) { isActive = false }
        UserDefaults.standard.set(true, forKey: key)
    }
}

// MARK: - Tutorial Step Data

struct TutorialStepData {
    let anchorId: String
    let titleEs: String
    let titleEn: String
    let messageEs: String
    let messageEn: String
    let cornerRadius: CGFloat
    let padding: CGFloat

    func title(_ l: AppLanguage) -> String { l == .es ? titleEs : titleEn }
    func msg(_ l: AppLanguage) -> String { l == .es ? messageEs : messageEn }

    static let all: [TutorialStepData] = [
        .init(anchorId: "", titleEs: "Alba", titleEn: "Alba",
              messageEs: "Hola, soy Alba. Quiero mostrarte como funciona todo para que tengas la mejor experiencia.",
              messageEn: "Hi, I'm Alba. I want to show you how everything works so you have the best experience.",
              cornerRadius: 0, padding: 0),
        .init(anchorId: "albaBlocks", titleEs: "Alba Blocks", titleEn: "Alba Blocks",
              messageEs: "Aqui encontraras articulos cortos sobre amistades, limites sanos y bienestar emocional.",
              messageEn: "Here you'll find short articles about friendships, healthy boundaries, and emotional well-being.",
              cornerRadius: 28, padding: 10),
        .init(anchorId: "albaIA", titleEs: "AlbaIA", titleEn: "AlbaAI",
              messageEs: "Platica conmigo y recibe consejos basados en psicologia positiva.",
              messageEn: "Chat with me and get advice based on positive psychology.",
              cornerRadius: 28, padding: 10),
        .init(anchorId: "albaTest", titleEs: "Alba Test", titleEn: "Alba Test",
              messageEs: "Basado en psicologia positiva, reflexiona si esa amistad realmente vale la pena.",
              messageEn: "Based on positive psychology, reflect on whether a friendship is truly worth it.",
              cornerRadius: 28, padding: 10),
        .init(anchorId: "settings", titleEs: "Configuracion", titleEn: "Settings",
              messageEs: "Ajusta el idioma y escucha musica mientras usas la app.",
              messageEn: "Change the language and listen to music while using the app.",
              cornerRadius: 20, padding: 12),
        .init(anchorId: "", titleEs: "Lista!", titleEn: "Ready!",
              messageEs: "Estoy lista para ayudarte. Si te pierdes, siempre voy a estar aqui.",
              messageEn: "I'm ready to help you. If you ever feel lost, I'll always be here.",
              cornerRadius: 0, padding: 0),
    ]
}

// MARK: - Tutorial Overlay
// Placed INSIDE the HomeView ZStack (not as .overlay{}).
// Uses .global coordinates and .position() - matching the original playground.

struct SpotlightTutorialOverlay: View {
    let frames: [String: CGRect]
    let lang: AppLanguage
    @ObservedObject var mgr: TutorialManager
    var onNav: ((String) -> Void)?

    private let steps = TutorialStepData.all
    private let totalSteps = TutorialStepData.all.count

    private var step: TutorialStepData {
        steps[min(mgr.currentStep, steps.count - 1)]
    }

    /// Returns the hole rect if this step has a valid target
    private func holeFor(_ step: TutorialStepData) -> CGRect? {
        guard !step.anchorId.isEmpty,
              let frame = frames[step.anchorId],
              frame != .zero, frame.width > 1, frame.height > 1 else { return nil }
        return frame.insetBy(dx: -step.padding, dy: -step.padding)
    }

    var body: some View {
        if mgr.isActive {
            GeometryReader { geo in
                let safeTop = geo.safeAreaInsets.top
                let safeBottom = geo.safeAreaInsets.bottom

                ZStack {
                    if let hole = holeFor(step) {
                        // Step with spotlight target
                        SpotlightMaskView(holeRect: hole, cornerRadius: step.cornerRadius, dimOpacity: 0.55)

                        // Glow border
                        RoundedRectangle(cornerRadius: step.cornerRadius)
                            .stroke(Color.white.opacity(0.92), lineWidth: 3)
                            .frame(width: hole.width, height: hole.height)
                            .position(x: hole.midX, y: hole.midY)
                            .shadow(color: Color.white.opacity(0.25), radius: 12)

                        // Clickable area on the spotlight
                        if let nav = onNav {
                            Button(action: { mgr.dismiss(); nav(step.anchorId) }) { Color.clear }
                                .frame(width: hole.width, height: hole.height)
                                .position(x: hole.midX, y: hole.midY)
                                .contentShape(RoundedRectangle(cornerRadius: step.cornerRadius))
                        }

                        // Card - positioned above or below the hole
                        let shouldPlaceAbove = (hole.minY - 120) > (safeTop + 150)

                        tutorialCard(step: step)
                            .position(
                                x: geo.size.width / 2,
                                y: shouldPlaceAbove
                                    ? (hole.minY - 120)
                                    : min(hole.maxY + 140, geo.size.height - safeBottom - 110)
                            )
                    } else {
                        // Intro / Done step - full dim, centered card
                        Color.black.opacity(0.45)
                            .ignoresSafeArea()

                        tutorialCard(step: step)
                            .position(x: geo.size.width / 2, y: max(safeTop + 160, 160))
                    }
                }
            }
            .transition(.opacity)
            .zIndex(999)
        }
    }

    // MARK: - Tutorial Card

    private func tutorialCard(step: TutorialStepData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                AlbaAvatarSquare(size: 34)

                Text(step.title(lang))
                    .font(AlbaFont.serif(20, weight: .heavy))
                    .foregroundColor(.albaText)

                Spacer()

                Text("\(mgr.currentStep + 1)/\(totalSteps)")
                    .font(AlbaFont.rounded(12, weight: .semibold))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.gray.opacity(0.1)))
            }

            // Message
            Text(step.msg(lang))
                .font(AlbaFont.rounded(15, weight: .medium))
                .foregroundColor(.albaText.opacity(0.85))
                .lineSpacing(5)

            // Buttons
            HStack(spacing: 12) {
                // Skip (only step 0)
                if mgr.currentStep == 0 {
                    Button(action: { mgr.dismiss() }) {
                        Text(L10n.t(.tutSkip, lang))
                            .font(AlbaFont.rounded(14, weight: .semibold))
                            .foregroundColor(.albaText.opacity(0.6))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                            .background(Color.white.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                // Open (only spotlight steps)
                if !step.anchorId.isEmpty, let nav = onNav {
                    Button(action: { mgr.dismiss(); nav(step.anchorId) }) {
                        Text(L10n.t(.tutOpen, lang))
                            .font(AlbaFont.rounded(14, weight: .semibold))
                            .foregroundColor(.albaAccent)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                            .background(Color.albaAccent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                Spacer()

                // Next / Start
                Button(action: { mgr.next(totalSteps) }) {
                    Text(mgr.currentStep == totalSteps - 1 ? L10n.t(.tutStart, lang) : L10n.t(.tutNext, lang))
                        .font(AlbaFont.rounded(14, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 22)
                        .background(
                            LinearGradient(colors: [Color.albaAccent, Color.albaAccent.opacity(0.92)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color.albaAccent.opacity(0.30), radius: 10, x: 0, y: 6)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .frame(maxWidth: UIScreen.main.bounds.width - 40, alignment: .leading)
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
    }
}
