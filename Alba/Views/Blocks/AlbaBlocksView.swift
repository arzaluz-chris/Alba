import SwiftUI
import UIKit

struct AlbaBlocksView: View {
    @Binding var currentView: AppState
    @EnvironmentObject var languageManager: LanguageManager

    @State private var selectedArticle: Article?

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
                        currentView = .welcome
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.albaText)
                    }

                    Spacer()

                    Text(L10n.t(.albaBlocksTitle, lang))
                        .font(AlbaFont.serif(20, weight: .bold))
                        .foregroundColor(.albaText)

                    Spacer()

                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)

                // MARK: - Articles Feed
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(AlbaBlocksData.articles) { article in
                            ArticleCardView(article: article, lang: lang) {
                                selectedArticle = article
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
        }
        .fullScreenCover(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
                .environmentObject(languageManager)
        }
    }
}

// MARK: - Article Card
struct ArticleCardView: View {
    let article: Article
    let lang: AppLanguage
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Cover Image or Gradient Placeholder
                ZStack {
                    if UIImage(named: article.coverImageName) != nil {
                        Image(article.coverImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
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
                        .frame(height: 160)
                        .overlay(
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(.albaAccent.opacity(0.4))
                        )
                    }
                }
                .clipShape(
                    RoundedCorner(radius: 20, corners: [.topLeft, .topRight])
                )

                // Text Content
                VStack(alignment: .leading, spacing: 10) {
                    Text(article.title(for: lang))
                        .font(AlbaFont.serif(18, weight: .bold))
                        .foregroundColor(.albaText)
                        .lineLimit(2)

                    Text(article.teaser(for: lang))
                        .font(AlbaFont.rounded(14))
                        .foregroundColor(.albaText.opacity(0.65))
                        .lineLimit(3)
                        .lineSpacing(3)

                    HStack(spacing: 6) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 12))
                        Text(L10n.t(.read, lang))
                            .font(AlbaFont.rounded(13, weight: .semibold))
                    }
                    .foregroundColor(.albaAccent)
                    .padding(.top, 4)
                }
                .padding(18)
            }
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}
