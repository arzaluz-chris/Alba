import Foundation
import Combine
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Alba", category: "VoiceRateLimiter")

/// Tracks daily voice call usage so we don't burn the free-tier quota on the Gemini Live API.
/// Independent from the text RateLimiter — voice has its own counters (calls/day and seconds/day).
@MainActor
final class VoiceRateLimiter: ObservableObject {
    static let shared = VoiceRateLimiter()

    @Published var callsUsedToday: Int = 0
    @Published var secondsUsedToday: Int = 0

    private let callsKey = "alba_daily_voice_calls_count"
    private let secondsKey = "alba_daily_voice_seconds_count"
    private let dateKey = "alba_daily_voice_date"

    private init() {
        resetIfNewDay()
    }

    /// Limit depends on whether the user signed in with Apple.
    var dailyCallLimit: Int {
        let isRegistered = KeychainHelper.load(key: "appleUserIdentifier") != nil
        return isRegistered
            ? RemoteConfigService.shared.maxDailyVoiceCalls
            : RemoteConfigService.shared.maxDailyVoiceCallsUnregistered
    }

    /// Client-side cap per individual call. Buffer against Gemini Live's 15 min hard cap.
    var maxSessionSeconds: Int {
        RemoteConfigService.shared.maxVoiceCallSeconds
    }

    /// Hard ceiling on total voice-call seconds per day. Protects the free tier.
    var dailyTotalSecondsLimit: Int {
        RemoteConfigService.shared.maxDailyVoiceSeconds
    }

    var callsRemaining: Int {
        max(0, dailyCallLimit - callsUsedToday)
    }

    var secondsRemaining: Int {
        max(0, dailyTotalSecondsLimit - secondsUsedToday)
    }

    /// Either cap blocks the user.
    var hasReachedLimit: Bool {
        hasReachedCallsLimit || hasReachedSecondsLimit
    }

    var hasReachedCallsLimit: Bool {
        callsUsedToday >= dailyCallLimit
    }

    var hasReachedSecondsLimit: Bool {
        secondsUsedToday >= dailyTotalSecondsLimit
    }

    /// Call this after a voice call finishes to persist the usage.
    func recordCall(durationSeconds: Int) {
        resetIfNewDay()
        callsUsedToday += 1
        secondsUsedToday += max(0, durationSeconds)
        UserDefaults.standard.set(callsUsedToday, forKey: callsKey)
        UserDefaults.standard.set(secondsUsedToday, forKey: secondsKey)
        logger.info("📞 Voice call recorded: \(durationSeconds)s. Today: \(self.callsUsedToday)/\(self.dailyCallLimit) calls, \(self.secondsUsedToday)s total")
    }

    private func resetIfNewDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let savedDate = UserDefaults.standard.object(forKey: dateKey) as? Date {
            let savedDay = calendar.startOfDay(for: savedDate)
            if today > savedDay {
                callsUsedToday = 0
                secondsUsedToday = 0
                UserDefaults.standard.set(0, forKey: callsKey)
                UserDefaults.standard.set(0, forKey: secondsKey)
                UserDefaults.standard.set(today, forKey: dateKey)
                logger.info("🔄 New day detected. Voice counters reset.")
                return
            }
        } else {
            UserDefaults.standard.set(today, forKey: dateKey)
        }

        callsUsedToday = UserDefaults.standard.integer(forKey: callsKey)
        secondsUsedToday = UserDefaults.standard.integer(forKey: secondsKey)
    }
}
