import Foundation
import SwiftUI
import UserNotifications

/// Manages local notifications for re-engaging players who haven't played in at least a day.
/// Schedules rotating competitive meme quotes to challenge their leaderboard ranks and streaks.
@MainActor
public final class NotificationManager: ObservableObject {
    public static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let notificationPrefix = "memeblitz_inactivity_"
    private let userDefaultsKey = "hasPromptedForNotifications"

    @Published public var showNotificationPrompt: Bool = false

    /// Competitive, punchy notification quotes to motivate the player to jump back in.
    private let competitiveQuotes: [(title: String, body: String)] = [
        (
            "Someone's beating your time! ⏱️",
            "Your leaderboard rank is slipping! Jump in now and reclaim your fastest solve time."
        ),
        (
            "Your Daily Streak is on the line! 🔥",
            "Don't let your solving streak reset to 0. One quick puzzle keeps your crown intact!"
        ),
        (
            "Meme gods don't take days off 👑",
            "Think you can conquer today's puzzle in under 20 seconds? Prove it."
        ),
        (
            "Are your reflexes slipping? ⚡",
            "The leaderboards are moving without you. Show them who's boss!"
        ),
        (
            "Your brain cells miss you 🧠",
            "Today's Daily Blitz puzzle just dropped. Go set an unbeatable record!"
        ),
        (
            "48-Piece Extreme is laughing at you 💀",
            "Triumph over the hardest puzzle tier and earn the Apex Legend achievement!"
        ),
        (
            "A rival just climbed the ranks! 🏆",
            "Take back your #1 spot on the global leaderboards before it's too late."
        ),
        (
            "The memes won't solve themselves! 🧩",
            "New puzzles are waiting in the Vault. Flex your lightning blitz speed today."
        ),
        (
            "Don't let your streak freeze! ❄️",
            "You were on a roll! Solve one quick meme to keep your fire burning."
        ),
        (
            "Speed Demon challenge! 🚀",
            "Can you solve a Medium or Hard puzzle before the timer hits 30s?"
        )
    ]

    private init() {}

    // MARK: - Prompt & Authorization

    /// Checks if we should display the in-app pre-permission prompt.
    public func checkAndPromptIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: userDefaultsKey) else { return }
        center.getNotificationSettings { settings in
            Task { @MainActor in
                if settings.authorizationStatus == .notDetermined {
                    self.showNotificationPrompt = true
                } else {
                    UserDefaults.standard.set(true, forKey: self.userDefaultsKey)
                    GameProfile.shared.notificationsEnabled = (settings.authorizationStatus == .authorized)
                }
            }
        }
    }

    /// User tapped "Allow Notifications" on the prompt card.
    public func allowNotifications() {
        showNotificationPrompt = false
        UserDefaults.standard.set(true, forKey: userDefaultsKey)

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            Task { @MainActor in
                GameProfile.shared.notificationsEnabled = granted
                if granted {
                    self.scheduleInactivityReminders()
                } else {
                    self.cancelAllReminders()
                }
            }
        }
    }

    /// User tapped "Don't Allow" on the prompt card.
    public func denyNotifications() {
        showNotificationPrompt = false
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
        GameProfile.shared.notificationsEnabled = false
        cancelAllReminders()
    }

    // MARK: - Scheduling

    /// Schedules rotating competitive notifications for 1 day, 2 days, 3 days, and 5 days of inactivity.
    public func scheduleInactivityReminders() {
        guard GameProfile.shared.notificationsEnabled else {
            cancelAllReminders()
            return
        }

        // Cancel previous pending reminders before re-scheduling
        cancelAllReminders()

        // Days to schedule: 1 day (24h), 2 days (48h), 3 days (72h), 5 days (120h)
        let reminderDelays: [(days: Double, idSuffix: String)] = [
            (1.0, "day1"),
            (2.0, "day2"),
            (3.0, "day3"),
            (5.0, "day5")
        ]

        var shuffledQuotes = competitiveQuotes.shuffled()

        for (index, item) in reminderDelays.enumerated() {
            let quote = shuffledQuotes[index % shuffledQuotes.count]
            let content = UNMutableNotificationContent()
            content.title = quote.title
            content.body = quote.body
            content.sound = .default
            content.badge = 1

            // Trigger after specified days (in seconds)
            let timeInterval = item.days * 86400
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

            let request = UNNotificationRequest(
                identifier: "\(notificationPrefix)\(item.idSuffix)",
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                #if DEBUG
                if let error {
                    print("[NotificationManager] Error scheduling \(item.idSuffix): \(error)")
                }
                #endif
            }
        }
    }

    /// Cancels all pending inactivity reminders (called whenever the player opens or plays the app).
    public func cancelAllReminders() {
        let identifiers = ["day1", "day2", "day3", "day5"].map { "\(notificationPrefix)\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        // Reset badge count to 0 when user opens the app
        center.setBadgeCount(0) { _ in }
    }
}
