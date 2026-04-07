//
//  AlbaApp.swift
//  Alba
//

import SwiftUI

// MARK: - AppDelegate for Quick Actions
class AlbaAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Handle quick action when app is launched from terminated state
        if let shortcutItem = options.shortcutItem {
            QuickActionManager.shared.handleShortcut(shortcutItem)
        }
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = AlbaSceneDelegate.self
        return config
    }
}

class AlbaSceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        // Handle quick action when app is already running
        QuickActionManager.shared.handleShortcut(shortcutItem)
        completionHandler(true)
    }
}

@main
struct AlbaApp: App {
    @UIApplicationDelegateAdaptor(AlbaAppDelegate.self) var appDelegate

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
                    QuickActionManager.shared.setupShortcuts(lang: languageManager.language)
                }
                .onChange(of: languageManager.language) { newLang in
                    QuickActionManager.shared.setupShortcuts(lang: newLang)
                }
        }
    }
}
