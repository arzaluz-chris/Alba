import Combine
import MusicKit
import SwiftUI
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Alba", category: "MusicViewModel")

@MainActor
final class MusicViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: MusicItemCollection<Song>?
    @Published var currentSong: Song?
    @Published var isPlaying: Bool = false
    @Published var isAuthorized: Bool = false
    @Published var showPlayer: Bool = false

    private let player = ApplicationMusicPlayer.shared

    let defaultPlaylist: [(title: String, artist: String)] = [
        ("Lacy", "Olivia Rodrigo"),
        ("Twilight Zone", "Ariana Grande"),
        ("These Walls", "Dua Lipa"),
        ("Wonderwall", "Oasis"),
        ("Pretty Slowly", "Benson Boone"),
        ("Love Me Anyway", "Chappell Roan")
    ]

    init() {
        let currentStatus = MusicAuthorization.currentStatus
        isAuthorized = currentStatus == .authorized
        logger.info("🎵 MusicViewModel init. Current auth status: \(String(describing: currentStatus))")
    }

    func requestAuthorization() async {
        logger.info("🔐 Requesting MusicKit authorization...")
        let status = await MusicAuthorization.request()
        isAuthorized = status == .authorized
        logger.info("🔐 MusicKit auth result: \(String(describing: status)) → isAuthorized: \(self.isAuthorized)")

        if !isAuthorized {
            logger.warning("⚠️ MusicKit NOT authorized. User denied or restricted.")
        }
    }

    func checkSubscription() async {
        do {
            let subscription = try await MusicSubscription.current
            logger.info("🎫 Apple Music subscription - canPlay: \(subscription.canPlayCatalogContent), canBecomeSubscriber: \(subscription.canBecomeSubscriber)")
        } catch {
            logger.error("❌ Failed to check subscription: \(error.localizedDescription)")
        }
    }

    func search(query: String) async {
        guard !query.isEmpty, isAuthorized else {
            searchResults = nil
            logger.info("🔍 Search skipped. Query empty: \(query.isEmpty), authorized: \(self.isAuthorized)")
            return
        }
        logger.info("🔍 Searching for: '\(query)'...")
        do {
            var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
            request.limit = 20
            let response = try await request.response()
            searchResults = response.songs
            logger.info("✅ Search results: \(response.songs.count) songs found")
            for (i, song) in response.songs.prefix(3).enumerated() {
                logger.info("   [\(i+1)] \(song.title) - \(song.artistName)")
            }
        } catch {
            logger.error("❌ Search failed: \(error.localizedDescription)")
            searchResults = nil
        }
    }

    func play(song: Song) async {
        logger.info("▶️ Playing: \(song.title) by \(song.artistName)")
        do {
            player.queue = [song]
            try await player.play()
            currentSong = song
            isPlaying = true
            showPlayer = true
            logger.info("✅ Playback started successfully")
            HapticManager.shared.mediumImpact()
        } catch {
            logger.error("❌ Playback failed: \(error.localizedDescription)")
            // Check if it's a subscription issue
            await checkSubscription()
        }
    }

    func togglePlayback() {
        if player.state.playbackStatus == .playing {
            player.pause()
            isPlaying = false
            logger.info("⏸️ Paused")
        } else {
            Task {
                do {
                    try await player.play()
                    isPlaying = true
                    logger.info("▶️ Resumed")
                } catch {
                    logger.error("❌ Resume failed: \(error.localizedDescription)")
                }
            }
        }
        HapticManager.shared.lightImpact()
    }

    func skipToNext() async {
        logger.info("⏭️ Skipping to next...")
        do {
            try await player.skipToNextEntry()
            isPlaying = true
            logger.info("✅ Skipped")
        } catch {
            logger.error("❌ Skip failed: \(error.localizedDescription)")
        }
    }

    func stop() {
        player.pause()
        isPlaying = false
        showPlayer = false
        currentSong = nil
        logger.info("⏹️ Stopped and dismissed player")
    }
}
