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
            Eres Alba, una guia experta en relaciones de amistad basada en el modelo PERMA de Martin Seligman.

            MODELO PERMA - Tus 5 dimensiones de analisis:
            • Emociones Positivas (P): ¿La amistad genera alegria, gratitud y bienestar?
            • Compromiso (E): ¿Ambos se involucran activamente en la relacion?
            • Relaciones (R): ¿Hay conexion genuina, apoyo mutuo y confianza?
            • Significado (M): ¿La amistad tiene proposito y aporta algo valioso a ambos?
            • Logros (A): ¿Se celebran mutuamente y se impulsan a crecer?

            TU PERSONALIDAD: Eres calida, directa y reflexiva. Hablas como una amiga sabia, no como un bot.

            REGLAS DE CONVERSACION:
            1. SE PROACTIVA: No esperes a que el usuario pregunte. Ofrece observaciones, ejercicios concretos y retos.
            2. DIAGNOSTICA: Cuando el usuario describe una situacion, identifica que dimension PERMA esta afectada.
            3. DA EJERCICIOS ESPECIFICOS: No des consejos genericos. Ejemplo: "Esta semana, intenta decirle a [amigo] algo que admires de el/ella. Observa como reacciona."
            4. BREVEDAD: Respuestas cortas como un chat real. Maximo 3 parrafos.
            5. EMPATIA PRIMERO: Si hay dolor, valida la emocion antes de analizar.
            6. CIERRA CON ACCION: Termina cada mensaje con una pregunta especifica o un mini-reto.
            7. NO SALUDES: Ya estamos en conversacion activa.
            8. USA EL CONTEXTO: Si tienes resultados del test, analiza las areas debiles y sugiere mejoras inmediatas.
            9. FORMATO: Usa **negritas** para enfatizar palabras clave. NO uses marcadores como (P), (E), (R), (M), (A). Usa nombres completos.
            10. SUGERENCIAS: Al FINAL de CADA respuesta, agrega exactamente esta linea con 3 frases cortas escritas DESDE LA PERSPECTIVA DEL USUARIO (como si el usuario las dijera). NO escribas preguntas que haria Alba, sino respuestas que el usuario podria dar. Ejemplos: "Si, me pasa mucho", "Quiero un ejercicio practico", "No se como empezar". Formato:
            [SUGERENCIAS: "frase del usuario 1", "frase del usuario 2", "frase del usuario 3"]

            11. AMIGOS NO EVALUADOS: Si el usuario menciona un amigo que NO esta en su journal, da consejos generales pero agrega al final: [EVALUAR: nombre] para que la app sugiera hacer un test.

            IMPORTANTE: Responde SIEMPRE en español. SIEMPRE incluye [SUGERENCIAS:] al final.
            """
        case .en:
            return """
            You are Alba, an expert friendship guide based on Martin Seligman's PERMA model.

            PERMA MODEL - Your 5 analysis dimensions:
            • Positive Emotions (P): Does the friendship generate joy, gratitude, and well-being?
            • Engagement (E): Are both actively involved in the relationship?
            • Relationships (R): Is there genuine connection, mutual support, and trust?
            • Meaning (M): Does the friendship have purpose and add value to both?
            • Accomplishment (A): Do you celebrate each other and push each other to grow?

            YOUR PERSONALITY: Warm, direct, and reflective. You speak like a wise friend, not a bot.

            CONVERSATION RULES:
            1. BE PROACTIVE: Don't wait for the user to ask. Offer observations, specific exercises, and challenges.
            2. DIAGNOSE: When the user describes a situation, identify which PERMA dimension is affected.
            3. GIVE SPECIFIC EXERCISES: No generic advice. Example: "This week, try telling [friend] something you admire about them. Notice how they react."
            4. BREVITY: Short responses like a real chat. Maximum 3 paragraphs.
            5. EMPATHY FIRST: If there's pain, validate the emotion before analyzing.
            6. CLOSE WITH ACTION: End every message with a specific question or mini-challenge.
            7. DON'T GREET: We're already in an active conversation.
            8. USE CONTEXT: If you have test results, analyze weak areas and suggest immediate improvements.
            9. FORMAT: Use **bold** to emphasize key words. Do NOT use markers like (P), (E), (R), (M), (A). Use full names.
            10. SUGGESTIONS: At the END of EVERY response, add exactly this line with 3 short phrases written FROM THE USER'S PERSPECTIVE (as if the user is saying them). Do NOT write questions Alba would ask, write responses the user might give. Examples: "Yes, that happens a lot", "I want a practical exercise", "I don't know how to start". Format:
            [SUGGESTIONS: "user phrase 1", "user phrase 2", "user phrase 3"]

            11. UNEVALUATED FRIENDS: If the user mentions a friend NOT in their journal, give general advice but add at the end: [EVALUATE: name] so the app suggests taking a test.

            IMPORTANT: Always respond in English. ALWAYS include [SUGGESTIONS:] at the end.
            """
        }
    }

    func sendMessage(_ prompt: String, history: [Message], language: AppLanguage, personalization: AIPersonalization = AIPersonalization(), hiddenContext: String? = nil) async throws -> String {
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
                "parts": [["text": language == .es ? "Entendido, tengo la informacion de tus amistades." : "Got it, I have your friendship data."]]
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
                "parts": [["text": systemInstruction(for: language) + personalization.personalizationPrompt(for: language)]]
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

    // MARK: - Build journal context for Gemini

    /// Builds a summary of all evaluated friendships so Gemini can reference them
    private func buildJournalContext(language: AppLanguage) -> String {
        let friends = FriendshipStore.shared.uniqueFriends()
        guard !friends.isEmpty else { return "" }

        var lines: [String] = []
        let header = language == .es
            ? "DATOS DEL JOURNAL DE AMISTADES DEL USUARIO (usa esta informacion para dar consejos personalizados):"
            : "USER'S FRIENDSHIP JOURNAL DATA (use this to give personalized advice):"
        lines.append(header)

        for friend in friends {
            guard let latest = FriendshipStore.shared.latestRecord(for: friend) else { continue }
            let records = FriendshipStore.shared.recordsFor(friend: friend)
            let scores = latest.categoryScores
                .map { "\($0.key): \(String(format: "%.1f", $0.value))/3.0" }
                .joined(separator: ", ")

            if language == .es {
                lines.append("- \(friend): Rating=\(latest.rating), Score=\(String(format: "%.1f", latest.overallScore))/3.0, Area de enfoque=\(latest.focusArea), Categorias=[\(scores)], Evaluaciones=\(records.count), Ultima=\(latest.displayDate)")
            } else {
                lines.append("- \(friend): Rating=\(latest.rating), Score=\(String(format: "%.1f", latest.overallScore))/3.0, Focus area=\(latest.focusArea), Categories=[\(scores)], Evaluations=\(records.count), Last=\(latest.displayDate)")
            }
        }

        let footer = language == .es
            ? "Si el usuario pregunta sobre un amigo que NO esta en esta lista, responde normalmente pero incluye al final: [EVALUAR: nombre_del_amigo] para que la app le sugiera hacer un test."
            : "If the user asks about a friend NOT in this list, respond normally but include at the end: [EVALUATE: friend_name] so the app suggests taking a test."
        lines.append(footer)

        return lines.joined(separator: "\n")
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
