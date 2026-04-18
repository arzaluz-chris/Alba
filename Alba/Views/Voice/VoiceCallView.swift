import SwiftUI

// MARK: - Voice Call View
/// Full-screen modal presenting the voice conversation with Alba.
/// Minimal ChatGPT-voice-inspired interface: subtle radial background, large
/// orb, timer with label, single pulse indicator, pause (left), end-call (right).
struct VoiceCallView: View {
    @StateObject var viewModel: VoiceCallViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    private var lang: AppLanguage { languageManager.language }

    var body: some View {
        ZStack {
            // Deep, subtly tinted background — more branded than pure black,
            // still keeps focus on the orb.
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top: timer + label
                VStack(spacing: 2) {
                    Text(viewModel.formattedElapsed)
                        .font(AlbaFont.rounded(18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .monospacedDigit()

                    Text(L10n.t(.voiceCallTimerLabel, lang))
                        .font(AlbaFont.rounded(11, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(0.8)
                        .textCase(.uppercase)
                }
                .padding(.top, 20)

                Spacer()

                // MARK: - Orb
                VoiceOrb(
                    audioLevel: viewModel.orbAudioLevel,
                    state: viewModel.orbState
                )

                Spacer()

                // MARK: - Status line (single elegant row, no dot array)
                HStack(spacing: 10) {
                    StatusPulse(active: viewModel.liveService.isUserSpeaking ||
                                       viewModel.liveService.isModelSpeaking)

                    Text(statusText)
                        .font(AlbaFont.rounded(16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.horizontal, 40)
                .animation(.easeInOut(duration: 0.35), value: statusText)
                .padding(.bottom, 40)

                // MARK: - Control bar
                HStack(alignment: .center) {
                    // Pause / Resume (bottom-left)
                    Button {
                        handlePauseTap()
                    } label: {
                        Image(systemName: viewModel.state == .paused ? "play.fill" : "pause.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.10))
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
                        Image(systemName: "phone.down.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 68, height: 68)
                            .background(
                                Circle()
                                    .fill(Color(red: 0.90, green: 0.23, blue: 0.28))
                                    .shadow(color: Color.red.opacity(0.45), radius: 14, y: 4)
                            )
                    }

                    Spacer()

                    // Invisible counter-weight so the end button stays centered
                    Color.clear.frame(width: 60, height: 60)
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 36)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.startCall()
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .ended = newState { dismiss() }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color.black
            RadialGradient(
                colors: [
                    Color.albaAccent.opacity(0.14),
                    Color.albaAccent.opacity(0.02),
                    .black
                ],
                center: .center,
                startRadius: 40,
                endRadius: 700
            )
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
            // "Listening" stays as the honest default so the label doesn't
            // flicker every time the user pauses between words.
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

// MARK: - Status pulse
/// Single soft pulse that glows when there's real audio activity (user or
/// model). Replaces the 4-dot mic meter, which flickered too much.
struct StatusPulse: View {
    let active: Bool

    var body: some View {
        Circle()
            .fill(active ? Color.albaAccent : Color.white.opacity(0.35))
            .frame(width: 8, height: 8)
            .scaleEffect(active ? 1.15 : 1.0)
            .shadow(color: active ? Color.albaAccent.opacity(0.6) : .clear,
                    radius: active ? 6 : 0)
            .animation(.easeInOut(duration: 0.25), value: active)
    }
}
