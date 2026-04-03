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
            return "Lo que describes indica una debilidad en el **compromiso mutuo** de la amistad. Esto sucede cuando el esfuerzo no es recíproco. **Ejercicio recomendado:** ten una conversación directa sobre expectativas mutuas."
        case (.profesional, .en):
            return "What you're describing indicates a weakness in the **mutual engagement** of the friendship. This happens when effort isn't reciprocal. **Recommended exercise:** have a direct conversation about mutual expectations."
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
        case .corta: return 256
        case .media: return 1024
        case .larga: return 2048
        }
    }

    func promptFragment(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.corta, .es):
            return "EXTENSIÓN: MUY corta. Responde en 1-2 oraciones MÁXIMO. Como un mensaje de texto entre amigas. Nada de párrafos."
        case (.corta, .en):
            return "LENGTH: VERY short. Respond in 1-2 sentences MAX. Like a text message between friends. No paragraphs."
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

    /// Dynamic example that combines style + length + emoji for the preview
    func dynamicExample(for lang: AppLanguage) -> String {
        // Base examples per style x length
        let example: String
        switch (style, length, lang) {
        // DIRECTA
        case (.directa, .corta, .es):
            example = "Tu amigo no te da el mismo esfuerzo. **Habla con él esta semana.**"
        case (.directa, .corta, .en):
            example = "Your friend isn't putting in the effort. **Talk to them this week.**"
        case (.directa, .media, .es):
            example = "Tu amigo no te está dando el mismo esfuerzo. **Habla con él esta semana.** Dile exactamente qué necesitas. Si no cambia, protege tu energía."
        case (.directa, .media, .en):
            example = "Your friend isn't putting in the same effort. **Talk to them this week.** Tell them exactly what you need. If nothing changes, protect your energy."
        case (.directa, .larga, .es):
            example = "Tu amigo no te está dando el mismo esfuerzo, y eso duele. **Habla con él esta semana.** Dile exactamente qué necesitas y cómo te hace sentir la situación. Si no cambia después de esa conversación, protege tu energía. No es egoísmo, es autocuidado. **Ejercicio:** Escríbele un mensaje honesto esta noche."
        case (.directa, .larga, .en):
            example = "Your friend isn't putting in the same effort, and that hurts. **Talk to them this week.** Tell them exactly what you need and how this situation makes you feel. If nothing changes after that talk, protect your energy. It's not selfish, it's self-care. **Exercise:** Write them an honest message tonight."

        // AMIGABLE
        case (.amigable, .corta, .es):
            example = "Ay, entiendo cómo te sientes. A veces las amistades pasan por baches y está bien."
        case (.amigable, .corta, .en):
            example = "Oh, I totally get how you feel. Sometimes friendships go through rough patches."
        case (.amigable, .media, .es):
            example = "Ay, entiendo perfectamente lo que sientes. A veces las amistades pasan por baches y está bien sentirse así. **Te propongo algo:** esta semana intenta decirle cómo te sientes, con calma y sin presión."
        case (.amigable, .media, .en):
            example = "Oh, I totally get how you feel! Sometimes friendships go through rough patches and it's okay to feel that way. **Here's an idea:** this week, try telling them how you feel, calmly and without pressure."
        case (.amigable, .larga, .es):
            example = "Ay, entiendo perfectamente lo que sientes. A veces las amistades pasan por baches y está bien sentirse así. No significa que la amistad no valga la pena. **Te propongo algo:** esta semana intenta decirle cómo te sientes, con calma y sin presión. Elige un momento tranquilo, sin distracciones. **Otro ejercicio:** escribe en tu diario qué es lo que más valoras de esta amistad."
        case (.amigable, .larga, .en):
            example = "Oh, I totally get how you feel! Sometimes friendships go through rough patches and it's okay to feel that way. It doesn't mean the friendship isn't worth it. **Here's an idea:** this week, try telling them how you feel, calmly and without pressure. Choose a quiet moment with no distractions. **Another exercise:** write in your diary what you value most about this friendship."

        // PROFESIONAL
        case (.profesional, .corta, .es):
            example = "Esto indica una debilidad en el **compromiso mutuo**. Recomendación: conversación directa sobre expectativas."
        case (.profesional, .corta, .en):
            example = "This indicates a weakness in **mutual engagement**. Recommendation: direct conversation about expectations."
        case (.profesional, .media, .es):
            example = "Lo que describes indica una debilidad en el **compromiso mutuo** de la amistad. Esto sucede cuando el esfuerzo no es recíproco. **Ejercicio recomendado:** ten una conversación directa sobre expectativas mutuas."
        case (.profesional, .media, .en):
            example = "What you're describing indicates a weakness in the **mutual engagement** of the friendship. This happens when effort isn't reciprocal. **Recommended exercise:** have a direct conversation about mutual expectations."
        case (.profesional, .larga, .es):
            example = "Lo que describes indica una debilidad en el **compromiso mutuo** de la amistad. Esto sucede cuando el esfuerzo no es recíproco y una de las partes invierte más energía emocional. **Ejercicio recomendado:** ten una conversación directa sobre expectativas mutuas. **Segundo paso:** establezcan juntos un acuerdo de cómo quieren mantener la relación. **Indicador de progreso:** si en 2 semanas notas un cambio positivo, la amistad tiene potencial."
        case (.profesional, .larga, .en):
            example = "What you're describing indicates a weakness in the **mutual engagement** of the friendship. This happens when effort isn't reciprocal and one party invests more emotional energy. **Recommended exercise:** have a direct conversation about mutual expectations. **Second step:** together, establish an agreement about how you want to maintain the relationship. **Progress indicator:** if you notice positive change in 2 weeks, the friendship has potential."

        // EMPATICA
        case (.empatica, .corta, .es):
            example = "Es completamente válido sentirte así. Tus sentimientos importan."
        case (.empatica, .corta, .en):
            example = "It's completely valid to feel that way. Your feelings matter."
        case (.empatica, .media, .es):
            example = "Es completamente válido sentirte así. Cuando alguien que nos importa no responde como esperamos, **duele**. Quiero que sepas que tus sentimientos importan. Cuando estés lista, podemos explorar juntas cómo mejorar esto."
        case (.empatica, .media, .en):
            example = "It's completely valid to feel that way. When someone we care about doesn't respond as we hope, **it hurts**. I want you to know your feelings matter. When you're ready, we can explore together how to improve this."
        case (.empatica, .larga, .es):
            example = "Es completamente válido sentirte así. Cuando alguien que nos importa no responde como esperamos, **duele**. Y ese dolor es real, no lo minimices. Quiero que sepas que tus sentimientos importan. No tienes que resolverlo todo hoy. **Cuando estés lista**, podemos explorar juntas cómo mejorar esto. **Por ahora:** date permiso de sentir sin juzgarte. Escribe lo que sientes, eso ayuda a procesarlo."
        case (.empatica, .larga, .en):
            example = "It's completely valid to feel that way. When someone we care about doesn't respond as we hope, **it hurts**. And that pain is real—don't minimize it. I want you to know your feelings matter. You don't have to figure it all out today. **When you're ready**, we can explore together how to improve this. **For now:** give yourself permission to feel without judgment. Write down what you're feeling—it helps process it."
        }

        // Apply emoji toggle
        if useEmojis {
            return addEmojis(to: example, lang: lang)
        }
        return example
    }

    private func addEmojis(to text: String, lang: AppLanguage) -> String {
        // Add contextual emojis to the example
        var result = text
        if lang == .es {
            if result.contains("duele") || result.contains("dolor") { result = result.replacingOccurrences(of: "duele", with: "duele 💔") }
            if result.contains("válido") { result = result.replacingOccurrences(of: "válido", with: "válido 🫂") }
            if result.contains("Ejercicio") { result = result.replacingOccurrences(of: "Ejercicio", with: "Ejercicio ✨") }
            if !result.contains("💔") && !result.contains("🫂") && !result.contains("✨") {
                result += " 💛✨"
            }
        } else {
            if result.contains("hurts") { result = result.replacingOccurrences(of: "hurts", with: "hurts 💔") }
            if result.contains("valid") { result = result.replacingOccurrences(of: "valid", with: "valid 🫂") }
            if result.contains("Exercise") { result = result.replacingOccurrences(of: "Exercise", with: "Exercise ✨") }
            if !result.contains("💔") && !result.contains("🫂") && !result.contains("✨") {
                result += " 💛✨"
            }
        }
        return result
    }

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
