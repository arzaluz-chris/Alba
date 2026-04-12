import SwiftUI

// MARK: - Voice Call View
/// Full-screen modal presenting the voice conversation with Alba.
/// Follows the design from the reference image: black background, large orb,
/// timer and status text, mic-level dots, pause (bottom-left), end-call (center).
struct VoiceCallView: View {
    @StateObject var viewModel: VoiceCallViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    private var lang: AppLanguage { languageManager.language }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top: timer
                Text(viewModel.formattedElapsed)
                    .font(AlbaFont.rounded(16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))
                    .monospacedDigit()
                    .padding(.top, 16)

                Spacer()

                // MARK: - Orb
                VoiceOrb(
                    audioLevel: viewModel.orbAudioLevel,
                    state: viewModel.orbState
                )

                Spacer()

                // MARK: - Status + mic dots
                VStack(spacing: 14) {
                    MicLevelDots(level: CGFloat(viewModel.liveService.inputAudioLevel))

                    Text(statusText)
                        .font(AlbaFont.rounded(16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.state)
                }
                .padding(.bottom, 36)

                // MARK: - Control bar
                HStack(alignment: .center) {
                    // Pause / Resume (bottom-left)
                    Button {
                        handlePauseTap()
                    } label: {
                        Image(systemName: viewModel.state == .paused ? "play.fill" : "pause.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 1))
                            )
                    }
                    .disabled(!canPause)
                    .opacity(canPause ? 1 : 0.35)

                    Spacer()

                    // End call (bottom-center)
                    Button {
                        Task { await endAndDismiss() }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 72, height: 72)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(0.82))
                                    .shadow(color: Color.red.opacity(0.5), radius: 14, y: 4)
                            )
                    }

                    Spacer()

                    // Invisible counter-weight so the end button stays centered
                    Color.clear.frame(width: 56, height: 56)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 42)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.startCall()
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .ended = newState { dismiss() }
            if case .permissionDenied = newState { /* shown inline */ }
        }
    }

    private var canPause: Bool {
        switch viewModel.state {
        case .active, .paused: return true
        default: return false
        }
    }

    private var statusText: String {
        switch viewModel.state {
        case .idle, .requestingPermission:
            return L10n.t(.voiceCallConnecting, lang)
        case .connecting:
            return L10n.t(.voiceCallConnecting, lang)
        case .permissionDenied:
            return L10n.t(.voiceCallMicPermissionDenied, lang)
        case .active:
            // Only flip between 2 states: Alba speaking, or Alba listening.
            // We intentionally do NOT react to `isUserSpeaking` here because it
            // toggles every time the user pauses between words, producing
            // rapid flicker. "Alba is listening" is the honest default
            // whenever the model isn't talking.
            if viewModel.liveService.isModelSpeaking {
                return L10n.t(.voiceCallAlbaSpeaking, lang)
            }
            return L10n.t(.voiceCallAlbaListening, lang)
        case .paused:
            return L10n.t(.voiceCallPaused, lang)
        case .ending:
            return L10n.t(.voiceCallEndButton, lang)
        case .ended:
            return ""
        case .failed(let msg):
            return msg
        }
    }

    private func handlePauseTap() {
        if viewModel.state == .active {
            viewModel.pause()
        } else if viewModel.state == .paused {
            viewModel.resume()
        }
    }

    private func endAndDismiss() async {
        await viewModel.endCall(reason: .user)
        // onChange handler above dismisses once state hits .ended; fallback:
        dismiss()
    }
}

// MARK: - Mic level dots
/// 4 stacked dots that pulse with the user's current mic RMS (0-1).
struct MicLevelDots: View {
    let level: CGFloat

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "mic.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .padding(.trailing, 4)

            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(dotOpacity(index: index)))
                    .frame(width: 6, height: 6)
                    .scaleEffect(dotScale(index: index))
                    .animation(.easeOut(duration: 0.15), value: level)
            }
        }
    }

    private func threshold(index: Int) -> CGFloat {
        // Dot 0 activates first (low level), dot 3 needs strong signal.
        return CGFloat(index + 1) * 0.18
    }

    private func dotOpacity(index: Int) -> Double {
        level >= threshold(index: index) ? 1.0 : 0.22
    }

    private func dotScale(index: Int) -> CGFloat {
        level >= threshold(index: index) ? 1.15 : 1.0
    }
}
