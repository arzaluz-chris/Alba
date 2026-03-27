import UIKit

final class HapticManager {
    static let shared = HapticManager()
    private init() {}

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
    }

    func lightImpact() { lightGenerator.impactOccurred() }
    func mediumImpact() { mediumGenerator.impactOccurred() }
    func heavyImpact() { heavyGenerator.impactOccurred() }
    func selection() { selectionGenerator.selectionChanged() }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }

    /// Haptic pattern when AI text arrives: strong → fading to light
    /// Simulates the feeling of text "landing" on screen
    func textArrivedPattern(pulses: Int = 4) {
        Task { @MainActor in
            var intensity: CGFloat = 1.0
            for i in 0..<pulses {
                if i == 0 {
                    heavyGenerator.impactOccurred(intensity: intensity)
                } else {
                    mediumGenerator.impactOccurred(intensity: intensity)
                }
                try? await Task.sleep(for: .milliseconds(120))
                intensity = max(0.2, intensity - 0.2)
            }
        }
    }
}
