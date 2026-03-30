import SwiftUI

struct AIPersonalizationView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var userViewModel: UserViewModel

    private var lang: AppLanguage { languageManager.language }
    private var personalization: AIPersonalization { userViewModel.aiPersonalization }

    var body: some View {
        ZStack {
            Color.albaBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 8)

                    // MARK: - Communication Style
                    styleSection

                    // MARK: - Response Length
                    lengthSection

                    // MARK: - Emoji Toggle
                    emojiSection

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(L10n.t(.aiPersonalization, lang))
                    .font(AlbaFont.serif(20, weight: .bold))
                    .foregroundColor(.albaText)
            }
        }
    }

    // MARK: - Style Section

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.t(.communicationStyle, lang))
                .font(AlbaFont.serif(18, weight: .bold))
                .foregroundColor(.albaText)
                .padding(.horizontal, 24)

            // Style cards - 2x2 grid
            let columns = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(CommunicationStyle.allCases) { style in
                    StyleCard(
                        style: style,
                        isSelected: personalization.style == style,
                        lang: lang
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            userViewModel.aiPersonalization.style = style
                        }
                        HapticManager.shared.selection()
                    }
                }
            }
            .padding(.horizontal, 24)

            // Example preview
            ExampleBubble(
                text: personalization.style.exampleResponse(for: lang),
                title: L10n.t(.responseExample, lang)
            )
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Length Section

    private var lengthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.t(.responseLength, lang))
                .font(AlbaFont.serif(18, weight: .bold))
                .foregroundColor(.albaText)
                .padding(.horizontal, 24)

            // Segmented picker
            HStack(spacing: 0) {
                ForEach(ResponseLength.allCases) { length in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            userViewModel.aiPersonalization.length = length
                        }
                        HapticManager.shared.selection()
                    } label: {
                        Text(length.displayName(for: lang))
                            .font(AlbaFont.rounded(14, weight: personalization.length == length ? .bold : .medium))
                            .foregroundColor(personalization.length == length ? .white : .albaText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                personalization.length == length
                                    ? AnyShapeStyle(LinearGradient.albaAccentGradient)
                                    : AnyShapeStyle(Color.clear)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .padding(4)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            )
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Emoji Section

    private var emojiSection: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.albaAccent)
                    .frame(width: 32)

                Text(L10n.t(.useEmojis, lang))
                    .font(AlbaFont.rounded(16, weight: .medium))
                    .foregroundColor(.albaText)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { personalization.useEmojis },
                set: { newValue in
                    userViewModel.aiPersonalization.useEmojis = newValue
                    HapticManager.shared.selection()
                }
            ))
            .tint(.albaAccent)
            .labelsHidden()
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 24)
    }
}

// MARK: - Style Card

private struct StyleCard: View {
    let style: CommunicationStyle
    let isSelected: Bool
    let lang: AppLanguage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.albaAccent.opacity(0.15) : Color.white.opacity(0.5))
                        .frame(width: 50, height: 50)

                    Image(systemName: style.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? .albaAccent : .albaText.opacity(0.6))
                }

                Text(style.displayName(for: lang))
                    .font(AlbaFont.rounded(14, weight: .bold))
                    .foregroundColor(isSelected ? .albaAccent : .albaText)

                Text(style.description(for: lang))
                    .font(AlbaFont.rounded(11))
                    .foregroundColor(.albaText.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 8)
            .background(
                isSelected
                    ? AnyShapeStyle(.ultraThinMaterial)
                    : AnyShapeStyle(Color.white.opacity(0.5))
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.albaAccent.opacity(0.5) : Color.gray.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(
                color: isSelected ? Color.albaAccent.opacity(0.2) : Color.black.opacity(0.05),
                radius: isSelected ? 12 : 4,
                x: 0,
                y: isSelected ? 6 : 2
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Example Bubble

private struct ExampleBubble: View {
    let text: String
    let title: String

    @State private var animationId = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AlbaFont.rounded(12, weight: .medium))
                .foregroundColor(.albaAccent)
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(alignment: .top, spacing: 10) {
                AlbaAvatarSquare(size: 28)

                Text(markdownToAttributed(text))
                    .font(AlbaFont.rounded(14))
                    .lineSpacing(4)
                    .foregroundColor(.albaText)
            }
            .id(animationId)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .onChange(of: text) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animationId = UUID()
            }
        }
    }

    private func markdownToAttributed(_ text: String) -> AttributedString {
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributed
        }
        return AttributedString(text)
    }
}
