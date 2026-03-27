import AuthenticationServices
import Combine
import SwiftUI

@MainActor
final class AuthManager: ObservableObject {
    @Published var isSignedIn = false
    @Published var appleUserName: String?

    private let userIdKey = "appleUserIdentifier"
    private let userNameKey = "appleUserName"

    init() {
        checkCredentialState()
    }

    func checkCredentialState() {
        guard let userIdentifier = KeychainHelper.load(key: userIdKey) else {
            isSignedIn = false
            return
        }

        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userIdentifier) { [weak self] state, _ in
            Task { @MainActor in
                switch state {
                case .authorized:
                    self?.isSignedIn = true
                    self?.appleUserName = UserDefaults.standard.string(forKey: "appleUserGivenName")
                case .revoked, .notFound:
                    self?.signOut()
                default:
                    self?.isSignedIn = false
                }
            }
        }
    }

    func handleAuthorization(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

        let userIdentifier = credential.user
        KeychainHelper.save(key: userIdKey, value: userIdentifier)

        // Save name (only available on first authorization)
        if let givenName = credential.fullName?.givenName {
            UserDefaults.standard.set(givenName, forKey: "appleUserGivenName")
            appleUserName = givenName
        }

        if let familyName = credential.fullName?.familyName {
            UserDefaults.standard.set(familyName, forKey: "appleUserFamilyName")
        }

        if let email = credential.email {
            UserDefaults.standard.set(email, forKey: "appleUserEmail")
        }

        isSignedIn = true
        HapticManager.shared.notification(.success)
    }

    func signOut() {
        KeychainHelper.delete(key: userIdKey)
        UserDefaults.standard.removeObject(forKey: "appleUserGivenName")
        UserDefaults.standard.removeObject(forKey: "appleUserFamilyName")
        UserDefaults.standard.removeObject(forKey: "appleUserEmail")
        isSignedIn = false
        appleUserName = nil
    }
}
