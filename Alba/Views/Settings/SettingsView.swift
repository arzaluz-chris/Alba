import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var musicViewModel: MusicViewModel
    @Environment(\.dismiss) private var dismiss

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
                }
                .scrollContentBackground(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
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
                             ? "Tu guia para mejorar tus amistades"
                             : "Your guide to better friendships")
                            .font(AlbaFont.rounded(15))
                            .foregroundColor(.albaText.opacity(0.6))
                            .multilineTextAlignment(.center)

                        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                            Text(lang == .es ? "Version \(version)" : "Version \(version)")
                                .font(AlbaFont.rounded(13))
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                    }

                    // Credits card
                    VStack(alignment: .leading, spacing: 16) {
                        Text(lang == .es ? "Creditos" : "Credits")
                            .font(AlbaFont.serif(20, weight: .bold))
                            .foregroundColor(.albaText)

                        creditRow(
                            role: lang == .es ? "Autora" : "Author",
                            name: "Leslie Maldonado Hernandez"
                        )

                        creditRow(
                            role: lang == .es ? "Autor" : "Author",
                            name: "Jose Manuel Maldonado Roldan"
                        )

                        Divider()
                            .opacity(0.3)

                        creditRow(
                            role: lang == .es ? "Inteligencia artificial" : "Artificial Intelligence",
                            name: "Gemini by Google"
                        )

                        creditRow(
                            role: lang == .es ? "Musica" : "Music",
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

                    // PERMA attribution
                    VStack(spacing: 8) {
                        Text(lang == .es
                             ? "Basada en el modelo PERMA de Martin Seligman"
                             : "Based on Martin Seligman's PERMA model")
                            .font(AlbaFont.rounded(13))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)

                        Text(lang == .es
                             ? "Hecha con amor en Mexico"
                             : "Made with love in Mexico")
                            .font(AlbaFont.rounded(13, weight: .medium))
                            .foregroundColor(.albaAccent.opacity(0.7))
                    }
                    .padding(.horizontal, 40)

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
