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

    private init() {
        isPINEnabled = UserDefaults.standard.bool(forKey: pinEnabledKey)
        isBiometricEnabled = UserDefaults.standard.bool(forKey: biometricEnabledKey)
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
        return hashPIN(pin) == storedHash
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

    private func hashPIN(_ pin: String) -> String {
        let data = Data(pin.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
