import SwiftUI
import LocalAuthentication

struct PINSetupView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject private var securityManager = JournalSecurityManager.shared
    var onComplete: () -> Void

    @State private var step: SetupStep = .create
    @State private var firstPIN: String = ""
    @State private var showBiometricOffer: Bool = false
    @State private var pinEntryId: UUID = UUID()
    @State private var showMismatchError: Bool = false

    private var lang: AppLanguage { languageManager.language }

    enum SetupStep {
        case create, confirm
    }

    var body: some View {
        ZStack {
            if showBiometricOffer {
                biometricOfferView
                    .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    PINEntryView(
                        mode: step == .create ? .create : .confirm,
                        onComplete: { pin in handlePIN(pin) }
                    )
                    .id(pinEntryId)

                    if showMismatchError {
                        Text(lang == .es ? "Los PIN no coinciden. Inténtalo de nuevo." : "PINs don't match. Try again.")
                            .font(AlbaFont.rounded(14, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.bottom, 20)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showBiometricOffer)
        .animation(.easeInOut(duration: 0.3), value: showMismatchError)
    }

    private func handlePIN(_ pin: String) {
        switch step {
        case .create:
            showMismatchError = false
            firstPIN = pin
            step = .confirm
            pinEntryId = UUID()
        case .confirm:
            if pin == firstPIN {
                showMismatchError = false
                securityManager.setPIN(pin)
                securityManager.unlock()
                HapticManager.shared.notification(.success)

                if securityManager.isBiometricAvailable {
                    withAnimation {
                        showBiometricOffer = true
                    }
                } else {
                    onComplete()
                }
            } else {
                // Show error and go back to confirm step (not create)
                HapticManager.shared.notification(.error)
                showMismatchError = true
                pinEntryId = UUID()
                // Stay on confirm step so user can retry
            }
        }
    }

    private var biometricOfferView: some View {
        ZStack {
            Color.albaBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: securityManager.biometricType == .faceID ? "faceid" : "touchid")
                    .font(.system(size: 56))
                    .foregroundColor(.albaAccent)

                Text(lang == .es
                     ? "¿Desbloquear con \(biometricName)?"
                     : "Unlock with \(biometricName)?")
                    .font(AlbaFont.serif(22, weight: .bold))
                    .foregroundColor(.albaText)
                    .multilineTextAlignment(.center)

                Text(lang == .es
                     ? "Usa \(biometricName) para acceder a tu journal más rápido."
                     : "Use \(biometricName) to access your journal faster.")
                    .font(AlbaFont.rounded(15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 20)

                Button {
                    securityManager.setBiometric(true)
                    HapticManager.shared.mediumImpact()
                    onComplete()
                } label: {
                    Text(lang == .es ? "Activar \(biometricName)" : "Enable \(biometricName)")
                        .font(AlbaFont.rounded(16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(LinearGradient.albaAccentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 40)

                Button {
                    onComplete()
                } label: {
                    Text(lang == .es ? "No, gracias" : "No, thanks")
                        .font(AlbaFont.rounded(15, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding(.horizontal, 30)
        }
    }

    private var biometricName: String {
        securityManager.biometricType == .faceID ? "Face ID" : "Touch ID"
    }
}
