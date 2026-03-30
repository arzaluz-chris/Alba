import Foundation

// MARK: - Communication Style

enum CommunicationStyle: String, CaseIterable, Codable, Identifiable {
    case directa, amigable, profesional, empatica

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .directa: return "bolt"
        case .amigable: return "face.smiling"
        case .profesional: return "briefcase"
        case .empatica: return "heart"
        }
    }

    func displayName(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.directa, .es): return "Directa"
        case (.directa, .en): return "Direct"
        case (.amigable, .es): return "Amigable"
        case (.amigable, .en): return "Friendly"
        case (.profesional, .es): return "Profesional"
        case (.profesional, .en): return "Professional"
        case (.empatica, .es): return "Empática"
        case (.empatica, .en): return "Empathetic"
        }
    }

    func description(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.directa, .es): return "Va al punto, sin rodeos"
        case (.directa, .en): return "Straight to the point"
        case (.amigable, .es): return "Cálida y casual"
        case (.amigable, .en): return "Warm and casual"
        case (.profesional, .es): return "Estructurada y analítica"
        case (.profesional, .en): return "Structured and analytical"
        case (.empatica, .es): return "Suave y comprensiva"
        case (.empatica, .en): return "Gentle and understanding"
        }
    }

    func promptFragment(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.directa, .es):
            return "ESTILO DE COMUNICACIÓN: Directa. Sé concisa y ve al punto. Evita rodeos, frases de relleno y explicaciones largas. Prioriza la acción sobre la teoría."
        case (.directa, .en):
            return "COMMUNICATION STYLE: Direct. Be concise and get to the point. Avoid filler phrases and long explanations. Prioritize action over theory."
        case (.amigable, .es):
            return "ESTILO DE COMUNICACIÓN: Amigable. Sé cálida y casual. Usa un tono de confianza como una amiga cercana. Incluye ánimos y palabras de apoyo."
        case (.amigable, .en):
            return "COMMUNICATION STYLE: Friendly. Be warm and casual. Use a tone of trust like a close friend. Include encouragement and supportive words."
        case (.profesional, .es):
            return "ESTILO DE COMUNICACIÓN: Profesional. Sé estructurada y analítica. Organiza tus ideas con claridad. Usa un tono medido y objetivo, como una consejera experta."
        case (.profesional, .en):
            return "COMMUNICATION STYLE: Professional. Be structured and analytical. Organize your ideas clearly. Use a measured, objective tone like an expert counselor."
        case (.empatica, .es):
            return "ESTILO DE COMUNICACIÓN: Empática. Prioriza la validación emocional. Usa lenguaje suave y comprensivo. Reconoce los sentimientos antes de dar cualquier consejo."
        case (.empatica, .en):
            return "COMMUNICATION STYLE: Empathetic. Prioritize emotional validation. Use gentle, understanding language. Acknowledge feelings before giving any advice."
        }
    }

    func exampleResponse(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.directa, .es):
            return "Tu amigo no te está dando el mismo esfuerzo. **Habla con él esta semana.** Dile exactamente qué necesitas. Si no cambia, protege tu energía."
        case (.directa, .en):
            return "Your friend isn't putting in the same effort. **Talk to them this week.** Tell them exactly what you need. If nothing changes, protect your energy."
        case (.amigable, .es):
            return "Ay, entiendo perfectamente lo que sientes. A veces las amistades pasan por baches y está bien sentirse así. **Te propongo algo:** esta semana intenta decirle cómo te sientes, con calma y sin presión."
        case (.amigable, .en):
            return "Oh, I totally get how you feel! Sometimes friendships go through rough patches and it's okay to feel that way. **Here's an idea:** this week, try telling them how you feel, calmly and without pressure."
        case (.profesional, .es):
            return "Lo que describes indica una debilidad en la dimensión de **Compromiso (Engagement)** del modelo PERMA. Esto sucede cuando el esfuerzo no es recíproco. **Ejercicio recomendado:** ten una conversación directa sobre expectativas mutuas."
        case (.profesional, .en):
            return "What you're describing indicates a weakness in the **Engagement** dimension of the PERMA model. This happens when effort isn't reciprocal. **Recommended exercise:** have a direct conversation about mutual expectations."
        case (.empatica, .es):
            return "Es completamente válido sentirte así. Cuando alguien que nos importa no responde como esperamos, **duele**. Quiero que sepas que tus sentimientos importan. Cuando estés lista, podemos explorar juntas cómo mejorar esto."
        case (.empatica, .en):
            return "It's completely valid to feel that way. When someone we care about doesn't respond as we hope, **it hurts**. I want you to know your feelings matter. When you're ready, we can explore together how to improve this."
        }
    }
}

// MARK: - Response Length

enum ResponseLength: String, CaseIterable, Codable, Identifiable {
    case corta, media, larga

    var id: String { rawValue }

    func displayName(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.corta, .es): return "Corta"
        case (.corta, .en): return "Short"
        case (.media, .es): return "Media"
        case (.media, .en): return "Medium"
        case (.larga, .es): return "Larga"
        case (.larga, .en): return "Long"
        }
    }

    var maxOutputTokens: Int {
        switch self {
        case .corta: return 512
        case .media: return 1024
        case .larga: return 2048
        }
    }

    func promptFragment(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.corta, .es):
            return "EXTENSIÓN: Corta. Responde en 1-2 oraciones máximo con una sola acción concreta. Sé breve."
        case (.corta, .en):
            return "LENGTH: Short. Respond in 1-2 sentences max with a single concrete action. Be brief."
        case (.media, .es):
            return "EXTENSIÓN: Media. Responde en 2-3 párrafos cortos. Equilibra análisis y acción."
        case (.media, .en):
            return "LENGTH: Medium. Respond in 2-3 short paragraphs. Balance analysis and action."
        case (.larga, .es):
            return "EXTENSIÓN: Larga. Da explicaciones detalladas, múltiples ejercicios y un análisis profundo. Sé exhaustiva."
        case (.larga, .en):
            return "LENGTH: Long. Give detailed explanations, multiple exercises, and deep analysis. Be thorough."
        }
    }
}

// MARK: - AI Personalization

struct AIPersonalization: Codable, Equatable {
    var style: CommunicationStyle = .amigable
    var length: ResponseLength = .media
    var useEmojis: Bool = true

    func personalizationPrompt(for lang: AppLanguage) -> String {
        var fragments: [String] = []
        fragments.append(style.promptFragment(for: lang))
        fragments.append(length.promptFragment(for: lang))
        if useEmojis {
            fragments.append(lang == .es
                ? "EMOJIS: DEBES incluir emojis en cada respuesta. Usa 2-4 emojis por mensaje para hacerlo expresivo. Ejemplos: 💛 para apoyo, 🤔 para reflexión, ✨ para ánimo, 🫂 para empatía. Es OBLIGATORIO."
                : "EMOJIS: You MUST include emojis in every response. Use 2-4 emojis per message to make it expressive. Examples: 💛 for support, 🤔 for reflection, ✨ for encouragement, 🫂 for empathy. This is MANDATORY.")
        } else {
            fragments.append(lang == .es
                ? "EMOJIS: NO uses emojis en tus respuestas. Ninguno. Cero emojis."
                : "EMOJIS: Do NOT use emojis in your responses. None. Zero emojis.")
        }
        return "\n\n" + fragments.joined(separator: "\n")
    }
}
