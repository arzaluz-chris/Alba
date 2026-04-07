import Foundation

// MARK: - Localization Keys
enum LKey: String {
    // General
    case settings, music, language, spanish, english

    // Welcome
    case helloName, iAmAlbaWelcome, albaTest, albaIA, albaBlocks

    // Music
    case playAll, songPromptTitle, repeatSong, changeSong, noMusic
    case searchMusic, nowPlaying, appleMusic

    // Onboarding
    case beforeStart, youAre, man, woman
    case whatIsYourName, yourNamePlaceholder, nameValidation, accept
    case signInWithApple, signInSubtitle
    case onboardingHello, onboardingGenderAsk, onboardingNameAsk
    case onboardingNiceName, onboardingReady

    // Alba Test
    case albaTestTitle, welcomeGendered, testIntro, instructionChoose
    case startTest, questionProgress, seeResults, nextQuestion
    case friendNamePlaceholder, friendNameValidation, preferNotName

    // Results
    case basedOnPerception, exploreWithAlba, backToHome

    // Chat
    case chatTitle, typeHere, chatConnectionError, chatRateLimited, aiThinking

    // Alba Blocks
    case albaBlocksTitle, addAsset, read

    // AI Personalization
    case aiPersonalization, communicationStyle, responseLength, useEmojis
    case responseExample

    // Article error
    case articleLoadError

    // Tutorial
    case tutSkip, tutNext, tutOpen, tutStart, tutDone

    // Quick Actions
    case quickActionTestSubtitle, quickActionChatSubtitle
    case quickActionBlocksSubtitle, quickActionJournalSubtitle

    // AI Onboarding
    case aiOnboardingPrivacyTitle, aiOnboardingPrivacyBody, aiOnboardingDisclaimerBody
    case aiOnboardingAccept
    case aiOnboardingTourChatTitle, aiOnboardingTourChatBody
    case aiOnboardingTourTestTitle, aiOnboardingTourTestBody
    case aiOnboardingTourPersonalizationTitle, aiOnboardingTourPersonalizationBody
    case aiOnboardingDoneTitle, aiOnboardingDoneBody
    case aiOnboardingContinue, aiOnboardingGetStarted
}

// MARK: - Localization Helper
struct L10n {
    static func t(_ key: LKey, _ lang: AppLanguage, _ args: CVarArg...) -> String {
        let value: String
        switch lang {
        case .es: value = es[key] ?? key.rawValue
        case .en: value = en[key] ?? key.rawValue
        }
        if args.isEmpty { return value }
        return String(format: value, locale: Locale(identifier: lang.localeIdentifier), arguments: args)
    }

    // MARK: - Spanish
    private static let es: [LKey: String] = [
        .settings: "Configuración",
        .music: "Música",
        .language: "Idioma",
        .spanish: "Español",
        .english: "Inglés",

        .helloName: "Hola %@",
        .iAmAlbaWelcome: "Soy Alba y estoy aquí para ayudarte a mejorar tus amistades.",
        .albaTest: "Alba Test",
        .albaIA: "AlbaIA",
        .albaBlocks: "Alba Blocks",

        .playAll: "Reproducir todo",
        .songPromptTitle: "¿Quieres repetir la canción o cambiarla?",
        .repeatSong: "Repetir",
        .changeSong: "Cambiar",
        .noMusic: "No quiero escuchar nada",
        .searchMusic: "Buscar canción...",
        .nowPlaying: "Reproduciendo",
        .appleMusic: "Apple Music",

        .beforeStart: "Antes de iniciar, me gustaría saber unas cosas sobre ti",
        .youAre: "Eres...",
        .man: "Hombre",
        .woman: "Mujer",
        .whatIsYourName: "¿Cómo te llamas?",
        .yourNamePlaceholder: "Tu nombre",
        .nameValidation: "El nombre debe tener +3 letras, iniciar en mayúscula, sin números, y solo 1 emoji.",
        .accept: "Aceptar",
        .signInWithApple: "Iniciar sesión con Apple",
        .signInSubtitle: "Tu información está segura y nunca será compartida.",
        .onboardingHello: "¡Hola! Soy Alba 👋",
        .onboardingGenderAsk: "Antes de comenzar, ¿cómo te identificas?",
        .onboardingNameAsk: "¡Genial! ¿Y cómo te llamas?",
        .onboardingNiceName: "Mucho gusto, %@ ✨",
        .onboardingReady: "Estoy lista para ayudarte a mejorar tus amistades. ¿Empezamos?",

        .albaTestTitle: "Alba Test",
        .welcomeGendered: "Bienvenid%@ %@",
        .testIntro: "Este Test te ayudará a saber qué clase de amistad tienes con esa persona y es por eso que necesito que respondas con sinceridad las siguientes preguntas.",
        .instructionChoose: "Elige la opción que mejor te describa.",
        .startTest: "Iniciar Test",
        .questionProgress: "Pregunta %d de %d",
        .seeResults: "Ver Resultados",
        .nextQuestion: "Siguiente Pregunta",
        .friendNamePlaceholder: "Escribe el nombre aquí (Ej: Laura)",
        .friendNameValidation: "Debe empezar con Mayúscula, tener mínimo 3 letras, y no contener números ni símbolos.",
        .preferNotName: "Prefiero no escribir el nombre",

        .basedOnPerception: "El análisis se basa en tu percepción de la relación al momento de responder el test.",
        .exploreWithAlba: "Explorar Respuestas con AlbaIA",
        .backToHome: "Regresar a la pantalla de inicio",

        .chatTitle: "AlbaIA",
        .typeHere: "Escribe aquí...",
        .chatConnectionError: "¡Uy! Parece que algo falló con la conexión.",
        .chatRateLimited: "El servicio de inteligencia artificial (Gemini) ha alcanzado su límite de uso por hoy. Vuelve a intentarlo mañana.",
        .aiThinking: "Alba está pensando...",

        .albaBlocksTitle: "Alba Blocks",
        .addAsset: "Agrega %@ a Assets",
        .read: "Leer",

        .aiPersonalization: "Alba IA",
        .communicationStyle: "Estilo de comunicación",
        .responseLength: "Extensión de respuesta",
        .useEmojis: "Usar emojis",
        .responseExample: "Ejemplo de respuesta",

        .quickActionTestSubtitle: "Evalúa una amistad",
        .quickActionChatSubtitle: "Habla con Alba",
        .quickActionBlocksSubtitle: "Lee artículos",
        .quickActionJournalSubtitle: "Ve tu diario",

        .articleLoadError: "No se pudo cargar el artículo.",

        .tutSkip: "Omitir",
        .tutNext: "Siguiente",
        .tutOpen: "Abrir",
        .tutStart: "Empezar",
        .tutDone: "Entendido",

        .aiOnboardingPrivacyTitle: "Antes de comenzar",
        .aiOnboardingPrivacyBody: "Tu privacidad es importante. Tus conversaciones con Alba se procesan de forma segura y no se comparten con terceros, cumpliendo con las regulaciones de protección de datos aplicables.",
        .aiOnboardingDisclaimerBody: "AlbaIA utiliza inteligencia artificial (Gemini). Las respuestas pueden contener errores y **no sustituyen** el consejo profesional de un psicólogo o terapeuta.",
        .aiOnboardingAccept: "Acepto y continuar",
        .aiOnboardingTourChatTitle: "Platica con Alba",
        .aiOnboardingTourChatBody: "Preguntale a Alba sobre tus amistades. Recibe consejos basados en psicologia positiva.",
        .aiOnboardingTourTestTitle: "Test desde el chat",
        .aiOnboardingTourTestBody: "Si mencionas a un amigo que no has evaluado, Alba te sugerira hacer el Alba Test directamente desde aqui.",
        .aiOnboardingTourPersonalizationTitle: "Personaliza a Alba",
        .aiOnboardingTourPersonalizationBody: "Elige cómo quieres que Alba se comunique contigo. Puedes cambiar esto después en Configuración.",
        .aiOnboardingDoneTitle: "Todo listo",
        .aiOnboardingDoneBody: "Alba esta lista para ayudarte. Comencemos!",
        .aiOnboardingContinue: "Continuar",
        .aiOnboardingGetStarted: "Comenzar"
    ]

    // MARK: - English
    private static let en: [LKey: String] = [
        .settings: "Settings",
        .music: "Music",
        .language: "Language",
        .spanish: "Spanish",
        .english: "English",

        .helloName: "Hi %@",
        .iAmAlbaWelcome: "I'm Alba, and I'm here to help you improve your friendships.",
        .albaTest: "Alba Test",
        .albaIA: "AlbaAI",
        .albaBlocks: "Alba Blocks",

        .playAll: "Play all",
        .songPromptTitle: "Do you want to replay the song or change it?",
        .repeatSong: "Replay",
        .changeSong: "Change",
        .noMusic: "I don't want to listen to anything",
        .searchMusic: "Search song...",
        .nowPlaying: "Now Playing",
        .appleMusic: "Apple Music",

        .beforeStart: "Before we start, I'd like to know a few things about you",
        .youAre: "You are...",
        .man: "Man",
        .woman: "Woman",
        .whatIsYourName: "What's your name?",
        .yourNamePlaceholder: "Your name",
        .nameValidation: "Your name must have 3+ letters, start with a capital letter, contain no numbers, and only 1 emoji.",
        .accept: "Continue",
        .signInWithApple: "Sign in with Apple",
        .signInSubtitle: "Your information is safe and will never be shared.",
        .onboardingHello: "Hi! I'm Alba 👋",
        .onboardingGenderAsk: "Before we begin, how do you identify?",
        .onboardingNameAsk: "Great! And what's your name?",
        .onboardingNiceName: "Nice to meet you, %@ ✨",
        .onboardingReady: "I'm ready to help you improve your friendships. Shall we start?",

        .albaTestTitle: "Alba Test",
        .welcomeGendered: "Welcome%@ %@",
        .testIntro: "This test will help you understand what kind of friendship you have with that person, so I need you to answer the following questions honestly.",
        .instructionChoose: "Choose the option that best describes you.",
        .startTest: "Start Test",
        .questionProgress: "Question %d of %d",
        .seeResults: "See Results",
        .nextQuestion: "Next Question",
        .friendNamePlaceholder: "Type the name here (e.g., Laura)",
        .friendNameValidation: "It must start with a capital letter, have at least 3 letters, and contain no numbers or symbols.",
        .preferNotName: "I'd rather not type the name",

        .basedOnPerception: "This analysis is based on your perception of the relationship at the time you answered the test.",
        .exploreWithAlba: "Explore results with AlbaAI",
        .backToHome: "Back to home",

        .chatTitle: "AlbaAI",
        .typeHere: "Type here...",
        .chatConnectionError: "Uh-oh! Something went wrong with the connection.",
        .chatRateLimited: "The AI service (Gemini) has reached its daily usage limit. Please try again tomorrow.",
        .aiThinking: "Alba is thinking...",

        .albaBlocksTitle: "Alba Blocks",
        .addAsset: "Add %@ to Assets",
        .read: "Read",

        .aiPersonalization: "Alba AI",
        .communicationStyle: "Communication style",
        .responseLength: "Response length",
        .useEmojis: "Use emojis",
        .responseExample: "Response example",

        .quickActionTestSubtitle: "Evaluate a friendship",
        .quickActionChatSubtitle: "Chat with Alba",
        .quickActionBlocksSubtitle: "Read articles",
        .quickActionJournalSubtitle: "View your journal",

        .articleLoadError: "Couldn't load the article.",

        .tutSkip: "Skip",
        .tutNext: "Next",
        .tutOpen: "Open",
        .tutStart: "Start",
        .tutDone: "Got it",

        .aiOnboardingPrivacyTitle: "Before we begin",
        .aiOnboardingPrivacyBody: "Your privacy matters. Your conversations with Alba are processed securely and are not shared with third parties, in compliance with applicable data protection regulations.",
        .aiOnboardingDisclaimerBody: "AlbaAI uses artificial intelligence (Gemini). Responses may contain errors and **do not substitute** professional advice from a psychologist or therapist.",
        .aiOnboardingAccept: "I accept and continue",
        .aiOnboardingTourChatTitle: "Chat with Alba",
        .aiOnboardingTourChatBody: "Ask Alba about your friendships. Get advice based on positive psychology.",
        .aiOnboardingTourTestTitle: "Test from chat",
        .aiOnboardingTourTestBody: "If you mention a friend you haven't evaluated, Alba will suggest taking the Alba Test right from here.",
        .aiOnboardingTourPersonalizationTitle: "Personalize Alba",
        .aiOnboardingTourPersonalizationBody: "Choose how you want Alba to communicate with you. You can change this later in Settings.",
        .aiOnboardingDoneTitle: "All set",
        .aiOnboardingDoneBody: "Alba is ready to help you. Let's get started!",
        .aiOnboardingContinue: "Continue",
        .aiOnboardingGetStarted: "Get started"
    ]
}
