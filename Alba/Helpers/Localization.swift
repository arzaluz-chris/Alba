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
    case chatTitle, typeHere, chatConnectionError, aiThinking

    // Alba Blocks
    case albaBlocksTitle, addAsset, read

    // Article error
    case articleLoadError

    // Tutorial
    case tutSkip, tutNext, tutOpen, tutStart, tutDone
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
        .settings: "Configuracion",
        .music: "Musica",
        .language: "Idioma",
        .spanish: "Español",
        .english: "Ingles",

        .helloName: "Hola %@",
        .iAmAlbaWelcome: "Soy Alba y estoy aqui para ayudarte a mejorar tus amistades.",
        .albaTest: "Alba Test",
        .albaIA: "AlbaIA",
        .albaBlocks: "Alba Blocks",

        .playAll: "Reproducir todo",
        .songPromptTitle: "¿Quieres repetir la cancion o cambiarla?",
        .repeatSong: "Repetir",
        .changeSong: "Cambiar",
        .noMusic: "No quiero escuchar nada",
        .searchMusic: "Buscar cancion...",
        .nowPlaying: "Reproduciendo",
        .appleMusic: "Apple Music",

        .beforeStart: "Antes de iniciar, me gustaria saber unas cosas sobre ti",
        .youAre: "Eres...",
        .man: "Hombre",
        .woman: "Mujer",
        .whatIsYourName: "¿Como te llamas?",
        .yourNamePlaceholder: "Tu nombre",
        .nameValidation: "El nombre debe tener +3 letras, iniciar en mayuscula, sin numeros, y solo 1 emoji.",
        .accept: "Aceptar",
        .signInWithApple: "Iniciar sesion con Apple",
        .signInSubtitle: "Tu informacion esta segura y nunca sera compartida.",
        .onboardingHello: "¡Hola! Soy Alba 👋",
        .onboardingGenderAsk: "Antes de comenzar, ¿como te identificas?",
        .onboardingNameAsk: "¡Genial! ¿Y como te llamas?",
        .onboardingNiceName: "Mucho gusto, %@ ✨",
        .onboardingReady: "Estoy lista para ayudarte a mejorar tus amistades. ¿Empezamos?",

        .albaTestTitle: "Alba Test",
        .welcomeGendered: "Bienvenid%@ %@",
        .testIntro: "Este Test te ayudara a saber que clase de amistad tienes con esa persona y es por eso que necesito que respondas con sinceridad las siguientes preguntas.",
        .instructionChoose: "Elige la opcion que mejor te describa.",
        .startTest: "Iniciar Test",
        .questionProgress: "Pregunta %d de %d",
        .seeResults: "Ver Resultados",
        .nextQuestion: "Siguiente Pregunta",
        .friendNamePlaceholder: "Escribe el nombre aqui (Ej: Laura)",
        .friendNameValidation: "Debe empezar con Mayuscula, tener minimo 3 letras, y no contener numeros ni simbolos.",
        .preferNotName: "Prefiero no escribir el nombre",

        .basedOnPerception: "El analisis se basa en tu percepcion de la relacion al momento de responder el test.",
        .exploreWithAlba: "Explorar Respuestas con AlbaIA",
        .backToHome: "Regresar a la pantalla de inicio",

        .chatTitle: "AlbaIA",
        .typeHere: "Escribe aqui...",
        .chatConnectionError: "¡Uy! Parece que algo fallo con la conexion.",
        .aiThinking: "Alba esta pensando...",

        .albaBlocksTitle: "Alba Blocks",
        .addAsset: "Agrega %@ a Assets",
        .read: "Leer",

        .articleLoadError: "No se pudo cargar el articulo.",

        .tutSkip: "Omitir",
        .tutNext: "Siguiente",
        .tutOpen: "Abrir",
        .tutStart: "Empezar",
        .tutDone: "Entendido"
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
        .aiThinking: "Alba is thinking...",

        .albaBlocksTitle: "Alba Blocks",
        .addAsset: "Add %@ to Assets",
        .read: "Read",

        .articleLoadError: "Couldn't load the article.",

        .tutSkip: "Skip",
        .tutNext: "Next",
        .tutOpen: "Open",
        .tutStart: "Start",
        .tutDone: "Got it"
    ]
}
