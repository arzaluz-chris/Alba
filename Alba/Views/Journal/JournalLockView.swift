import SwiftUI

struct JournalLockView: View {
    @Binding var currentView: AppState
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var securityManager = JournalSecurityManager.shared
    @State private var pinEntryId: UUID = UUID()
    @State private var showSecurityPrompt: Bool = false
    @State private var showPINSetup: Bool = false

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
                // First time using journal? Ask about security
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
                        } else {
                            HapticManager.shared.notification(.error)
                            pinEntryId = UUID()
                        }
                    },
                    onBiometric: securityManager.isBiometricEnabled ? { attemptBiometric() } : nil
                )
                .id(pinEntryId)
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
