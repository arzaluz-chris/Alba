import SwiftUI
import UIKit

struct ArticleDetailView: View {
    let article: Article
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    private var lang: AppLanguage { languageManager.language }

    var body: some View {
        ZStack {
            Color.albaBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top Bar
                HStack {
                    Button {
                        HapticManager.shared.lightImpact()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.albaText.opacity(0.5))
                    }

                    Spacer()

                    Text(L10n.t(.albaBlocksTitle, lang))
                        .font(AlbaFont.serif(18, weight: .bold))
                        .foregroundColor(.albaText)

                    Spacer()

                    // Invisible spacer for centering
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // MARK: - Cover Image
                        ZStack(alignment: .bottomLeading) {
                            if UIImage(named: article.coverImageName) != nil {
                                Image(article.coverImageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 220)
                                    .clipped()
                            } else {
                                LinearGradient(
                                    colors: [
                                        Color.albaAccent.opacity(0.3),
                                        Color.albaAccent.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .frame(height: 220)
                            }

                            // Gradient overlay
                            LinearGradient(
                                colors: [.clear, Color.albaBackground.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 100)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                        }
                        .frame(height: 220)

                        // MARK: - Title
                        Text(article.title(for: lang))
                            .font(AlbaFont.serif(28, weight: .bold))
                            .foregroundColor(.albaText)
                            .padding(.horizontal, 24)
                            .padding(.top, 4)
                            .padding(.bottom, 20)

                        // MARK: - Body Content
                        articleBodyView
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                    }
                }
            }
        }
    }

    // MARK: - Article Body Parser
    @ViewBuilder
    private var articleBodyView: some View {
        let fullText = AlbaBlocksData.loadArticleText(from: article.resourceBaseName, lang: lang)
        let paragraphs = fullText.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
                let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)

                if isHeader(trimmed) {
                    Text(trimmed)
                        .font(AlbaFont.serif(20, weight: .bold))
                        .foregroundColor(.albaText)
                        .padding(.top, index > 0 ? 8 : 0)
                } else {
                    Text(trimmed)
                        .font(AlbaFont.rounded(15))
                        .foregroundColor(.albaText.opacity(0.85))
                        .lineSpacing(6)
                }

                // Decorative dot separator every 3 body paragraphs
                if (index + 1) % 3 == 0 && index < paragraphs.count - 1 {
                    HStack {
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { _ in
                                Circle()
                                    .fill(Color.albaAccent.opacity(0.3))
                                    .frame(width: 5, height: 5)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func isHeader(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Short lines that look like headers
        if trimmed.count < 80 {
            if trimmed.hasSuffix("?") || trimmed.hasSuffix(":") { return true }
            if trimmed.hasPrefix("##") || trimmed.hasPrefix("**") { return true }
            // Lines that are all uppercase or very short standalone
            if trimmed.count < 50 && !trimmed.contains(".") { return true }
        }
        return false
    }
}
