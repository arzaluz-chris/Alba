import SwiftUI
import MusicKit
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Alba", category: "MusicSearchView")

struct MusicSearchView: View {
    @EnvironmentObject var musicViewModel: MusicViewModel
    @EnvironmentObject var languageManager: LanguageManager

    @State private var defaultSongs: [Song] = []
    @State private var isLoadingDefaults = false
    @State private var debounceTask: Task<Void, Never>?

    private var language: AppLanguage { languageManager.language }

    var body: some View {
        ZStack {
            Color.albaBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Search bar
                searchBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        if !musicViewModel.isAuthorized {
                            authorizationSection
                        } else if let results = musicViewModel.searchResults,
                                  !musicViewModel.searchQuery.isEmpty {
                            ForEach(results, id: \.id) { song in
                                songRow(song)
                            }
                            if results.isEmpty {
                                noResultsView
                            }
                        } else {
                            defaultPlaylistSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(L10n.t(.music, language))
                    .font(AlbaFont.serif(20, weight: .bold))
                    .foregroundColor(.albaText)
            }
        }
        .task {
            logger.info("🎵 MusicSearchView appeared. Authorized: \(self.musicViewModel.isAuthorized)")
            if !musicViewModel.isAuthorized {
                await musicViewModel.requestAuthorization()
            }
            if musicViewModel.isAuthorized {
                await loadDefaultSongs()
                await musicViewModel.checkSubscription()
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.albaText.opacity(0.5))
                .font(.system(size: 16))

            TextField(L10n.t(.searchMusic, language), text: $musicViewModel.searchQuery)
                .font(AlbaFont.rounded(16))
                .foregroundColor(.albaText)
                .autocorrectionDisabled()
                .onChange(of: musicViewModel.searchQuery) {
                    debounceTask?.cancel()
                    let query = musicViewModel.searchQuery
                    debounceTask = Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        guard !Task.isCancelled else { return }
                        await musicViewModel.search(query: query)
                    }
                }

            if !musicViewModel.searchQuery.isEmpty {
                Button {
                    musicViewModel.searchQuery = ""
                    musicViewModel.searchResults = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.albaText.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .stroke(Color.albaText.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Authorization Section
    private var authorizationSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.house")
                .font(.system(size: 50))
                .foregroundColor(.albaAccent)

            Text(language == .es
                 ? "Alba necesita acceso a Apple Music para reproducir canciones."
                 : "Alba needs access to Apple Music to play songs.")
                .font(AlbaFont.rounded(16))
                .foregroundColor(.albaText.opacity(0.7))
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await musicViewModel.requestAuthorization()
                    if musicViewModel.isAuthorized {
                        await loadDefaultSongs()
                    }
                }
            } label: {
                Text(language == .es ? "Permitir acceso" : "Allow Access")
                    .font(AlbaFont.rounded(16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(LinearGradient.albaAccentGradient)
                    )
                    .shadow(color: Color.albaAccent.opacity(0.3), radius: 12, x: 0, y: 6)
            }
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .glassCard()
    }

    // MARK: - No Results
    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 30))
                .foregroundColor(.gray.opacity(0.4))
            Text(language == .es ? "Sin resultados" : "No results")
                .font(AlbaFont.rounded(16, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Default Playlist
    private var defaultPlaylistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(language == .es ? "Playlist sugerida" : "Suggested Playlist")
                    .font(AlbaFont.serif(20, weight: .bold))
                    .foregroundColor(.albaText)

                Spacer()

                if !defaultSongs.isEmpty {
                    Button {
                        Task {
                            if let first = defaultSongs.first {
                                await musicViewModel.play(song: first)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12))
                            Text(L10n.t(.playAll, language))
                                .font(AlbaFont.rounded(14, weight: .semibold))
                        }
                        .foregroundColor(.albaAccent)
                    }
                }
            }

            if isLoadingDefaults {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.albaAccent)
                        Text(language == .es ? "Cargando canciones..." : "Loading songs...")
                            .font(AlbaFont.rounded(14))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.vertical, 30)
            } else if defaultSongs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 30))
                        .foregroundColor(.gray.opacity(0.4))
                    Text(language == .es
                         ? "No se pudieron cargar las canciones. Verifica tu conexión."
                         : "Couldn't load songs. Check your connection.")
                        .font(AlbaFont.rounded(14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    Button {
                        Task { await loadDefaultSongs() }
                    } label: {
                        Text(language == .es ? "Reintentar" : "Retry")
                            .font(AlbaFont.rounded(14, weight: .semibold))
                            .foregroundColor(.albaAccent)
                    }
                }
                .padding(.vertical, 30)
            } else {
                ForEach(defaultSongs, id: \.id) { song in
                    songRow(song)
                }
            }
        }
    }

    // MARK: - Song Row
    private func songRow(_ song: Song) -> some View {
        Button {
            Task {
                await musicViewModel.play(song: song)
            }
        } label: {
            HStack(spacing: 12) {
                if let artwork = song.artwork {
                    ArtworkImage(artwork, width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.albaAccent.opacity(0.15))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.albaAccent)
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(AlbaFont.rounded(16, weight: .medium))
                        .foregroundColor(isCurrentSong(song) ? .albaAccent : .albaText)
                        .lineLimit(1)

                    Text(song.artistName)
                        .font(AlbaFont.rounded(13))
                        .foregroundColor(.albaText.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer()

                if isCurrentSong(song) && musicViewModel.isPlaying {
                    Image(systemName: "waveform")
                        .foregroundColor(.albaAccent)
                        .font(.system(size: 16))
                        .symbolEffect(.variableColor.iterative)
                } else if isCurrentSong(song) {
                    Image(systemName: "pause.fill")
                        .foregroundColor(.albaAccent)
                        .font(.system(size: 14))
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isCurrentSong(song) ? Color.albaAccent.opacity(0.4) : Color.white.opacity(0.3), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers
    private func isCurrentSong(_ song: Song) -> Bool {
        musicViewModel.currentSong?.id == song.id
    }

    private func loadDefaultSongs() async {
        isLoadingDefaults = true
        logger.info("🎶 Loading default playlist (\(self.musicViewModel.defaultPlaylist.count) songs)...")

        var songs: [Song] = []
        for item in musicViewModel.defaultPlaylist {
            let query = "\(item.title) \(item.artist)"
            do {
                var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
                request.limit = 1
                let response = try await request.response()
                if let song = response.songs.first {
                    songs.append(song)
                    logger.info("  ✅ Found: \(song.title) - \(song.artistName)")
                } else {
                    logger.warning("  ⚠️ Not found: \(item.title) - \(item.artist)")
                }
            } catch {
                logger.error("  ❌ Error searching '\(item.title)': \(error.localizedDescription)")
            }
        }

        defaultSongs = songs
        isLoadingDefaults = false
        logger.info("🎶 Default playlist loaded: \(songs.count)/\(self.musicViewModel.defaultPlaylist.count) songs")
    }
}
