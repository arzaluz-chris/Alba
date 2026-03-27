import SwiftUI

/// Reusable Alba avatar showing the app icon.
/// Used in chat bubbles, onboarding, and tutorial cards.
struct AlbaAvatar: View {
    let size: CGFloat

    var body: some View {
        Image("ALBA_LOGO")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .shadow(color: Color.albaAccent.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

/// Square-rounded variant for tutorial cards.
struct AlbaAvatarSquare: View {
    let size: CGFloat

    var body: some View {
        Image("ALBA_LOGO")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .shadow(color: Color.albaAccent.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}
