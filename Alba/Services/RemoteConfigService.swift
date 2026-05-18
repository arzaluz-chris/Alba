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
    var geminiLiveVoiceName: String = "Despina"
    var maxDailyVoiceCalls: Int = 3
    var maxDailyVoiceCallsUnregistered: Int = 1
    var maxVoiceCallSeconds: Int = 300 // 5 min — conservative per-call cap
    var maxDailyVoiceSeconds: Int = 900 // 15 min total/day hard cap to protect free tier

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppConfig()

        geminiModel = try container.decodeIfPresent(String.self, forKey: .geminiModel) ?? defaults.geminiModel
        maxDailyChatMessages = try container.decodeIfPresent(Int.self, forKey: .maxDailyChatMessages) ?? defaults.maxDailyChatMessages
        maxDailyUnregisteredMessages = try container.decodeIfPresent(Int.self, forKey: .maxDailyUnregisteredMessages) ?? defaults.maxDailyUnregisteredMessages
        chatEnabled = try container.decodeIfPresent(Bool.self, forKey: .chatEnabled) ?? defaults.chatEnabled
        albaTestEnabled = try container.decodeIfPresent(Bool.self, forKey: .albaTestEnabled) ?? defaults.albaTestEnabled
        journalEnabled = try container.decodeIfPresent(Bool.self, forKey: .journalEnabled) ?? defaults.journalEnabled
        blocksEnabled = try container.decodeIfPresent(Bool.self, forKey: .blocksEnabled) ?? defaults.blocksEnabled

        voiceModeEnabled = try container.decodeIfPresent(Bool.self, forKey: .voiceModeEnabled) ?? defaults.voiceModeEnabled
        geminiLiveModel = try container.decodeIfPresent(String.self, forKey: .geminiLiveModel) ?? defaults.geminiLiveModel
        geminiLiveVoiceName = try container.decodeIfPresent(String.self, forKey: .geminiLiveVoiceName) ?? defaults.geminiLiveVoiceName
        maxDailyVoiceCalls = try container.decodeIfPresent(Int.self, forKey: .maxDailyVoiceCalls) ?? defaults.maxDailyVoiceCalls
        maxDailyVoiceCallsUnregistered = try container.decodeIfPresent(Int.self, forKey: .maxDailyVoiceCallsUnregistered) ?? defaults.maxDailyVoiceCallsUnregistered
        maxVoiceCallSeconds = try container.decodeIfPresent(Int.self, forKey: .maxVoiceCallSeconds) ?? defaults.maxVoiceCallSeconds
        maxDailyVoiceSeconds = try container.decodeIfPresent(Int.self, forKey: .maxDailyVoiceSeconds) ?? defaults.maxDailyVoiceSeconds
    }
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
    var maxDailyChatMessages: Int { max(0, config.maxDailyChatMessages) }
    var maxDailyUnregisteredMessages: Int { max(0, config.maxDailyUnregisteredMessages) }
    var isChatEnabled: Bool { config.chatEnabled }
    var isAlbaTestEnabled: Bool { config.albaTestEnabled }
    var isJournalEnabled: Bool { config.journalEnabled }
    var isBlocksEnabled: Bool { config.blocksEnabled }

    // Voice Mode
    var isVoiceModeEnabled: Bool { config.voiceModeEnabled }
    var geminiLiveModel: String { config.geminiLiveModel }
    var geminiLiveVoiceName: String { config.geminiLiveVoiceName }
    var maxDailyVoiceCalls: Int { max(0, config.maxDailyVoiceCalls) }
    var maxDailyVoiceCallsUnregistered: Int { max(0, config.maxDailyVoiceCallsUnregistered) }
    var maxVoiceCallSeconds: Int { max(1, config.maxVoiceCallSeconds) }
    var maxDailyVoiceSeconds: Int { max(0, config.maxDailyVoiceSeconds) }

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
        guard !ScreenshotMode.isActive else { return }

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
