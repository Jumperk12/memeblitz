import Foundation
import GameKit
import SwiftUI
import UIKit

/// Manages Apple Game Center authentication, leaderboards, and native achievement syncing.
///
/// Designed to follow Apple GameKit best practices:
/// - Authenticates seamlessly via `GKLocalPlayer.local.authenticateHandler`.
/// - Submits high scores, fastest solve times, and daily streaks to Game Center leaderboards.
/// - Syncs in-game trophy unlocks directly to Game Center achievements with native banners.
/// - Presents native `GKGameCenterViewController` with zero boilerplate.
@MainActor
public final class GameCenterManager: NSObject, ObservableObject, GKGameCenterControllerDelegate, @unchecked Sendable {
    public static let shared = GameCenterManager()

    // MARK: - Leaderboard ID Constants (Configure these in App Store Connect)

    public enum LeaderboardID {
        /// Integer: Consecutive days of Daily Blitz completed (High to Low)
        public static let dailyStreak = "daily_blitz_streak"
        /// Elapsed Time (ms): Fastest solve time in Hard Mode (Low to High)
        public static let fastestHard = "fastest_hard_time"
        /// Elapsed Time (ms): Fastest solve time for Daily Blitz (Low to High)
        public static let fastestDaily = "fastest_daily_blitz"
        /// Integer: Total meme puzzles solved across all modes (High to Low)
        public static let totalSolved = "total_puzzles_solved"
        /// Integer: Cumulative player XP earned (High to Low)
        public static let playerXP = "arcade_player_xp"
    }

    // MARK: - Published State

    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var localPlayerName: String = ""

    private var hasConfiguredAuthHandler = false

    private override init() {
        super.init()
    }

    // MARK: - Authentication

    /// Authenticates the local player with Game Center.
    /// Should be called on app launch from `MemePuzzleApp` or `RootView.onAppear`.
    public func authenticateLocalPlayer() {
        guard !hasConfiguredAuthHandler else { return }
        hasConfiguredAuthHandler = true

        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }

                if let vc = viewController {
                    // Player has not yet enabled Game Center or needs to confirm; present system sheet
                    self.getTopViewController()?.present(vc, animated: true)
                } else if GKLocalPlayer.local.isAuthenticated {
                    self.isAuthenticated = true
                    self.localPlayerName = GKLocalPlayer.local.displayName
                    #if DEBUG
                    print("🎮 GameCenter: Authenticated as \(GKLocalPlayer.local.displayName) (ID: \(GKLocalPlayer.local.gamePlayerID))")
                    #endif
                } else {
                    self.isAuthenticated = false
                    self.localPlayerName = ""
                    #if DEBUG
                    if let error {
                        print("🎮 GameCenter: Authentication unavailable: \(error.localizedDescription)")
                    }
                    #endif
                }
            }
        }
    }

    // MARK: - Leaderboard Score Submission

    /// Submits a raw integer score to the specified leaderboard.
    public func submitScore(_ score: Int, leaderboardID: String) {
        guard GKLocalPlayer.local.isAuthenticated else { return }

        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [leaderboardID]
                )
                #if DEBUG
                print("🎮 GameCenter: Submitted score \(score) to '\(leaderboardID)'")
                #endif
            } catch {
                #if DEBUG
                print("🎮 GameCenter: Score submission failed for '\(leaderboardID)': \(error.localizedDescription)")
                #endif
            }
        }
    }

    /// Submits elapsed time in milliseconds to a time-based leaderboard.
    public func submitTime(seconds: Double, leaderboardID: String) {
        guard seconds > 0 else { return }
        // App Store Connect elapsed time format expects integer centiseconds or milliseconds
        let scoreMs = Int(seconds * 1000)
        submitScore(scoreMs, leaderboardID: leaderboardID)
    }

    // MARK: - Convenience Game Submissions

    public func submitDailyStreak(_ streak: Int) {
        guard streak > 0 else { return }
        submitScore(streak, leaderboardID: LeaderboardID.dailyStreak)
    }

    public func submitDailySolveTime(_ seconds: Double) {
        submitTime(seconds: seconds, leaderboardID: LeaderboardID.fastestDaily)
    }

    public func submitHardSolveTime(_ seconds: Double) {
        submitTime(seconds: seconds, leaderboardID: LeaderboardID.fastestHard)
    }

    public func submitTotalSolved(_ count: Int) {
        guard count > 0 else { return }
        submitScore(count, leaderboardID: LeaderboardID.totalSolved)
    }

    public func submitPlayerXP(_ xp: Int) {
        guard xp > 0 else { return }
        submitScore(xp, leaderboardID: LeaderboardID.playerXP)
    }

    // MARK: - Achievements

    /// Reports achievement progress to Apple Game Center (0.0 to 100.0%).
    public func reportAchievement(id: String, percentComplete: Double, showsBanner: Bool = true) {
        guard GKLocalPlayer.local.isAuthenticated else { return }

        let achievement = GKAchievement(identifier: id)
        achievement.percentComplete = min(100.0, max(0.0, percentComplete))
        achievement.showsCompletionBanner = showsBanner

        GKAchievement.report([achievement]) { error in
            #if DEBUG
            if let error {
                print("🎮 GameCenter: Achievement report failed for '\(id)': \(error.localizedDescription)")
            } else if percentComplete >= 100.0 {
                print("🎮 GameCenter: Achievement '\(id)' unlocked and synced to Apple!")
            }
            #endif
        }
    }

    // MARK: - Present Native Game Center Overlays

    /// Presents Apple's native Game Center Leaderboard overlay.
    /// If leaderboards haven't been provisioned yet in App Store Connect,
    /// displays an informative alert rather than Apple's blank empty screen.
    public func showLeaderboards(leaderboardID: String? = nil) {
        guard let topVC = getTopViewController() else { return }

        guard GKLocalPlayer.local.isAuthenticated else {
            let alert = UIAlertController(
                title: "Game Center",
                message: "Please sign in to Game Center in your device Settings to view global rankings and compete with friends.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            topVC.present(alert, animated: true)
            return
        }

        Task {
            do {
                let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: nil)
                if leaderboards.isEmpty {
                    self.showLeaderboardsPendingAlert(on: topVC)
                } else {
                    self.presentNativeLeaderboards(leaderboardID: leaderboardID, on: topVC)
                }
            } catch {
                self.showLeaderboardsPendingAlert(on: topVC)
            }
        }
    }

    private func presentNativeLeaderboards(leaderboardID: String?, on topVC: UIViewController) {
        let gcVC: GKGameCenterViewController
        if let leaderboardID = leaderboardID {
            gcVC = GKGameCenterViewController(
                leaderboardID: leaderboardID,
                playerScope: .global,
                timeScope: .allTime
            )
        } else {
            gcVC = GKGameCenterViewController(state: .leaderboards)
        }

        gcVC.gameCenterDelegate = self
        topVC.present(gcVC, animated: true)
    }

    private func showLeaderboardsPendingAlert(on topVC: UIViewController) {
        let alert = UIAlertController(
            title: "🏆 Global Rankings",
            message: "Leaderboards will be live on Apple Game Center once configured in App Store Connect!\n\nIn the meantime, your best times, daily streaks, and trophies are safely recorded on your device.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got It", style: .default))
        topVC.present(alert, animated: true)
    }

    /// Presents Apple's native Game Center Achievements overlay.
    public func showAchievements() {
        guard let topVC = getTopViewController() else { return }

        let gcVC = GKGameCenterViewController(state: .achievements)
        gcVC.gameCenterDelegate = self
        topVC.present(gcVC, animated: true)
    }

    // MARK: - GKGameCenterControllerDelegate

    public nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }

    // MARK: - Top UIViewController Helper

    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        var top = rootViewController
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
