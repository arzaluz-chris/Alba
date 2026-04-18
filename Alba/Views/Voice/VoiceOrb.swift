import SwiftUI

// MARK: - Orb State
enum VoiceOrbState: Equatable {
    case idle
    case connecting
    case listening
    case speaking
    case paused
}

// MARK: - Voice Orb
/// Animated orb that reacts to the live audio output level. Built with layered
/// Circles inside a `TimelineView(.animation)` so the rings can use continuous
/// time for gentle sine-based motion while the main scale is driven by `audioLevel`.
///
/// - Parameters:
///   - audioLevel: Normalized 0.0–1.0 RMS of the model's currently-playing audio.
///   - state: High-level mode (idle / connecting / listening / speaking / paused)
///            used to pick the accent intensity and tempo.
struct VoiceOrb: View {
    let audioLevel: Float
    let state: VoiceOrbState

    private let orbSize: CGFloat = 220

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            // Smoothed audio drive — clamp and slightly compress to avoid jitter
            let drive = CGFloat(max(0, min(1, audioLevel)))

            ZStack {
                // MARK: Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.albaAccent.opacity(glowOpacity(drive: drive)),
                                Color.albaAccent.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: orbSize
                        )
                    )
                    .frame(width: orbSize * 2.2, height: orbSize * 2.2)
                    .blur(radius: 50)

                // MARK: Expanding rings
                ForEach(0..<3, id: \.self) { index in
                    let phase = elapsed * ringSpeed + Double(index) * 0.6
                    let sine = CGFloat(sin(phase))
                    let baseScale = 1.0 + CGFloat(index + 1) * 0.14
                    let ringScale = baseScale + drive * 0.22 + sine * 0.03

                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.albaAccent.opacity(0.55 - Double(index) * 0.15),
                                    Color.albaAccent.opacity(0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(0.8, 2.2 - CGFloat(index) * 0.6)
                        )
                        .frame(width: orbSize, height: orbSize)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity(drive: drive, index: index))
                }

                // MARK: Base orb
                Circle()
                    .fill(LinearGradient.albaAccentGradient)
                    .frame(width: orbSize, height: orbSize)
                    .scaleEffect(baseScale(drive: drive))
                    .shadow(color: Color.albaAccent.opacity(0.45), radius: 30, x: 0, y: 0)

                // MARK: Inner highlight (glossy top-left)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.45),
                                Color.white.opacity(0.0)
                            ],
                            center: UnitPoint(x: 0.32, y: 0.28),
                            startRadius: 0,
                            endRadius: orbSize * 0.55
                        )
                    )
                    .frame(width: orbSize, height: orbSize)
                    .scaleEffect(baseScale(drive: drive))
                    .blendMode(.plusLighter)

                // MARK: Soft inner rim for depth
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    .frame(width: orbSize, height: orbSize)
                    .scaleEffect(baseScale(drive: drive))
            }
            .animation(.easeOut(duration: 0.12), value: drive)
        }
        .frame(width: orbSize * 2.2, height: orbSize * 2.2)
        .accessibilityLabel("Alba voice orb")
        .accessibilityValue(accessibilityValue)
    }

    // MARK: - Animation tuning per state

    private var ringSpeed: Double {
        switch state {
        case .idle: return 0.7
        case .connecting: return 1.4
        case .listening: return 1.1
        case .speaking: return 1.8
        case .paused: return 0.35
        }
    }

    private func baseScale(drive: CGFloat) -> CGFloat {
        switch state {
        case .idle, .paused:
            return 1.0 + drive * 0.04
        case .connecting:
            return 1.0 + drive * 0.06
        case .listening:
            return 1.0 + drive * 0.10
        case .speaking:
            return 1.0 + drive * 0.14
        }
    }

    private func glowOpacity(drive: CGFloat) -> Double {
        switch state {
        case .idle: return 0.25 + Double(drive) * 0.15
        case .connecting: return 0.35
        case .listening: return 0.40 + Double(drive) * 0.20
        case .speaking: return 0.55 + Double(drive) * 0.30
        case .paused: return 0.18
        }
    }

    private func ringOpacity(drive: CGFloat, index: Int) -> Double {
        let base: Double
        switch state {
        case .idle, .paused: base = 0.25
        case .connecting: base = 0.40
        case .listening: base = 0.50
        case .speaking: base = 0.70
        }
        return max(0.0, base + Double(drive) * 0.25 - Double(index) * 0.12)
    }

    private var accessibilityValue: String {
        switch state {
        case .idle: return "idle"
        case .connecting: return "connecting"
        case .listening: return "listening"
        case .speaking: return "speaking"
        case .paused: return "paused"
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        VoiceOrb(audioLevel: 0.0, state: .idle)
        VoiceOrb(audioLevel: 0.6, state: .speaking)
    }
    .padding()
    .background(Color.black)
}
