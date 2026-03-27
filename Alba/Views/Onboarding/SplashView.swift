import SwiftUI

struct SplashView: View {
    @Binding var currentView: AppState
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.9

    var body: some View {
        ZStack {
            Color.albaBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                Image("ALBA_LOGO")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .shadow(color: Color.albaAccent.opacity(0.3), radius: 30, x: 0, y: 15)

                Text("Alba")
                    .font(AlbaFont.serif(28, weight: .heavy))
                    .foregroundColor(.albaText)
            }
            .opacity(opacity)
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1.0
                scale = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    opacity = 0.0
                    scale = 1.05
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation { currentView = .intro }
            }
        }
    }
}
