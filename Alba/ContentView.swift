//
//  ContentView.swift
//  Alba
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var musicViewModel: MusicViewModel

    @State private var currentView: AppState = .splash

    var body: some View {
        ZStack {
            Color.albaBackground
                .ignoresSafeArea()

            mainContent
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .animation(.easeInOut(duration: 0.35), value: currentView)

            if shouldShowMiniPlayer {
                VStack {
                    Spacer()
                    MiniPlayerView()
                        .padding(.bottom, 8)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .onAppear {
            if userViewModel.hasCompletedOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
                    if currentView == .intro || currentView == .signIn || currentView == .onboarding {
                        currentView = .welcome
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch currentView {
        case .splash:
            SplashView(currentView: $currentView)
        case .intro:
            IntroView(currentView: $currentView)
        case .signIn:
            SignInView(currentView: $currentView)
        case .onboarding:
            OnboardingChatView(currentView: $currentView, userViewModel: userViewModel)
        case .welcome:
            HomeView(currentView: $currentView, userViewModel: userViewModel)
        case .chat(let context):
            ChatView(currentView: $currentView, userViewModel: userViewModel, initialContext: context)
        case .albaTest:
            AlbaTestView(currentView: $currentView, viewModel: TestViewModel(userViewModel: userViewModel), userViewModel: userViewModel)
        case .reEvaluate(let friendName, let friendGender):
            let vm = TestViewModel(userViewModel: userViewModel)
            AlbaTestView(currentView: $currentView, viewModel: vm, userViewModel: userViewModel)
                .onAppear { vm.setupReEvaluation(friendName: friendName, friendGender: friendGender) }
        case .albaBlocks:
            AlbaBlocksView(currentView: $currentView)
        case .journal:
            NavigationStack {
                JournalView(currentView: $currentView)
            }
        }
    }

    private var shouldShowMiniPlayer: Bool {
        musicViewModel.showPlayer &&
        currentView != .splash &&
        currentView != .intro &&
        currentView != .signIn &&
        currentView != .onboarding
    }
}
