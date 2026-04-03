import SwiftUI
import LocalAuthentication

struct JournalSecuritySettingsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject private var securityManager = JournalSecurityManager.shared
    @State private var showPINSetup: Bool = false
    @State private var showRemoveConfirm: Bool = false
    @State private var showAuthForChange: Bool = false
    @State private var showAuthForRemove: Bool = false
    @State private var authPINEntry: String = ""
    @State private var authPINId: UUID = UUID()
    @State private var pendingAction: PendingAction? = nil

    private var lang: AppLanguage { languageManager.language }

    enum PendingAction {
        case changePIN, removePIN
    }

    var body: some View {
        ZStack {
            Color.albaBackground.ignoresSafeArea()

            if showAuthForChange || showAuthForRemove {
                // Verify current PIN first
                VStack {
                    PINEntryView(
                        mode: .unlock,
                        onComplete: { pin in
                            if securityManager.verifyPIN(pin) {
                                HapticManager.shared.notification(.success)
                                if showAuthForChange {
                                    showAuthForChange = false
                                    showPINSetup = true
                                } else if showAuthForRemove {
                                    showAuthForRemove = false
                                    showRemoveConfirm = true
                                }
                            } else {
                                HapticManager.shared.notification(.error)
                                authPINId = UUID()
                            }
                        }
                    )
                    .id(authPINId)

                    Button {
                        showAuthForChange = false
                        showAuthForRemove = false
                    } label: {
                        Text(lang == .es ? "Cancelar" : "Cancel")
                            .font(AlbaFont.rounded(15, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 10)
                }
            } else {
                List {
                    // PIN section
                    Section {
                        if securityManager.isPINEnabled {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.albaAccent)
                                    .frame(width: 24)
                                Text(lang == .es ? "PIN activado" : "PIN enabled")
                                    .font(AlbaFont.rounded(16))
                                    .foregroundColor(.albaText)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }

                            // Change PIN - requires auth first
                            Button {
                                showAuthForChange = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .foregroundColor(.albaAccent)
                                        .frame(width: 24)
                                    Text(lang == .es ? "Cambiar PIN" : "Change PIN")
                                        .font(AlbaFont.rounded(16))
                                        .foregroundColor(.albaText)
                                }
                            }

                            // Remove PIN - requires auth first
                            Button(role: .destructive) {
                                showAuthForRemove = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                        .frame(width: 24)
                                    Text(lang == .es ? "Eliminar PIN" : "Remove PIN")
                                        .font(AlbaFont.rounded(16))
                                }
                            }
                        } else {
                            Button {
                                showPINSetup = true
                            } label: {
                                HStack {
                                    Image(systemName: "lock.open")
                                        .foregroundColor(.albaAccent)
                                        .frame(width: 24)
                                    Text(lang == .es ? "Activar PIN" : "Enable PIN")
                                        .font(AlbaFont.rounded(16, weight: .medium))
                                        .foregroundColor(.albaText)
                                }
                            }
                        }
                    } header: {
                        Text("PIN")
                            .font(AlbaFont.rounded(12, weight: .medium))
                    }
                    .listRowBackground(Color.white.opacity(0.5))

                    // Biometric section
                    if securityManager.isPINEnabled && securityManager.isBiometricAvailable {
                        Section {
                            Toggle(isOn: Binding(
                                get: { securityManager.isBiometricEnabled },
                                set: { securityManager.setBiometric($0) }
                            )) {
                                HStack(spacing: 12) {
                                    Image(systemName: securityManager.biometricType == .faceID ? "faceid" : "touchid")
                                        .foregroundColor(.albaAccent)
                                        .frame(width: 24)
                                    Text(biometricName)
                                        .font(AlbaFont.rounded(16))
                                        .foregroundColor(.albaText)
                                }
                            }
                            .tint(.albaAccent)
                        } header: {
                            Text(lang == .es ? "Biométrico" : "Biometric")
                                .font(AlbaFont.rounded(12, weight: .medium))
                        }
                        .listRowBackground(Color.white.opacity(0.5))
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(lang == .es ? "Seguridad del Journal" : "Journal Security")
                    .font(AlbaFont.serif(20, weight: .bold))
                    .foregroundColor(.albaText)
            }
        }
        .sheet(isPresented: $showPINSetup) {
            PINSetupView {
                showPINSetup = false
            }
            .environmentObject(languageManager)
        }
        .alert(
            lang == .es ? "¿Eliminar PIN?" : "Remove PIN?",
            isPresented: $showRemoveConfirm
        ) {
            Button(lang == .es ? "Cancelar" : "Cancel", role: .cancel) {}
            Button(lang == .es ? "Eliminar" : "Remove", role: .destructive) {
                securityManager.removePIN()
                HapticManager.shared.notification(.warning)
            }
        } message: {
            Text(lang == .es
                 ? "Tu journal quedará sin protección."
                 : "Your journal will be unprotected.")
        }
    }

    private var biometricName: String {
        securityManager.biometricType == .faceID ? "Face ID" : "Touch ID"
    }
}
