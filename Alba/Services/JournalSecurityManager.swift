import Foundation
import Combine
import LocalAuthentication
import CryptoKit
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Alba", category: "JournalSecurity")

final class JournalSecurityManager: ObservableObject {
    static let shared = JournalSecurityManager()

    @Published var isUnlocked: Bool = false
    @Published var isPINEnabled: Bool = false
    @Published var isBiometricEnabled: Bool = false

    private let pinKeychainKey = "alba_journal_pin_hash"
    private let pinEnabledKey = "alba_journal_pin_enabled"
    private let biometricEnabledKey = "alba_journal_biometric_enabled"
    private let failedAttemptsKey = "alba_journal_failed_attempts"
    private let firstFailedAtKey = "alba_journal_first_failed_at"

    static let maxFailedAttempts = 5
    private static let failedWindowSeconds: TimeInterval = 3600 // 1 hour

    @Published var failedAttempts: Int = 0

    private init() {
        isPINEnabled = UserDefaults.standard.bool(forKey: pinEnabledKey)
        isBiometricEnabled = UserDefaults.standard.bool(forKey: biometricEnabledKey)
        loadFailedAttempts()
    }

    var isBiometricAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    var biometricType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    func setPIN(_ pin: String) {
        let hash = hashPIN(pin)
        KeychainHelper.save(key: pinKeychainKey, value: hash)
        isPINEnabled = true
        UserDefaults.standard.set(true, forKey: pinEnabledKey)
        logger.info("🔒 PIN set successfully")
    }

    func verifyPIN(_ pin: String) -> Bool {
        guard let storedHash = KeychainHelper.load(key: pinKeychainKey) else { return false }
        if hashPIN(pin) == storedHash {
            resetFailedAttempts()
            return true
        } else {
            registerFailedAttempt()
            return false
        }
    }

    var remainingAttempts: Int {
        max(0, Self.maxFailedAttempts - failedAttempts)
    }

    func authenticateWithBiometrics(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = ""
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if success {
                await MainActor.run { isUnlocked = true }
                logger.info("🔓 Biometric auth successful")
            }
            return success
        } catch {
            logger.error("❌ Biometric auth failed: \(error.localizedDescription)")
            return false
        }
    }

    func removePIN() {
        KeychainHelper.delete(key: pinKeychainKey)
        isPINEnabled = false
        isBiometricEnabled = false
        isUnlocked = false
        UserDefaults.standard.set(false, forKey: pinEnabledKey)
        UserDefaults.standard.set(false, forKey: biometricEnabledKey)
        logger.info("🗑️ PIN removed")
    }

    func setBiometric(_ enabled: Bool) {
        isBiometricEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: biometricEnabledKey)
    }

    func lock() {
        isUnlocked = false
    }

    func unlock() {
        isUnlocked = true
    }

    // MARK: - Failed Attempts

    private func loadFailedAttempts() {
        let count = UserDefaults.standard.integer(forKey: failedAttemptsKey)
        let firstFailedAt = UserDefaults.standard.object(forKey: firstFailedAtKey) as? Date

        // Reset if the window (1 hour) has expired since the first failed attempt
        if let firstFailed = firstFailedAt,
           Date().timeIntervalSince(firstFailed) > Self.failedWindowSeconds {
            resetFailedAttempts()
            return
        }

        failedAttempts = count
    }

    private func registerFailedAttempt() {
        // Check window expiration before incrementing
        if let firstFailed = UserDefaults.standard.object(forKey: firstFailedAtKey) as? Date,
           Date().timeIntervalSince(firstFailed) > Self.failedWindowSeconds {
            resetFailedAttempts()
        }

        // Set first-failure timestamp if this is the first attempt in a new window
        if failedAttempts == 0 {
            UserDefaults.standard.set(Date(), forKey: firstFailedAtKey)
        }

        failedAttempts += 1
        UserDefaults.standard.set(failedAttempts, forKey: failedAttemptsKey)
        logger.warning("⚠️ Failed PIN attempt \(self.failedAttempts)/\(Self.maxFailedAttempts)")

        if failedAttempts >= Self.maxFailedAttempts {
            wipeJournalData()
        }
    }

    func resetFailedAttempts() {
        failedAttempts = 0
        UserDefaults.standard.set(0, forKey: failedAttemptsKey)
        UserDefaults.standard.removeObject(forKey: firstFailedAtKey)
    }

    private func wipeJournalData() {
        logger.error("🚨 Max PIN attempts reached — wiping journal data")
        FriendshipStore.shared.deleteAll()
        JournalEntryStore.shared.deleteAll()
        removePIN()
        resetFailedAttempts()
    }

    // MARK: - Helpers

    private func hashPIN(_ pin: String) -> String {
        let data = Data(pin.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
