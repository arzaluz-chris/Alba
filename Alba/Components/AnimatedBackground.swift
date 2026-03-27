import SwiftUI

// MARK: - Premium Animated Background (adapts to dark mode)
struct AnimatedMeshBackground: View {
    @State private var animate = false
    @Environment(\.colorScheme) private var colorScheme

    private var orbOpacity: Double { colorScheme == .dark ? 0.08 : 0.12 }
    private var secondaryOrbColor: Color {
        colorScheme == .dark
            ? Color(red: 0.4, green: 0.25, blue: 0.2)
            : Color(red: 1.0, green: 0.85, blue: 0.75)
    }

    var body: some View {
        ZStack {
            LinearGradient.albaWarm
                .ignoresSafeArea()

            // Floating orbs
            Circle()
                .fill(Color.albaAccent.opacity(orbOpacity))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: animate ? -120 : -40, y: animate ? -250 : -150)
                .scaleEffect(animate ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animate)

            Circle()
                .fill(secondaryOrbColor.opacity(0.15))
                .frame(width: 350, height: 350)
                .blur(radius: 70)
                .offset(x: animate ? 150 : 80, y: animate ? 280 : 200)
                .scaleEffect(animate ? 0.95 : 1.1)
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animate)

            Ellipse()
                .fill(Color.albaAccent.opacity(colorScheme == .dark ? 0.05 : 0.08))
                .frame(width: 280, height: 200)
                .blur(radius: 50)
                .rotationEffect(.degrees(animate ? 20 : -15))
                .offset(x: animate ? 100 : 50, y: animate ? -200 : -100)
                .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: animate)

            // Subtle grain overlay — less opaque in dark mode
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(colorScheme == .dark ? 0.15 : 0.3)
                .ignoresSafeArea()
        }
        .onAppear { animate = true }
    }
}

// MARK: - Intro Background (adapts to dark mode)
struct IntroAnimatedBackground: View {
    @State private var animate = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color.albaBackground, Color(red: 0.08, green: 0.07, blue: 0.06)]
                    : [Color.albaBackground, .white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.albaAccent.opacity(colorScheme == .dark ? 0.10 : 0.15))
                .frame(width: 260, height: 260)
                .blur(radius: 2)
                .offset(x: animate ? -150 : -60, y: animate ? -220 : -120)
                .scaleEffect(animate ? 1.06 : 0.96)
                .rotationEffect(.degrees(animate ? 18 : -10))
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animate)

            Circle()
                .fill(Color.albaAccent.opacity(colorScheme == .dark ? 0.06 : 0.10))
                .frame(width: 320, height: 320)
                .blur(radius: 4)
                .offset(x: animate ? 160 : 60, y: animate ? 300 : 170)
                .scaleEffect(animate ? 0.98 : 1.08)
                .rotationEffect(.degrees(animate ? -14 : 8))
                .animation(.easeInOut(duration: 7.5).repeatForever(autoreverses: true), value: animate)

            RoundedRectangle(cornerRadius: 44)
                .fill(Color.albaGlass.opacity(0.35))
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(animate ? 16 : -12))
                .blur(radius: 8)
                .offset(x: animate ? 140 : 90, y: animate ? -260 : -170)
                .scaleEffect(animate ? 1.04 : 0.98)
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animate)
        }
        .onAppear { animate = true }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.albaAccent.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .offset(y: phase == CGFloat(index) ? -6 : 0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: phase
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedCorner(radius: 18, corners: [.topLeft, .topRight, .bottomRight]))
        .onAppear { phase = 2 }
    }
}
