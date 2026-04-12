import Foundation
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Alba", category: "RemoteConfig")

// MARK: - Config Model

struct AppConfig: Codable {
    var geminiModel: String = "gemini-3.1-flash-lite-preview"
    var maxDailyChatMessages: Int = 50
    var maxDailyUnregisteredMessages: Int = 15
    var chatEnabled: Bool = true
    var albaTestEnabled: Bool = true
    var journalEnabled: Bool = true
    var blocksEnabled: Bool = true

    // Voice Mode
    var voiceModeEnabled: Bool = true
    var geminiLiveModel: String = "gemini-2.5-flash-native-audio-preview-09-2025"
    var geminiLiveVoiceName: String = "Leda"
    var maxDailyVoiceCalls: Int = 5
    var maxDailyVoiceCallsUnregistered: Int = 2
    var maxVoiceCallSeconds: Int = 780 // 13 min — buffer vs Gemini's 15 min hard cap
}

// MARK: - Remote Config Service

@MainActor
final class RemoteConfigService {
    static let shared = RemoteConfigService()

    private let configURL = URL(string: "https://chrisarzaluz.dev/alba/config.json")!
    private let cacheKey = "cached_alba_config"

    private(set) var config: AppConfig

    // MARK: - Typed Accessors

    var geminiModel: String { config.geminiModel }
    var maxDailyChatMessages: Int { config.maxDailyChatMessages }
    var maxDailyUnregisteredMessages: Int { config.maxDailyUnregisteredMessages }
    var isChatEnabled: Bool { config.chatEnabled }
    var isAlbaTestEnabled: Bool { config.albaTestEnabled }
    var isJournalEnabled: Bool { config.journalEnabled }
    var isBlocksEnabled: Bool { config.blocksEnabled }

    // Voice Mode
    var isVoiceModeEnabled: Bool { config.voiceModeEnabled }
    var geminiLiveModel: String { config.geminiLiveModel }
    var geminiLiveVoiceName: String { config.geminiLiveVoiceName }
    var maxDailyVoiceCalls: Int { config.maxDailyVoiceCalls }
    var maxDailyVoiceCallsUnregistered: Int { config.maxDailyVoiceCallsUnregistered }
    var maxVoiceCallSeconds: Int { config.maxVoiceCallSeconds }

    // MARK: - Init

    private init() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode(AppConfig.self, from: data) {
            self.config = cached
            logger.info("Loaded cached config")
        } else {
            self.config = AppConfig()
            logger.info("Using default config")
        }
    }

    // MARK: - Fetch

    func fetchConfig() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: configURL)
            let decoded = try JSONDecoder().decode(AppConfig.self, from: data)
            self.config = decoded
            UserDefaults.standard.set(data, forKey: cacheKey)
            logger.info("Fetched remote config: model=\(decoded.geminiModel)")
        } catch {
            logger.warning("Fetch failed, using cached/defaults: \(error.localizedDescription)")
        }
    }
}
