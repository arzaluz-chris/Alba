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
                self.schedulePERMATip()
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
            content.body = "¿Como van tus amistades esta semana? Estoy aqui si necesitas platicar."
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
            content.body = "Ha pasado un mes desde que evaluaste tu amistad con \(friendName). ¿Quieres ver como ha cambiado?"
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

    func schedulePERMATip() {
        let tips = [
            ("es", "Tip PERMA: Las emociones positivas fortalecen los vinculos. Hoy, comparte algo que te hizo sonreir con un amigo."),
            ("en", "PERMA Tip: Positive emotions strengthen bonds. Today, share something that made you smile with a friend."),
            ("es", "Tip PERMA: El compromiso mutuo es clave. ¿Cuando fue la ultima vez que hiciste algo especial por un amigo?"),
            ("en", "PERMA Tip: Mutual engagement is key. When was the last time you did something special for a friend?"),
            ("es", "Tip PERMA: Los limites sanos protegen las amistades. Recuerda: decir 'no' tambien es cuidar la relacion."),
            ("en", "PERMA Tip: Healthy boundaries protect friendships. Remember: saying 'no' is also caring for the relationship."),
        ]

        let isSpanish = Locale.current.language.languageCode?.identifier.hasPrefix("es") == true
        let filtered = tips.filter { $0.0 == (isSpanish ? "es" : "en") }

        for (index, tip) in filtered.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Alba"
            content.body = tip.1
            content.sound = .default

            // Schedule one tip per week, on different days
            var dateComponents = DateComponents()
            dateComponents.weekday = 4 + index // Wed, Thu, Fri
            dateComponents.hour = 18 // 6 PM
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let request = UNNotificationRequest(identifier: "alba_tip_\(index)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
        logger.info("📅 PERMA tips scheduled")
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        logger.info("🗑️ All notifications cancelled")
    }
}
