import Foundation
import MemePuzzleCore

public struct DailyBlitzManager {
    public static let totalDays = 100

    /// Anchor date for Day 1: November 4, 2026 (today)
    public static let anchorDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 11
        components.day = 4
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    /// Calculates today's Daily Blitz day number (1 ... 100).
    public static var currentDayNumber: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfAnchor = calendar.startOfDay(for: anchorDate)
        let diff = calendar.dateComponents([.day], from: startOfAnchor, to: startOfToday).day ?? 0
        let normalized = (diff % totalDays + totalDays) % totalDays
        return normalized + 1
    }

    /// Date formatted as "yyyy-MM-dd"
    public static var todayDateKey: String {
        formatDate(Date())
    }

    /// Date formatted for yesterday as "yyyy-MM-dd" (used for daily streak continuity)
    public static var yesterdayDateKey: String {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return formatDate(yesterday)
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    /// Seconds remaining until midnight (when next daily puzzle unlocks)
    public static var secondsUntilTomorrow: TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else {
            return 0
        }
        return max(0, tomorrow.timeIntervalSince(now))
    }

    /// Formats countdown string like "08h 24m"
    public static func formattedCountdown(seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%02dh %02dm", hours, minutes)
        } else {
            return String(format: "%02dm %02ds", minutes, secs)
        }
    }

    /// Creates today's Daily Blitz puzzle session locked to Hard mode with a generous 120s timer and a deterministic daily seed.
    public static func makeDailySession() -> PuzzleSession {
        let day = currentDayNumber
        let template = MemeCatalog.dailyTemplate(for: day)
        // Deterministic daily seed so all users solve the exact same board configuration on this day
        let seed = UInt64(day * 7919 + 42)
        let config = try! PuzzleConfiguration(
            rows: 10,
            columns: 10,
            missingTileCount: 32,
            timeLimit: 120,
            mode: .hard
        )
        return PuzzleSession(
            source: .bundled(template),
            configuration: config,
            seed: seed
        )
    }
}
