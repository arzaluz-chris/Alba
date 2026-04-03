import SwiftUI

struct HomeView: View {
    @Binding var currentView: AppState
    @ObservedObject var userViewModel: UserViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var tutorialManager = TutorialManager.shared

    @State private var showSettings = false
    @State private var appeared = false
    @State private var spotlightFrames: [String: CGRect] = [:]

    private var lang: AppLanguage { languageManager.language }

    var body: some View {
        // The ZStack's first child uses .ignoresSafeArea which makes the
        // ZStack fill the full screen. This ensures .global coordinates
        // used by .position() align with the captured frames.
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        HapticManager.shared.lightImpact()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.albaText.opacity(0.6))
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .spotlightAnchor("settings")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(LinearGradient.albaAccentGradient, lineWidth: 2)
                        .frame(width: 110, height: 110)
                        .opacity(0.5)
                    Image("ALBA_LOGO").resizable().scaledToFit().frame(width: 90, height: 90)
                }
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appeared)

                Text(L10n.t(.helloName, lang, userViewModel.userName))
                    .font(AlbaFont.serif(28, weight: .bold))
                    .foregroundColor(.albaText)
                    .padding(.top, 20)
                    .opacity(appeared ? 1 : 0)

                Text(L10n.t(.iAmAlbaWelcome, lang))
                    .font(AlbaFont.rounded(15))
                    .foregroundColor(.albaText.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                VStack(spacing: 14) {
                    GlassActionButton(L10n.t(.albaTest, lang), icon: "checklist", style: .primary) {
                        currentView = .albaTest
                    }
                    .spotlightAnchor("albaTest")
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.4), value: appeared)

                    GlassActionButton(L10n.t(.albaIA, lang), icon: "bubble.left.and.text.bubble.right", style: .primary) {
                        currentView = .chat()
                    }
                    .spotlightAnchor("albaIA")
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.55), value: appeared)

                    GlassActionButton(L10n.t(.albaBlocks, lang), icon: "book.fill", style: .primary) {
                        currentView = .albaBlocks
                    }
                    .spotlightAnchor("albaBlocks")
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.7), value: appeared)

                    GlassActionButton(lang == .es ? "Mi Journal" : "My Journal", icon: "chart.line.uptrend.xyaxis", style: .secondary) {
                        currentView = .journal
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.85), value: appeared)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
            .padding(.top, 54)
            .padding(.bottom, 34)

            // Tutorial overlay - INSIDE ZStack as last child (matches playground)
            if tutorialManager.isActive {
                SpotlightTutorialOverlay(
                    frames: spotlightFrames,
                    lang: lang,
                    mgr: tutorialManager,
                    onNav: { id in
                        switch id {
                        case "albaBlocks": currentView = .albaBlocks
                        case "albaIA": currentView = .chat()
                        case "albaTest": currentView = .albaTest
                        case "settings": showSettings = true
                        default: break
                        }
                    }
                )
            }
        }
        .ignoresSafeArea()
        .onPreferenceChange(SpotlightFramePreference.self) { spotlightFrames = $0 }
        .onAppear {
            withAnimation { appeared = true }
            tutorialManager.startIfFirstTime()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(onDeleteAccount: {
                currentView = .splash
            })
        }
    }
}
