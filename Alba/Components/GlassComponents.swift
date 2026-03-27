import SwiftUI

// MARK: - Glass Action Button (Premium)
struct GlassActionButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void

    enum ButtonStyle {
        case primary, secondary, subtle
    }

    init(_ title: String, icon: String? = nil, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.mediumImpact()
            action()
        }) {
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(AlbaFont.rounded(16, weight: .bold))
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(borderColor, lineWidth: style == .secondary ? 1.5 : 0)
            )
            .shadow(color: shadowColor, radius: style == .primary ? 16 : 8, x: 0, y: style == .primary ? 8 : 4)
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            LinearGradient.albaAccentGradient
        case .secondary:
            Color.white.opacity(0.85)
        case .subtle:
            Color.clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .albaAccent
        case .subtle: return .gray
        }
    }

    private var borderColor: Color {
        switch style {
        case .secondary: return Color.albaAccent.opacity(0.5)
        default: return .clear
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary: return Color.albaAccent.opacity(0.3)
        case .secondary: return Color.black.opacity(0.05)
        case .subtle: return .clear
        }
    }
}

// MARK: - Glass Card Container
struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .glassCard()
    }
}

// MARK: - Gender Selection Button (Premium)
struct GenderButton: View {
    let label: String
    let icon: String
    let gender: Gender
    @Binding var selectedGender: Gender?

    private var isSelected: Bool { selectedGender == gender }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedGender = gender
            }
            HapticManager.shared.mediumImpact()
        }) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.albaAccent.opacity(0.15) : Color.white.opacity(0.5))
                        .frame(width: 70, height: 70)

                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(isSelected ? .albaAccent : .albaText.opacity(0.6))
                }

                Text(label)
                    .font(AlbaFont.rounded(15, weight: .semibold))
                    .foregroundColor(isSelected ? .albaAccent : .albaText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                isSelected
                    ? AnyShapeStyle(.ultraThinMaterial)
                    : AnyShapeStyle(Color.white.opacity(0.5))
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? Color.albaAccent.opacity(0.5) : Color.gray.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(color: isSelected ? Color.albaAccent.opacity(0.2) : Color.black.opacity(0.05), radius: isSelected ? 12 : 4, x: 0, y: isSelected ? 6 : 2)
        }
    }
}

// MARK: - Option Button (Test)
struct OptionButton: View {
    let option: Option
    let isSelected: Bool
    var wasPreviousAnswer: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                action()
            }
        }) {
            HStack(alignment: .center, spacing: 15) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : .albaAccent)
                    .frame(width: 28)

                Text(option.labelFallback)
                    .font(AlbaFont.rounded(16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .albaText)

                Spacer()

                // Previous answer indicator
                if wasPreviousAnswer && !isSelected {
                    Text("anterior")
                        .font(AlbaFont.rounded(11, weight: .medium))
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(18)
            .background(
                isSelected
                    ? AnyShapeStyle(LinearGradient.albaAccentGradient)
                    : wasPreviousAnswer
                        ? AnyShapeStyle(Color.albaAccent.opacity(0.06))
                        : AnyShapeStyle(Color.white.opacity(0.7))
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected ? Color.clear :
                            wasPreviousAnswer ? Color.albaAccent.opacity(0.15) : Color.gray.opacity(0.12),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? Color.albaAccent.opacity(0.35) : Color.black.opacity(0.06),
                radius: isSelected ? 12 : 4,
                x: 0,
                y: isSelected ? 6 : 2
            )
        }
    }
}

// MARK: - Chat Bubble (Premium)
struct ChatBubble: View {
    let message: Message
    var onTakeTest: ((String) -> Void)?

    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
            // Main message bubble
            HStack(alignment: .bottom, spacing: 8) {
                if message.isUser { Spacer(minLength: 50) }

                if !message.isUser {
                    AlbaAvatar(size: 32)
                }

                Text(markdownToAttributed(message.text))
                    .font(AlbaFont.rounded(15))
                    .lineSpacing(5)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isUser
                            ? AnyShapeStyle(LinearGradient.albaAccentGradient)
                            : AnyShapeStyle(.ultraThinMaterial)
                    )
                    .foregroundColor(message.isUser ? .white : .albaText)
                    .clipShape(
                        RoundedCorner(
                            radius: 20,
                            corners: message.isUser
                                ? [.topLeft, .topRight, .bottomLeft]
                                : [.topLeft, .topRight, .bottomRight]
                        )
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75,
                           alignment: message.isUser ? .trailing : .leading)

                if !message.isUser { Spacer(minLength: 50) }
            }

            // Embedded "Take Test" card if action is present
            if case .takeTest(let friendName) = message.action {
                TakeTestCard(friendName: friendName) {
                    onTakeTest?(friendName)
                }
                .padding(.leading, 40) // Align with bubble (after avatar)
            }
        }
    }

    private func markdownToAttributed(_ text: String) -> AttributedString {
        var cleaned = text
        for marker in ["(P)", "(E)", "(R)", "(M)", "(A)"] {
            cleaned = cleaned.replacingOccurrences(of: marker, with: "")
        }
        if let attributed = try? AttributedString(markdown: cleaned, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributed
        }
        return AttributedString(cleaned)
    }
}

// MARK: - Embedded "Take Test" Card
struct TakeTestCard: View {
    let friendName: String
    let onTap: () -> Void

    @State private var appeared = false

    var body: some View {
        Button(action: {
            HapticManager.shared.mediumImpact()
            onTap()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.albaAccentGradient)
                        .frame(width: 42, height: 42)
                    Image(systemName: "checklist")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Alba Test")
                        .font(AlbaFont.rounded(15, weight: .bold))
                        .foregroundColor(.albaText)
                    Text(friendName)
                        .font(AlbaFont.rounded(13))
                        .foregroundColor(.albaAccent)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.albaAccent)
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.albaAccent.opacity(0.3), lineWidth: 1.2)
            )
            .shadow(color: Color.albaAccent.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 280)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}
