//
//  AlbaApp.swift
//  Alba
//

import SwiftUI

@main
struct AlbaApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var musicViewModel = MusicViewModel()

    init() {
        // Request notification permission after a brief delay (after onboarding)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if UserDefaults.standard.bool(forKey: "has_completed_onboarding") {
                NotificationManager.shared.requestPermission()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(languageManager)
                .environmentObject(userViewModel)
                .environmentObject(musicViewModel)
                .task {
                    await RemoteConfigService.shared.fetchConfig()
                }
        }
    }
}
