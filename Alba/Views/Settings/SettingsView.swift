import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var musicViewModel: MusicViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm: Bool = false
    @State private var showChangeName: Bool = false
    @State private var newName: String = ""
    var onDeleteAccount: (() -> Void)?

    private var lang: AppLanguage { languageManager.language }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.albaBackground
                    .ignoresSafeArea()

                List {
                    // MARK: - Music
                    NavigationLink {
                        MusicSearchView()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "music.note")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.albaAccent)
                                .frame(width: 32)

                            Text(L10n.t(.music, lang))
                                .font(AlbaFont.rounded(16, weight: .medium))
                                .foregroundColor(.albaText)
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.white.opacity(0.5))

                    // MARK: - Language
                    NavigationLink {
                        LanguageSelectionView()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "globe")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.albaAccent)
                                .frame(width: 32)

                            Text(L10n.t(.language, lang))
                                .font(AlbaFont.rounded(16, weight: .medium))
                                .foregroundColor(.albaText)
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.white.opacity(0.5))

                    // MARK: - Journal Security
                    NavigationLink {
                        JournalSecuritySettingsView()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.albaAccent)
                                .frame(width: 32)

                            Text(lang == .es ? "Seguridad del Journal" : "Journal Security")
                                .font(AlbaFont.rounded(16, weight: .medium))
                                .foregroundColor(.albaText)
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.white.opacity(0.5))

                    // MARK: - About
                    NavigationLink {
                        AboutView()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.albaAccent)
                                .frame(width: 32)

                            Text(lang == .es ? "Acerca de" : "About")
                                .font(AlbaFont.rounded(16, weight: .medium))
                                .foregroundColor(.albaText)
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.white.opacity(0.5))

                    // MARK: - Account
                    NavigationLink {
                        accountView
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.albaAccent)
                                .frame(width: 32)

                            Text(lang == .es ? "Cuenta" : "Account")
                                .font(AlbaFont.rounded(16, weight: .medium))
                                .foregroundColor(.albaText)
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.white.opacity(0.5))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert(
                lang == .es ? "¿Eliminar tu cuenta?" : "Delete your account?",
                isPresented: $showDeleteConfirm
            ) {
                Button(lang == .es ? "Cancelar" : "Cancel", role: .cancel) {}
                Button(lang == .es ? "Eliminar todo" : "Delete everything", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text(lang == .es
                     ? "Se eliminarán todos tus datos: conversaciones, evaluaciones, diario y configuración. Esta acción no se puede deshacer."
                     : "All your data will be deleted: conversations, evaluations, diary, and settings. This action cannot be undone.")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.albaText)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(L10n.t(.settings, lang))
                        .font(AlbaFont.serif(20, weight: .bold))
                        .foregroundColor(.albaText)
                }
            }
        }
    }

    private var accountView: some View {
        ZStack {
            Color.albaBackground.ignoresSafeArea()

            List {
                // User info
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.albaAccent.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Text(String(userViewModel.userName.prefix(1)).uppercased())
                                .font(AlbaFont.serif(20, weight: .bold))
                                .foregroundColor(.albaAccent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(userViewModel.userName)
                                .font(AlbaFont.rounded(17, weight: .semibold))
                                .foregroundColor(.albaText)
                            if authManager.isSignedIn {
                                Text("Apple ID")
                                    .font(AlbaFont.rounded(12))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.white.opacity(0.5))

                // Change name
                Section {
                    Button {
                        newName = userViewModel.userName
                        showChangeName = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "pencil")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.albaAccent)
                                .frame(width: 32)
                            Text(lang == .es ? "Cambiar nombre" : "Change name")
                                .font(AlbaFont.rounded(16, weight: .medium))
                                .foregroundColor(.albaText)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listRowBackground(Color.white.opacity(0.5))

                // Delete account
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "trash")
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 32)
                            Text(lang == .es ? "Eliminar cuenta" : "Delete account")
                                .font(AlbaFont.rounded(16, weight: .medium))
                        }
                        .padding(.vertical, 6)
                    }
                } footer: {
                    Text(lang == .es
                         ? "Esto eliminará todos tus datos de forma permanente."
                         : "This will permanently delete all your data.")
                        .font(AlbaFont.rounded(12))
                }
                .listRowBackground(Color.white.opacity(0.5))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(lang == .es ? "Cuenta" : "Account")
                    .font(AlbaFont.serif(20, weight: .bold))
                    .foregroundColor(.albaText)
            }
        }
        .alert(lang == .es ? "Cambiar nombre" : "Change name", isPresented: $showChangeName) {
            TextField(lang == .es ? "Tu nombre" : "Your name", text: $newName)
            Button(lang == .es ? "Guardar" : "Save") {
                let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    userViewModel.userName = trimmed
                    HapticManager.shared.notification(.success)
                }
            }
            Button(lang == .es ? "Cancelar" : "Cancel", role: .cancel) {}
        }
    }

    private func deleteAllData() {
        // Delete all user data
        ConversationStore.shared.deleteAll()
        FriendshipStore.shared.deleteAll()
        JournalEntryStore.shared.deleteAll()
        JournalSecurityManager.shared.removePIN()
        authManager.signOut()

        // Clear UserDefaults
        let keysToRemove = [
            "user_name", "user_gender",
            "has_completed_onboarding", "has_completed_ai_onboarding",
            "hasSeenJournalSecurityPrompt",
            "alba_current_conversation_id", "alba_current_conversation_timestamp",
            "alba_daily_message_count", "alba_daily_message_date",
            "alba_completed_tests_count", "alba_last_review_request_version"
        ]
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }

        // Reset user view model
        userViewModel.userName = ""
        userViewModel.selectedGender = nil
        userViewModel.hasCompletedOnboarding = false
        userViewModel.hasCompletedAIOnboarding = false

        HapticManager.shared.notification(.warning)
        dismiss()
        onDeleteAccount?()
    }
}

// MARK: - Language Selection View
struct LanguageSelectionView: View {
    @EnvironmentObject var languageManager: LanguageManager

    private var lang: AppLanguage { languageManager.language }

    var body: some View {
        ZStack {
            Color.albaBackground
                .ignoresSafeArea()

            List {
                ForEach(AppLanguage.allCases) { appLang in
                    Button {
                        HapticManager.shared.selection()
                        languageManager.language = appLang
                    } label: {
                        HStack {
                            Text(appLang == .es ? L10n.t(.spanish, lang) : L10n.t(.english, lang))
                                .font(AlbaFont.rounded(16, weight: .medium))
                                .foregroundColor(.albaText)

                            Spacer()

                            if languageManager.language == appLang {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.albaAccent)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.white.opacity(0.5))
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(L10n.t(.language, lang))
                    .font(AlbaFont.serif(20, weight: .bold))
                    .foregroundColor(.albaText)
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var logoScale: CGFloat = 0.8

    private var lang: AppLanguage { languageManager.language }

    var body: some View {
        ZStack {
            Color.albaBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 20)

                    // Logo
                    AlbaAvatar(size: 100)
                        .scaleEffect(logoScale)
                        .onAppear {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                logoScale = 1.0
                            }
                        }

                    // App name & version
                    VStack(spacing: 6) {
                        Text("Alba")
                            .font(AlbaFont.serif(32, weight: .heavy))
                            .foregroundColor(.albaText)

                        Text(lang == .es
                             ? "Tu guía para mejorar tus amistades"
                             : "Your guide to better friendships")
                            .font(AlbaFont.rounded(15))
                            .foregroundColor(.albaText.opacity(0.6))
                            .multilineTextAlignment(.center)

                        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                            Text(lang == .es ? "Versión \(version)" : "Version \(version)")
                                .font(AlbaFont.rounded(13))
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                    }

                    // Credits card
                    VStack(alignment: .leading, spacing: 16) {
                        Text(lang == .es ? "Créditos" : "Credits")
                            .font(AlbaFont.serif(20, weight: .bold))
                            .foregroundColor(.albaText)

                        creditRow(
                            role: lang == .es ? "Autora" : "Author",
                            name: "Leslie Maldonado Hernández"
                        )

                        creditRow(
                            role: lang == .es ? "Autor" : "Author",
                            name: "José Manuel Maldonado Roldán"
                        )

                        Divider()
                            .opacity(0.3)

                        creditRow(
                            role: lang == .es ? "Inteligencia artificial" : "Artificial Intelligence",
                            name: "Gemini by Google"
                        )

                        creditRow(
                            role: lang == .es ? "Música" : "Music",
                            name: "Apple Music"
                        )
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.4), lineWidth: 0.8)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
                    .padding(.horizontal, 24)

                    // Positive psychology attribution
                    Text(lang == .es
                         ? "Basada en estudios de psicología positiva"
                         : "Based on positive psychology studies")
                        .font(AlbaFont.rounded(13))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // Academic sources
                    VStack(alignment: .leading, spacing: 10) {
                        Text(lang == .es ? "Fuentes" : "Sources")
                            .font(AlbaFont.serif(16, weight: .bold))
                            .foregroundColor(.albaText)

                        Text("Seligman, M. E. P. (2011). Flourish: A Visionary New Understanding of Happiness and Well-being. Free Press.")
                            .font(AlbaFont.rounded(12))
                            .foregroundColor(.albaText.opacity(0.7))
                            .lineSpacing(3)

                        Text("Demir, M., & Weitekamp, L. A. (2007). I am so happy cause today I found my friend: Friendship and personality as predictors of happiness. Journal of Happiness Studies, 8(2), 181-211.")
                            .font(AlbaFont.rounded(12))
                            .foregroundColor(.albaText.opacity(0.7))
                            .lineSpacing(3)

                        Text("Reis, H. T., Sheldon, K. M., Gable, S. L., Roscoe, J., & Ryan, R. M. (2000). Daily well-being: The role of autonomy, competence, and relatedness. Personality and Social Psychology Bulletin, 26(4), 419-435.")
                            .font(AlbaFont.rounded(12))
                            .foregroundColor(.albaText.opacity(0.7))
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.3), lineWidth: 0.8))
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(lang == .es ? "Acerca de" : "About")
                    .font(AlbaFont.serif(20, weight: .bold))
                    .foregroundColor(.albaText)
            }
        }
    }

    private func creditRow(role: String, name: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(role)
                .font(AlbaFont.rounded(12, weight: .medium))
                .foregroundColor(.albaAccent)
                .textCase(.uppercase)
                .tracking(0.5)

            Text(name)
                .font(AlbaFont.rounded(16, weight: .semibold))
                .foregroundColor(.albaText)
        }
    }
}
