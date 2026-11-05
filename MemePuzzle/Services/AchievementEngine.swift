import MemePuzzleCore
import SwiftUI

// MARK: - A. Achievement Categories

public enum AchievementCategory: String, CaseIterable, Identifiable, Sendable {
    case puzzleMaster = "Puzzle Master"
    case speedDemon = "Speed Demon"
    case perfectionist = "Perfectionist"
    case collector = "Collector"
    case streakHunter = "Streak Hunter"
    case hardcore = "Hardcore"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .puzzleMaster: return "puzzlepiece.fill"
        case .speedDemon: return "timer"
        case .perfectionist: return "checkmark.seal.fill"
        case .collector: return "photo.stack.fill"
        case .streakHunter: return "flame.fill"
        case .hardcore: return "skull.fill"
        }
    }

    public var accentColor: Color {
        switch self {
        case .puzzleMaster: return Theme.neonViolet
        case .speedDemon: return Theme.neonCyan
        case .perfectionist: return Theme.easyEmerald
        case .collector: return Color(red: 0.96, green: 0.45, blue: 0.71)
        case .streakHunter: return Theme.neonOrange
        case .hardcore: return Theme.extremeCrimson
        }
    }
}

// MARK: - B. Achievement State

public enum AchievementState: Equatable, Sendable {
    case unlocked(Date)
    case inProgress(current: Int, target: Int)
    case locked
}

// MARK: - C. Achievement Definition & Status

public struct AchievementDefinition: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let category: AchievementCategory
    public let icon: String
    public let accentColor: Color
    public let targetValue: Int
    public let xpReward: Int

    public init(
        id: String,
        title: String,
        description: String,
        category: AchievementCategory,
        icon: String,
        accentColor: Color,
        targetValue: Int,
        xpReward: Int = 100
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.icon = icon
        self.accentColor = accentColor
        self.targetValue = targetValue
        self.xpReward = xpReward
    }
}

public struct AchievementStatus: Identifiable, Sendable {
    public let definition: AchievementDefinition
    public let isUnlocked: Bool
    public let unlockDate: Date?
    public let currentProgress: Int
    public let targetProgress: Int

    public var id: String { definition.id }
    public var title: String { definition.title }
    public var description: String { definition.description }
    public var category: AchievementCategory { definition.category }
    public var icon: String { definition.icon }
    public var accentColor: Color { definition.accentColor }
    public var xpReward: Int { definition.xpReward }

    public var state: AchievementState {
        if isUnlocked {
            return .unlocked(unlockDate ?? Date())
        } else if currentProgress > 0 {
            return .inProgress(current: currentProgress, target: targetProgress)
        } else {
            return .locked
        }
    }

    public var progressFraction: Double {
        if isUnlocked { return 1.0 }
        guard targetProgress > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(currentProgress) / Double(targetProgress)))
    }
}

// MARK: - D. Achievement Engine

public final class AchievementEngine: @unchecked Sendable {
    public static let shared = AchievementEngine()

    public let allAchievements: [AchievementDefinition] = [
        // 1. Puzzle Master
        AchievementDefinition(
            id: "first_blitz",
            title: "First Spark",
            description: "Solve your very first meme puzzle.",
            category: .puzzleMaster,
            icon: "bolt.fill",
            accentColor: Theme.neonGold,
            targetValue: 1,
            xpReward: 100
        ),
        AchievementDefinition(
            id: "puzzle_novice",
            title: "Novice Solver",
            description: "Complete 5 meme puzzles across any mode.",
            category: .puzzleMaster,
            icon: "puzzlepiece.fill",
            accentColor: Theme.neonViolet,
            targetValue: 5,
            xpReward: 150
        ),
        AchievementDefinition(
            id: "puzzle_artisan",
            title: "Puzzle Artisan",
            description: "Complete 25 meme puzzles.",
            category: .puzzleMaster,
            icon: "sparkles",
            accentColor: Theme.neonViolet,
            targetValue: 25,
            xpReward: 300
        ),
        AchievementDefinition(
            id: "puzzle_grandmaster",
            title: "Grandmaster",
            description: "Conquer 50 puzzles across all difficulty tiers.",
            category: .puzzleMaster,
            icon: "crown.fill",
            accentColor: Theme.neonGold,
            targetValue: 50,
            xpReward: 600
        ),

        // 2. Speed Demon
        AchievementDefinition(
            id: "speed_demon",
            title: "Speed Demon",
            description: "Complete a puzzle with over 30s remaining.",
            category: .speedDemon,
            icon: "timer",
            accentColor: Theme.neonCyan,
            targetValue: 1,
            xpReward: 120
        ),
        AchievementDefinition(
            id: "speed_sub45",
            title: "Lightning Reflexes",
            description: "Solve any puzzle in under 45 seconds.",
            category: .speedDemon,
            icon: "flame.fill",
            accentColor: Theme.neonCyan,
            targetValue: 1,
            xpReward: 180
        ),
        AchievementDefinition(
            id: "speed_sub20",
            title: "Blitz Overdrive",
            description: "Solve a Medium or higher puzzle in under 20 seconds.",
            category: .speedDemon,
            icon: "hare.fill",
            accentColor: Theme.neonGold,
            targetValue: 1,
            xpReward: 350
        ),

        // 3. Perfectionist
        AchievementDefinition(
            id: "flawless",
            title: "Flawless Victory",
            description: "Complete a puzzle with zero incorrect tile placements.",
            category: .perfectionist,
            icon: "checkmark.seal.fill",
            accentColor: Theme.easyEmerald,
            targetValue: 1,
            xpReward: 150
        ),
        AchievementDefinition(
            id: "surgical_precision",
            title: "Surgical Precision",
            description: "Achieve 3 flawless puzzle solves.",
            category: .perfectionist,
            icon: "diamond.fill",
            accentColor: Theme.easyEmerald,
            targetValue: 3,
            xpReward: 300
        ),

        // 4. Collector
        AchievementDefinition(
            id: "vault_explorer",
            title: "Vault Explorer",
            description: "Browse the curated Meme Vault collection.",
            category: .collector,
            icon: "photo.stack.fill",
            accentColor: Color(red: 0.96, green: 0.45, blue: 0.71),
            targetValue: 1,
            xpReward: 80
        ),
        AchievementDefinition(
            id: "collector_10",
            title: "Meme Connoisseur",
            description: "Unlock and restore 10 unique meme puzzles.",
            category: .collector,
            icon: "square.grid.2x2.fill",
            accentColor: Color(red: 0.96, green: 0.45, blue: 0.71),
            targetValue: 10,
            xpReward: 200
        ),
        AchievementDefinition(
            id: "collector_25",
            title: "Culture Curator",
            description: "Unlock and restore 25 unique meme puzzles.",
            category: .collector,
            icon: "sparkles.rectangle.stack.fill",
            accentColor: Color(red: 0.96, green: 0.45, blue: 0.71),
            targetValue: 25,
            xpReward: 400
        ),
        AchievementDefinition(
            id: "meme_master",
            title: "Meme God",
            description: "Restore all curated memes in the entire catalog.",
            category: .collector,
            icon: "star.circle.fill",
            accentColor: Theme.neonGold,
            targetValue: 100,
            xpReward: 1000
        ),

        // 5. Streak Hunter
        AchievementDefinition(
            id: "streak_3",
            title: "On A Roll",
            description: "Achieve a 3-puzzle solving streak.",
            category: .streakHunter,
            icon: "flame",
            accentColor: Theme.neonOrange,
            targetValue: 3,
            xpReward: 150
        ),
        AchievementDefinition(
            id: "streak_5",
            title: "Blazing Trail",
            description: "Achieve a 5-puzzle solving streak.",
            category: .streakHunter,
            icon: "flame.fill",
            accentColor: Theme.neonOrange,
            targetValue: 5,
            xpReward: 300
        ),
        AchievementDefinition(
            id: "streak_10",
            title: "Unstoppable Force",
            description: "Achieve a 10-puzzle solving streak.",
            category: .streakHunter,
            icon: "bolt.heart.fill",
            accentColor: Theme.neonGold,
            targetValue: 10,
            xpReward: 600
        ),

        // 6. Hardcore
        AchievementDefinition(
            id: "galaxy_brain",
            title: "Galaxy Brain",
            description: "Conquer a Hard 10×10 puzzle before time expires.",
            category: .hardcore,
            icon: "brain.head.profile",
            accentColor: Theme.hardMagenta,
            targetValue: 1,
            xpReward: 250
        ),
        AchievementDefinition(
            id: "extreme_champion",
            title: "Apex Legend",
            description: "Triumph over an Extreme Hard 48-piece puzzle.",
            category: .hardcore,
            icon: "skull.fill",
            accentColor: Theme.extremeCrimson,
            targetValue: 1,
            xpReward: 500
        ),
        AchievementDefinition(
            id: "second_wind",
            title: "Second Wind",
            description: "Watch a rewarded ad to continue and claim victory.",
            category: .hardcore,
            icon: "play.tv.fill",
            accentColor: Theme.neonViolet,
            targetValue: 1,
            xpReward: 100
        ),
    ]

    public func statuses(for profile: GameProfile) -> [AchievementStatus] {
        allAchievements.map { status(for: $0, profile: profile) }
    }

    public func statuses(in category: AchievementCategory, for profile: GameProfile) -> [AchievementStatus] {
        allAchievements
            .filter { $0.category == category }
            .map { status(for: $0, profile: profile) }
    }

    public func status(for def: AchievementDefinition, profile: GameProfile) -> AchievementStatus {
        let isAlreadyUnlocked = profile.unlockedAchievementIDs.contains(def.id)
        let unlockDate = profile.achievementUnlockDates[def.id]
        let currentProgress = calculateProgress(for: def, profile: profile)

        return AchievementStatus(
            definition: def,
            isUnlocked: isAlreadyUnlocked || currentProgress >= def.targetValue,
            unlockDate: unlockDate,
            currentProgress: isAlreadyUnlocked ? def.targetValue : currentProgress,
            targetProgress: def.targetValue
        )
    }

    public func nextFeaturedAchievement(for profile: GameProfile) -> AchievementStatus? {
        let allStatuses = statuses(for: profile)
        let pending = allStatuses.filter { !$0.isUnlocked }

        // Prefer in-progress achievements sorted by highest progress percentage
        if let bestInProgress = pending.filter({ $0.currentProgress > 0 }).max(by: { $0.progressFraction < $1.progressFraction }) {
            return bestInProgress
        }

        return pending.first
    }

    // MARK: - Progress Calculations

    public func calculateProgress(for def: AchievementDefinition, profile: GameProfile) -> Int {
        switch def.id {
        case "first_blitz":
            return min(def.targetValue, profile.totalSolvedCount)
        case "puzzle_novice", "puzzle_artisan", "puzzle_grandmaster":
            return min(def.targetValue, profile.totalSolvedCount)
        case "collector_10", "collector_25":
            return min(def.targetValue, profile.completedMemeIDs.count)
        case "meme_master":
            return min(def.targetValue, profile.completedMemeIDs.count)
        case "streak_3", "streak_5", "streak_10":
            return min(def.targetValue, max(profile.currentStreak, profile.highestStreak))
        case "speed_demon", "speed_sub45", "speed_sub20", "flawless", "surgical_precision", "vault_explorer", "galaxy_brain", "extreme_champion", "second_wind":
            return profile.unlockedAchievementIDs.contains(def.id) ? def.targetValue : 0
        default:
            return profile.unlockedAchievementIDs.contains(def.id) ? def.targetValue : 0
        }
    }

    /// Evaluates all achievements after a gameplay event and unlocks any newly earned ones.
    public func evaluateProgress(profile: GameProfile) {
        for def in allAchievements {
            guard !profile.unlockedAchievementIDs.contains(def.id) else { continue }
            let progress = calculateProgress(for: def, profile: profile)
            if progress >= def.targetValue {
                profile.unlock(def.id)
                profile.addXP(def.xpReward)
            }
        }
    }
}
