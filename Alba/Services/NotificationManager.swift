import UserNotifications
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Alba", category: "Notifications")

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                logger.info("✅ Notification permission granted")
                self.scheduleWeeklyReminder()
            } else {
                logger.info("❌ Notification permission denied: \(error?.localizedDescription ?? "none")")
            }
        }
    }

    func scheduleWeeklyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Alba"
        // Will be localized based on device language
        if Locale.current.language.languageCode?.identifier.hasPrefix("es") == true {
            content.body = "¿Cómo van tus amistades esta semana? Estoy aquí si necesitas platicar."
        } else {
            content.body = "How are your friendships this week? I'm here if you need to talk."
        }
        content.sound = .default
        content.categoryIdentifier = "weekly_reminder"

        // Every Monday at 10:00 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = 10
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: "alba_weekly", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("❌ Weekly notification error: \(error.localizedDescription)")
            } else {
                logger.info("📅 Weekly reminder scheduled (Mondays 10AM)")
            }
        }
    }

    func scheduleReEvaluationReminder(friendName: String, afterDays: Int = 30) {
        let content = UNMutableNotificationContent()
        content.title = "Alba"
        if Locale.current.language.languageCode?.identifier.hasPrefix("es") == true {
            content.body = "Ha pasado un mes desde que evaluaste tu amistad con \(friendName). ¿Quieres ver cómo ha cambiado?"
        } else {
            content.body = "It's been a month since you evaluated your friendship with \(friendName). Want to see how it's changed?"
        }
        content.sound = .default
        content.categoryIdentifier = "reevaluate"
        content.userInfo = ["friendName": friendName]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(afterDays * 86400), repeats: false)
        let id = "alba_reeval_\(friendName.lowercased().replacingOccurrences(of: " ", with: "_"))"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("❌ Re-eval notification error: \(error.localizedDescription)")
            } else {
                logger.info("📅 Re-eval reminder scheduled for \(friendName) in \(afterDays) days")
            }
        }
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        logger.info("🗑️ All notifications cancelled")
    }
}
