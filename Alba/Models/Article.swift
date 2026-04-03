import Foundation

struct Article: Identifiable, Equatable {
    let id = UUID()
    let titleEs: String
    let titleEn: String
    let teaserEs: String
    let teaserEn: String
    let coverImageName: String
    let resourceBaseName: String

    func title(for lang: AppLanguage) -> String { lang == .es ? titleEs : titleEn }
    func teaser(for lang: AppLanguage) -> String { lang == .es ? teaserEs : teaserEn }
}

struct AlbaBlocksData {
    static let articles: [Article] = [
        Article(
            titleEs: "Limites: ¿Que son y que no son?",
            titleEn: "Boundaries: What They Are (and Aren't)",
            teaserEs: "Por que los limites sanos protegen vinculos y nos cuidan a todos.",
            teaserEn: "Why healthy boundaries protect relationships and take care of us.",
            coverImageName: "limitsCover",
            resourceBaseName: "Articulo_Limites"
        ),
        Article(
            titleEs: "Estudio revelador",
            titleEn: "Eye-opening Study",
            teaserEs: "Un analisis profundo que revela datos que sorprenden.",
            teaserEn: "A deep analysis that reveals surprising insights.",
            coverImageName: "estudioCover",
            resourceBaseName: "Articulo_EstudioRevelador"
        ),
        Article(
            titleEs: "Psicología positiva y las amistades",
            titleEn: "Positive Psychology & Friendships",
            teaserEs: "Cómo la ciencia del bienestar nos ayuda a construir amistades más sanas.",
            teaserEn: "How the science of well-being helps us build healthier friendships.",
            coverImageName: "permaCover",
            resourceBaseName: "Articulo_PERMA"
        )
    ]

    static func localizedResourceName(base: String, lang: AppLanguage) -> String {
        base + (lang == .es ? "_es" : "_en")
    }

    static func loadArticleText(from baseResource: String, lang: AppLanguage) -> String {
        let localized = localizedResourceName(base: baseResource, lang: lang)
        if let url = Bundle.main.url(forResource: localized, withExtension: "txt"),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            return text
        }
        return lang == .es
            ? "No se pudo cargar el articulo."
            : "Couldn't load the article."
    }
}
