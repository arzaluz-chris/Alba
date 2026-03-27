import SwiftUI
import UIKit

// MARK: - Adaptive Color Palette (Light + Dark)
extension Color {
    // Background: warm cream (light) → deep charcoal (dark)
    static let albaBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 1)
            : UIColor(red: 0.97, green: 0.95, blue: 0.93, alpha: 1)
    })

    // Accent: coral — same in both modes (slightly brighter in dark)
    static let albaAccent = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.58, blue: 0.48, alpha: 1)
            : UIColor(red: 0.85, green: 0.55, blue: 0.45, alpha: 1)
    })

    // Text: dark brown (light) → warm off-white (dark)
    static let albaText = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.90, blue: 0.88, alpha: 1)
            : UIColor(red: 0.25, green: 0.22, blue: 0.20, alpha: 1)
    })

    // Surface: white glass (light) → dark glass (dark)
    static let albaSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.15, alpha: 0.75)
            : UIColor(white: 1.0, alpha: 0.75)
    })

    static let albaGlass = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.18, alpha: 0.5)
            : UIColor(white: 1.0, alpha: 0.5)
    })

    static let botBubble = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.14, blue: 0.13, alpha: 1)
            : UIColor(white: 1.0, alpha: 1)
    })

    static let disabledButton = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.3, alpha: 0.5)
            : UIColor(white: 0.5, alpha: 0.35)
    })

    static let optionBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.16, alpha: 0.8)
            : UIColor(white: 1.0, alpha: 0.8)
    })

    // Result colors — slightly adjusted for dark mode legibility
    static let resultHigh = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.45, green: 0.75, blue: 0.50, alpha: 1)
            : UIColor(red: 0.88, green: 0.72, blue: 0.65, alpha: 1)
    })

    static let resultNeutral = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.58, blue: 0.48, alpha: 1)
            : UIColor(red: 0.85, green: 0.55, blue: 0.45, alpha: 1)
    })

    static let resultLow = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.90, green: 0.42, blue: 0.38, alpha: 1)
            : UIColor(red: 0.75, green: 0.45, blue: 0.35, alpha: 1)
    })
}

// MARK: - Adaptive Gradient Presets
extension LinearGradient {
    static var albaWarm: LinearGradient {
        LinearGradient(
            colors: [
                Color(UIColor { trait in
                    trait.userInterfaceStyle == .dark
                        ? UIColor(red: 0.12, green: 0.10, blue: 0.09, alpha: 1)
                        : UIColor(red: 0.98, green: 0.94, blue: 0.90, alpha: 1)
                }),
                Color(UIColor { trait in
                    trait.userInterfaceStyle == .dark
                        ? UIColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 1)
                        : UIColor(red: 0.95, green: 0.90, blue: 0.87, alpha: 1)
                }),
                Color(UIColor { trait in
                    trait.userInterfaceStyle == .dark
                        ? UIColor(red: 0.11, green: 0.10, blue: 0.09, alpha: 1)
                        : UIColor(red: 0.97, green: 0.95, blue: 0.93, alpha: 1)
                })
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var albaAccentGradient: LinearGradient {
        LinearGradient(
            colors: [Color.albaAccent, Color.albaAccent.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var albaSunrise: LinearGradient {
        LinearGradient(
            colors: [
                Color(UIColor { trait in
                    trait.userInterfaceStyle == .dark
                        ? UIColor(red: 0.35, green: 0.18, blue: 0.12, alpha: 1)
                        : UIColor(red: 1.0, green: 0.85, blue: 0.75, alpha: 1)
                }),
                Color(UIColor { trait in
                    trait.userInterfaceStyle == .dark
                        ? UIColor(red: 0.30, green: 0.15, blue: 0.10, alpha: 1)
                        : UIColor(red: 0.95, green: 0.75, blue: 0.65, alpha: 1)
                }),
                Color(UIColor { trait in
                    trait.userInterfaceStyle == .dark
                        ? UIColor(red: 0.28, green: 0.14, blue: 0.10, alpha: 1)
                        : UIColor(red: 0.90, green: 0.65, blue: 0.55, alpha: 1)
                })
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Typography
struct AlbaFont {
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func title() -> Font {
        .system(size: 32, weight: .heavy, design: .serif)
    }

    static func headline() -> Font {
        .system(size: 20, weight: .bold, design: .rounded)
    }

    static func body() -> Font {
        .system(size: 16, weight: .regular, design: .rounded)
    }

    static func caption() -> Font {
        .system(size: 13, weight: .medium, design: .rounded)
    }
}
