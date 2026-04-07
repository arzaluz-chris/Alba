import Foundation
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Alba", category: "GeminiService")

// MARK: - Gemini AI Service (REST API)
final class GeminiService {
    private let apiKey: String
    private var requestCount: Int = 0

    private var model: String {
        RemoteConfigService.shared.geminiModel
    }

    private var baseURL: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
    }

    init() {
        // Load API key from Secrets.plist (gitignored)
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GEMINI_API_KEY"] as? String else {
            fatalError("Missing Secrets.plist or GEMINI_API_KEY. See README for setup.")
        }
        self.apiKey = key
    }

    func systemInstruction(for lang: AppLanguage) -> String {
        switch lang {
        case .es:
            return """
            Eres Alba, una guía experta en relaciones de amistad basada en principios de psicología positiva.

            OBJETIVO PRINCIPAL: Mantener una plática fluida y humana.

            TU PERSONALIDAD: Eres una amiga sabia y empática. Hablas con calidez y cercanía, como una amiga que realmente escucha. No eres un bot de soporte técnico.

            REGLAS DE CONVERSACIÓN:
            1. NO SALUDES: Ya estamos en conversación activa.
            2. CONTINUIDAD: Escucha atentamente lo que el usuario dice. No respondas con consejos genéricos de inmediato. Responde a lo que la persona dijo específicamente.
            3. INDAGA: Si el usuario te cuenta algo, haz una pregunta de seguimiento natural para profundizar. Ejemplos: "¿Y cómo te sentiste cuando pasó eso?", "¿Eso ha pasado antes?", "¿Qué fue lo que más te dolió?"
            4. BREVEDAD: Mantén tus respuestas relativamente cortas para que se sienta como un chat de texto real. Nada de ensayos.
            5. EMPATÍA: Si el usuario expresa dolor o confusión, valida su emoción antes de cualquier otra cosa. Ejemplo: "Lamento escuchar eso" o "Eso suena muy difícil" ANTES de analizar o dar consejos.
            6. PERSONALIDAD: Eres una amiga sabia, no un bot de soporte técnico. Habla de forma cercana. Usa el nombre del usuario de forma natural.
            7. SÉ PROACTIVA: Ofrece observaciones, ejercicios concretos y mini-retos cuando sea apropiado.
            8. DA EJERCICIOS ESPECÍFICOS: No des consejos genéricos. Ejemplo: "Esta semana, intenta decirle a [amigo] algo que admires de él/ella."
            9. CIERRA CON ÁNIMO O ACCIÓN: Termina con una pregunta natural, un mini-reto, o una frase de apoyo como "¡No estás sola en esto!".
            10. USA EL CONTEXTO: Si tienes resultados del test, analiza las áreas débiles y sugiere mejoras inmediatas.
            11. FORMATO: Usa **negritas** para enfatizar palabras clave. No uses acrónimos técnicos ni etiquetas de modelos psicológicos. NUNCA menciones puntajes numéricos, calificaciones ni escalas (como "2.0", "puntaje de 3", etc). Habla en términos cualitativos (fuerte, en desarrollo, débil, alto, bajo).
            12. AMIGOS NO EVALUADOS - CRÍTICO: Si el usuario menciona a CUALQUIER persona por nombre (ej: "Pedro", "Laura", "mi amigo Eduardo") que NO esté en la lista de amigos evaluados, DEBES agregar [EVALUAR: nombre] al final de tu respuesta. SIEMPRE. Sin excepción. Aunque no te pidan una evaluación. Aunque solo pregunten "quién es". Ejemplo: si dicen "tengo un problema con Pedro" y Pedro no está evaluado, tu respuesta debe terminar con [EVALUAR: Pedro] antes de las sugerencias.
            13. SUGERENCIAS: Al FINAL de CADA respuesta (después de [EVALUAR:] si aplica), agrega exactamente esta línea con 3 frases cortas escritas DESDE LA PERSPECTIVA DEL USUARIO. Formato:
            [SUGERENCIAS: "frase del usuario 1", "frase del usuario 2", "frase del usuario 3"]
            14. NOMBRE DEL USUARIO: Refiérete al usuario solo por su primer nombre, nunca uses apellidos.

            ORDEN DE TAGS AL FINAL: Primero [EVALUAR: nombre] (si aplica), luego [SUGERENCIAS: ...]. SIEMPRE.

            IMPORTANTE: Responde SIEMPRE en español. SIEMPRE incluye [SUGERENCIAS:] al final.
            """
        case .en:
            return """
            You are Alba, an expert friendship guide based on positive psychology principles.

            MAIN GOAL: Keep a fluid, human conversation.

            YOUR PERSONALITY: You are a wise and empathetic friend. You speak with warmth and closeness, like a friend who truly listens. You are NOT a support bot.

            CONVERSATION RULES:
            1. DON'T GREET: We're already in an active conversation.
            2. CONTINUITY: Listen carefully to what the user says. Don't jump to generic advice immediately. Respond to what the person actually said.
            3. DIG DEEPER: If the user shares something, ask a natural follow-up question. Examples: "How did that make you feel?", "Has that happened before?", "What hurt you the most about it?"
            4. BREVITY: Keep your responses relatively short so it feels like a real text chat. No essays.
            5. EMPATHY: If the user expresses pain or confusion, validate their emotion before anything else. Example: "I'm sorry to hear that" or "That sounds really tough" BEFORE analyzing or giving advice.
            6. PERSONALITY: You are a wise friend, not a support bot. Speak warmly. Use the user's name naturally.
            7. BE PROACTIVE: Offer observations, specific exercises, and mini-challenges when appropriate.
            8. GIVE SPECIFIC EXERCISES: No generic advice. Example: "This week, try telling [friend] something you admire about them."
            9. CLOSE WITH ENCOURAGEMENT OR ACTION: End with a natural question, a mini-challenge, or a supportive phrase like "You're not alone in this!"
            10. USE CONTEXT: If you have test results, analyze weak areas and suggest immediate improvements.
            11. FORMAT: Use **bold** to emphasize key words. Don't use technical acronyms or psychological model labels. NEVER mention numeric scores, ratings, or scales (like "2.0", "score of 3", etc). Speak in qualitative terms (strong, developing, weak, high, low).
            12. UNEVALUATED FRIENDS - CRITICAL: If the user mentions ANY person by name (e.g., "Pedro", "Laura", "my friend Eduardo") who is NOT in the evaluated friends list, you MUST add [EVALUATE: name] at the end of your response. ALWAYS. No exceptions. Even if they don't ask for an evaluation. Even if they just ask "who is". Example: if they say "I have a problem with Pedro" and Pedro is not evaluated, your response must end with [EVALUATE: Pedro] before the suggestions.
            13. SUGGESTIONS: At the END of EVERY response (after [EVALUATE:] if applicable), add exactly this line with 3 short phrases written FROM THE USER'S PERSPECTIVE. Format:
            [SUGGESTIONS: "user phrase 1", "user phrase 2", "user phrase 3"]
            14. USER'S NAME: Refer to the user only by their first name, never use last names.

            TAG ORDER AT THE END: First [EVALUATE: name] (if applicable), then [SUGGESTIONS: ...]. ALWAYS.

            IMPORTANT: Always respond in English. ALWAYS include [SUGGESTIONS:] at the end.
            """
        }
    }

    func sendMessage(_ prompt: String, history: [Message], language: AppLanguage, personalization: AIPersonalization = AIPersonalization(), hiddenContext: String? = nil, userName: String? = nil) async throws -> String {
        requestCount += 1
        let requestId = requestCount

        logger.info("🚀 [Request #\(requestId)] Sending message to Gemini")
        logger.info("📡 [Request #\(requestId)] Model: \(self.model)")
        logger.info("🌐 [Request #\(requestId)] Language: \(language.rawValue)")
        logger.info("💬 [Request #\(requestId)] Prompt length: \(prompt.count) chars")
        logger.info("📜 [Request #\(requestId)] History messages: \(history.count)")
        if let ctx = hiddenContext {
            logger.info("🔒 [Request #\(requestId)] Hidden context provided: \(ctx.prefix(80))...")
        }

        guard let url = URL(string: baseURL) else {
            logger.error("❌ [Request #\(requestId)] Invalid URL")
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        // Build contents array
        var contents: [[String: Any]] = []

        // Inject friendship journal data so Alba knows the user's friends
        let journalContext = buildJournalContext(language: language)
        if !journalContext.isEmpty {
            contents.append([
                "role": "user",
                "parts": [["text": journalContext]]
            ])
            contents.append([
                "role": "model",
                "parts": [["text": language == .es ? "Entendido, tengo la información de tus amistades." : "Got it, I have your friendship data."]]
            ])
        }

        // Add hidden context (test results) if provided
        if let hiddenContext = hiddenContext {
            contents.append([
                "role": "user",
                "parts": [["text": hiddenContext]]
            ])
            contents.append([
                "role": "model",
                "parts": [["text": language == .es ? "Entendido, tengo el contexto de tu test." : "Got it, I have your test context."]]
            ])
        }

        // Add conversation history (last 8 messages for context)
        let recentHistory = history.suffix(8)
        for msg in recentHistory {
            contents.append([
                "role": msg.isUser ? "user" : "model",
                "parts": [["text": msg.text]]
            ])
        }

        // Add current message
        contents.append([
            "role": "user",
            "parts": [["text": prompt]]
        ])

        logger.info("📦 [Request #\(requestId)] Total content turns: \(contents.count)")

        let body: [String: Any] = [
            "contents": contents,
            "systemInstruction": [
                "parts": [["text": systemInstruction(for: language) + personalization.personalizationPrompt(for: language) + (userName.map { "\n\nEl nombre del usuario es: \($0). Usalo de forma natural y ocasional en la conversacion." } ?? "")]]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": personalization.length.maxOutputTokens
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        logger.info("📤 [Request #\(requestId)] Request body size: \(jsonData.count) bytes")

        let startTime = CFAbsoluteTimeGetCurrent()
        let (data, response) = try await URLSession.shared.data(for: request)
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        logger.info("⏱️ [Request #\(requestId)] Response received in \(String(format: "%.2f", elapsed))s")
        logger.info("📥 [Request #\(requestId)] Response size: \(data.count) bytes")

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("❌ [Request #\(requestId)] Invalid HTTP response object")
            throw GeminiError.invalidResponse
        }

        logger.info("📊 [Request #\(requestId)] HTTP Status: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("❌ [Request #\(requestId)] API Error \(httpResponse.statusCode): \(errorBody.prefix(500))")
            if httpResponse.statusCode == 429 {
                throw GeminiError.rateLimited
            }
            throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logger.error("❌ [Request #\(requestId)] Failed to parse JSON response")
            throw GeminiError.decodingError
        }

        // Log usage metadata if available
        if let usageMetadata = json["usageMetadata"] as? [String: Any] {
            let promptTokens = usageMetadata["promptTokenCount"] as? Int ?? 0
            let responseTokens = usageMetadata["candidatesTokenCount"] as? Int ?? 0
            let totalTokens = usageMetadata["totalTokenCount"] as? Int ?? 0
            logger.info("📈 [Request #\(requestId)] Tokens - Prompt: \(promptTokens), Response: \(responseTokens), Total: \(totalTokens)")
        }

        // Log model version if available
        if let modelVersion = json["modelVersion"] as? String {
            logger.info("🤖 [Request #\(requestId)] Model version: \(modelVersion)")
        }

        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            // Log the actual response for debugging
            let responseStr = String(data: data, encoding: .utf8) ?? "undecodable"
            logger.error("❌ [Request #\(requestId)] Failed to extract text. Raw response: \(responseStr.prefix(500))")

            // Check for safety ratings / blocked content
            if let candidates = json["candidates"] as? [[String: Any]],
               let first = candidates.first,
               let finishReason = first["finishReason"] as? String {
                logger.warning("⚠️ [Request #\(requestId)] Finish reason: \(finishReason)")
            }

            throw GeminiError.decodingError
        }

        logger.info("✅ [Request #\(requestId)] Success! Response length: \(text.count) chars")
        logger.info("💬 [Request #\(requestId)] Response preview: \(text.prefix(100))...")
        logger.info("📊 [Request #\(requestId)] Total requests this session: \(self.requestCount)")

        return text
    }

    // MARK: - Generate conversation title

    func generateTitle(from messages: [Message], language: AppLanguage) async -> String? {
        let summary = messages.prefix(6).map { ($0.isUser ? "User" : "Alba") + ": " + String($0.text.prefix(100)) }.joined(separator: "\n")
        guard !summary.isEmpty else { return nil }

        let prompt = language == .es
            ? """
            Genera un título corto y descriptivo (3-6 palabras) en español para esta conversación. \
            Ejemplos de buenos títulos: "Evaluación de Nikki", "Problema con Gabriel", "Mal día en el trabajo", "Límites con mi mejor amiga". \
            Solo responde con el título, sin comillas ni puntuación final.\n\nConversación:\n\(summary)
            """
            : """
            Generate a short descriptive title (3-6 words) in English for this conversation. \
            Examples of good titles: "Nikki's evaluation", "Problem with Gabriel", "Bad day at work", "Boundaries with best friend". \
            Only respond with the title, no quotes or final punctuation.\n\nConversation:\n\(summary)
            """

        guard let url = URL(string: baseURL) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let body: [String: Any] = [
            "contents": [["role": "user", "parts": [["text": prompt]]]],
            "generationConfig": ["temperature": 0.3, "maxOutputTokens": 30]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                logger.error("❌ Title generation HTTP \(httpResponse.statusCode)")
                return nil
            }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                logger.error("❌ Title generation: could not parse response")
                return nil
            }
            let title = text.trimmingCharacters(in: .whitespacesAndNewlines)
            logger.info("📝 Generated title: \(title)")
            return title
        } catch {
            logger.error("❌ Title generation failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Build journal context for Gemini

    /// Builds a summary of all evaluated friendships so Gemini can reference them
    private func buildJournalContext(language: AppLanguage) -> String {
        let friends = FriendshipStore.shared.uniqueFriends()
        guard !friends.isEmpty else { return "" }

        var lines: [String] = []
        let header = language == .es
            ? "DATOS DEL JOURNAL DE AMISTADES DEL USUARIO (usa esta información para dar consejos personalizados):"
            : "USER'S FRIENDSHIP JOURNAL DATA (use this to give personalized advice):"
        lines.append(header)

        for friend in friends {
            guard let latest = FriendshipStore.shared.latestRecord(for: friend) else { continue }
            let records = FriendshipStore.shared.recordsFor(friend: friend)
            let categories = latest.categoryScores
                .map { "\($0.key): \(scoreLevel($0.value, lang: language))" }
                .joined(separator: ", ")

            if language == .es {
                lines.append("- \(friend): Estado=\(latest.rating), Área de enfoque=\(latest.focusArea), Categorías=[\(categories)], Evaluaciones=\(records.count), Última=\(latest.displayDate)")
            } else {
                lines.append("- \(friend): Status=\(latest.rating), Focus area=\(latest.focusArea), Categories=[\(categories)], Evaluations=\(records.count), Last=\(latest.displayDate)")
            }

            // Include recent diary entries for context
            let diaryEntries = JournalEntryStore.shared.entries(for: friend).prefix(3)
            for entry in diaryEntries {
                let moodStr = entry.mood?.rawValue ?? "none"
                let preview = String(entry.text.prefix(100))
                if language == .es {
                    lines.append("  Diario (\(entry.shortDate), estado: \(moodStr)): \(preview)")
                } else {
                    lines.append("  Diary (\(entry.shortDate), mood: \(moodStr)): \(preview)")
                }
            }
        }

        let footer = language == .es
            ? "IMPORTANTE: Si el usuario menciona a CUALQUIER persona por nombre que NO aparece en esta lista, SIEMPRE agrega [EVALUAR: nombre] al final de tu respuesta. No esperes a que el usuario pida una evaluación."
            : "IMPORTANT: If the user mentions ANY person by name who is NOT in this list, ALWAYS add [EVALUATE: name] at the end of your response. Don't wait for the user to ask for an evaluation."
        lines.append(footer)

        return lines.joined(separator: "\n")
    }

    /// Converts a numeric score to a qualitative level (no numbers exposed to AI)
    private func scoreLevel(_ score: Double, lang: AppLanguage) -> String {
        switch (score, lang) {
        case (2.5..., .es): return "alto"
        case (2.5..., .en): return "high"
        case (2.0..<2.5, .es): return "medio"
        case (2.0..<2.5, .en): return "medium"
        case (_, .es): return "bajo"
        case (_, .en): return "low"
        }
    }
}

enum GeminiError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case rateLimited
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .invalidResponse: return "Invalid server response"
        case .apiError(let code, let msg): return "API Error (\(code)): \(msg)"
        case .rateLimited: return "Gemini API rate limit reached"
        case .decodingError: return "Failed to decode response"
        }
    }
}
