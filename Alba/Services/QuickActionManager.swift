//
//  QuickActionManager.swift
//  Alba
//

import UIKit

final class QuickActionManager: ObservableObject {
    static let shared = QuickActionManager()

    @Published var pendingAction: AppState?

    private init() {}

    // MARK: - Register dynamic shortcuts

    func setupShortcuts(lang: AppLanguage) {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: "com.alba.test",
                localizedTitle: L10n.t(.albaTest, lang),
                localizedSubtitle: L10n.t(.quickActionTestSubtitle, lang),
                icon: UIApplicationShortcutIcon(systemImageName: "checklist")
            ),
            UIApplicationShortcutItem(
                type: "com.alba.chat",
                localizedTitle: L10n.t(.albaIA, lang),
                localizedSubtitle: L10n.t(.quickActionChatSubtitle, lang),
                icon: UIApplicationShortcutIcon(systemImageName: "bubble.left.and.text.bubble.right")
            ),
            UIApplicationShortcutItem(
                type: "com.alba.blocks",
                localizedTitle: L10n.t(.albaBlocks, lang),
                localizedSubtitle: L10n.t(.quickActionBlocksSubtitle, lang),
                icon: UIApplicationShortcutIcon(systemImageName: "book.fill")
            ),
            UIApplicationShortcutItem(
                type: "com.alba.journal",
                localizedTitle: lang == .es ? "Mi Journal" : "My Journal",
                localizedSubtitle: L10n.t(.quickActionJournalSubtitle, lang),
                icon: UIApplicationShortcutIcon(systemImageName: "chart.line.uptrend.xyaxis")
            )
        ]
    }

    // MARK: - Handle shortcut

    func handleShortcut(_ item: UIApplicationShortcutItem) {
        guard UserDefaults.standard.bool(forKey: "has_completed_onboarding") else { return }

        switch item.type {
        case "com.alba.test":
            pendingAction = .albaTest
        case "com.alba.chat":
            pendingAction = .chat()
        case "com.alba.blocks":
            pendingAction = .albaBlocks
        case "com.alba.journal":
            pendingAction = .journal
        default:
            break
        }
    }
}
