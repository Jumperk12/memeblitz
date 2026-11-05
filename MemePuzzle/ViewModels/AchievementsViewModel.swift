import MemeBlitzCore
import Observation
import SwiftUI

@Observable
@MainActor
public final class AchievementsViewModel {
    public var selectedCategory: AchievementCategory? = nil

    public var profile: GameProfile {
        GameProfile.shared
    }

    public var engine: AchievementEngine {
        AchievementEngine.shared
    }

    public init() {}

    // MARK: - Player Progression Stats

    public var playerLevel: Int {
        profile.playerLevel
    }

    public var totalXP: Int {
        profile.totalXP
    }

    public var levelProgress: Double {
        profile.levelProgress
    }

    public var xpRemainingForNextLevel: Int {
        profile.xpRemainingForNextLevel
    }

    public var totalSolvedCount: Int {
        profile.totalSolvedCount
    }

    public var currentStreak: Int {
        profile.currentStreak
    }

    public var unlockedCount: Int {
        engine.statuses(for: profile).filter(\.isUnlocked).count
    }

    public var totalAchievementCount: Int {
        engine.allAchievements.count
    }

    public var overallProgressFraction: Double {
        guard totalAchievementCount > 0 else { return 0.0 }
        return Double(unlockedCount) / Double(totalAchievementCount)
    }

    // MARK: - Featured Next Trophy

    public var featuredNextAchievement: AchievementStatus? {
        engine.nextFeaturedAchievement(for: profile)
    }

    // MARK: - Categorized Achievements

    public var categories: [AchievementCategory] {
        AchievementCategory.allCases
    }

    public var filteredCategories: [AchievementCategory] {
        if let selected = selectedCategory {
            return [selected]
        }
        return AchievementCategory.allCases
    }

    public func statuses(for category: AchievementCategory) -> [AchievementStatus] {
        engine.statuses(in: category, for: profile)
    }

    public func unlockedCount(in category: AchievementCategory) -> Int {
        statuses(for: category).filter(\.isUnlocked).count
    }

    public func totalCount(in category: AchievementCategory) -> Int {
        statuses(for: category).count
    }

    public func completionFraction(for category: AchievementCategory) -> Double {
        let total = totalCount(in: category)
        guard total > 0 else { return 0.0 }
        return Double(unlockedCount(in: category)) / Double(total)
    }

    public func onTrophiesAppear() {
        engine.evaluateProgress(profile: profile)
    }
}
