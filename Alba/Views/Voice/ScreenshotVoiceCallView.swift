import SwiftUI

struct ScreenshotVoiceCallView: View {
    let language: AppLanguage

    private var title: String {
        language == .es ? "Alba está hablando" : "Alba is speaking"
    }

    private var subtitle: String {
        language == .es ? "Llamada de voz" : "Voice call"
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("01:24")
                        .font(AlbaFont.rounded(18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .monospacedDigit()

                    Text(subtitle)
                        .font(AlbaFont.rounded(11, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(0.8)
                        .textCase(.uppercase)
                }
                .padding(.top, 20)

                Spacer()

                VoiceOrb(audioLevel: 0.62, state: .speaking)

                Spacer()

                HStack(spacing: 10) {
                    StatusPulse(active: true)

                    Text(title)
                        .font(AlbaFont.rounded(16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)

                HStack(alignment: .center) {
                    CircleButton(systemName: "pause.fill", size: 60, fontSize: 20)

                    Spacer()

                    CircleButton(
                        systemName: "phone.down.fill",
                        size: 68,
                        fontSize: 26,
                        background: Color(red: 0.90, green: 0.23, blue: 0.28),
                        shadow: Color.red.opacity(0.45)
                    )

                    Spacer()

                    Color.clear.frame(width: 60, height: 60)
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 36)
            }
        }
        .preferredColorScheme(.dark)
    }

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
}

private struct CircleButton: View {
    let systemName: String
    let size: CGFloat
    let fontSize: CGFloat
    var background: Color = Color.white.opacity(0.10)
    var shadow: Color = .clear

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(background)
                    .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 1))
                    .shadow(color: shadow, radius: shadow == .clear ? 0 : 14, y: 4)
            )
    }
}
