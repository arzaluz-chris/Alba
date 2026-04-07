import SwiftUI

struct JournalLockView: View {
    @Binding var currentView: AppState
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var securityManager = JournalSecurityManager.shared
    @State private var pinEntryId: UUID = UUID()
    @State private var showSecurityPrompt: Bool = false
    @State private var showPINSetup: Bool = false
    @State private var showWipeAlert: Bool = false
    @State private var errorMessage: String = ""

    private var lang: AppLanguage { languageManager.language }

    private var hasSeenPrompt: Bool {
        UserDefaults.standard.bool(forKey: "hasSeenJournalSecurityPrompt")
    }

    var body: some View {
        Group {
            if securityManager.isUnlocked || !securityManager.isPINEnabled {
                NavigationStack {
                    JournalView(currentView: $currentView)
                }
                .onDisappear {
                    securityManager.lock()
                }
            } else {
                unlockView
            }
        }
        .onAppear {
            if !securityManager.isPINEnabled {
                if !hasSeenPrompt {
                    showSecurityPrompt = true
                }
                return
            }
            if securityManager.isBiometricEnabled && securityManager.isBiometricAvailable {
                attemptBiometric()
            }
        }
        .alert(
            lang == .es ? "Protege tu Journal" : "Protect your Journal",
            isPresented: $showSecurityPrompt
        ) {
            Button(lang == .es ? "Configurar PIN" : "Set up PIN") {
                UserDefaults.standard.set(true, forKey: "hasSeenJournalSecurityPrompt")
                showPINSetup = true
            }
            Button(lang == .es ? "Ahora no" : "Not now", role: .cancel) {
                UserDefaults.standard.set(true, forKey: "hasSeenJournalSecurityPrompt")
            }
        } message: {
            Text(lang == .es
                 ? "Tu journal contiene información personal. ¿Quieres protegerlo con un PIN o Face ID?"
                 : "Your journal contains personal information. Want to protect it with a PIN or Face ID?")
        }
        .alert(
            lang == .es ? "Datos eliminados" : "Data Deleted",
            isPresented: $showWipeAlert
        ) {
            Button("OK") {
                currentView = .welcome
            }
        } message: {
            Text(lang == .es
                 ? "Se superó el límite de intentos. Todos los datos del journal han sido eliminados por seguridad."
                 : "Maximum attempts exceeded. All journal data has been deleted for security.")
        }
        .sheet(isPresented: $showPINSetup) {
            PINSetupView {
                showPINSetup = false
            }
            .environmentObject(languageManager)
        }
    }

    private var unlockView: some View {
        ZStack {
            Color.albaBackground.ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        HapticManager.shared.lightImpact()
                        currentView = .welcome
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.albaText)
                    }
                    Spacer()
                    Text(lang == .es ? "Mi Journal" : "My Journal")
                        .font(AlbaFont.serif(20, weight: .bold))
                        .foregroundColor(.albaText)
                    Spacer()
                    Image(systemName: "chevron.left").opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                PINEntryView(
                    mode: .unlock,
                    onComplete: { pin in
                        if securityManager.verifyPIN(pin) {
                            securityManager.unlock()
                            HapticManager.shared.notification(.success)
                            errorMessage = ""
                        } else {
                            HapticManager.shared.notification(.error)
                            if securityManager.remainingAttempts <= 0 {
                                showWipeAlert = true
                            } else {
                                errorMessage = lang == .es
                                    ? "PIN incorrecto. \(securityManager.remainingAttempts) intento\(securityManager.remainingAttempts == 1 ? "" : "s") restante\(securityManager.remainingAttempts == 1 ? "" : "s")."
                                    : "Incorrect PIN. \(securityManager.remainingAttempts) attempt\(securityManager.remainingAttempts == 1 ? "" : "s") remaining."
                            }
                            pinEntryId = UUID()
                        }
                    },
                    onBiometric: securityManager.isBiometricEnabled ? { attemptBiometric() } : nil
                )
                .id(pinEntryId)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(AlbaFont.rounded(14, weight: .medium))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                }
            }
        }
    }

    private func attemptBiometric() {
        let reason = lang == .es
            ? "Desbloquea tu journal"
            : "Unlock your journal"
        Task {
            _ = await securityManager.authenticateWithBiometrics(reason: reason)
        }
    }
}
