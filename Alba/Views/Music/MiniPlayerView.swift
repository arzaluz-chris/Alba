//
//  MiniPlayerView.swift
//  Alba
//

import SwiftUI
import MusicKit

struct MiniPlayerView: View {
    @EnvironmentObject var musicViewModel: MusicViewModel

    @State private var dragOffset: CGFloat = 0
    @State private var playerPosition: PlayerPosition = .bottom

    private enum PlayerPosition {
        case top, bottom
    }

    var body: some View {
        if musicViewModel.showPlayer, let song = musicViewModel.currentSong {
            playerContent(song: song)
                .offset(y: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.height
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 100
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                if value.translation.height < -threshold {
                                    playerPosition = .top
                                } else if value.translation.height > threshold {
                                    playerPosition = .bottom
                                }
                                dragOffset = 0
                            }
                        }
                )
                .frame(maxHeight: .infinity, alignment: playerPosition == .top ? .top : .bottom)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: playerPosition)
        }
    }

    // MARK: - Player Content

    private func playerContent(song: Song) -> some View {
        HStack(spacing: 12) {
            // Artwork thumbnail
            if let artwork = song.artwork {
                ArtworkImage(artwork, width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.albaAccent.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.albaAccent)
                            .font(.system(size: 14))
                    )
            }

            // Song info
            VStack(alignment: .leading, spacing: 1) {
                Text(song.title)
                    .font(AlbaFont.rounded(14, weight: .medium))
                    .foregroundColor(.albaText)
                    .lineLimit(1)

                Text(song.artistName)
                    .font(AlbaFont.rounded(12))
                    .foregroundColor(.albaText.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer()

            // Controls
            HStack(spacing: 16) {
                // Play/Pause
                Button {
                    musicViewModel.togglePlayback()
                } label: {
                    Image(systemName: musicViewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.albaText)
                        .frame(width: 32, height: 32)
                }

                // Skip
                Button {
                    Task {
                        await musicViewModel.skipToNext()
                    }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.albaText.opacity(0.7))
                        .frame(width: 28, height: 28)
                }

                // Close
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        musicViewModel.stop()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.albaText.opacity(0.5))
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .overlay(
            Capsule()
                .stroke(Color.albaText.opacity(0.08), lineWidth: 1)
        )
    }
}
