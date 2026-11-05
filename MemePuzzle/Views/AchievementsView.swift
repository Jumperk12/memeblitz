import MemeBlitzCore
import SwiftUI

/// Redesigned Trophies & Player Progression screen.
/// Features player level, XP progress, daily streaks, featured next trophy, and categorized achievements.
struct AchievementsView: View {
    @State private var viewModel = AchievementsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - 1. Top Section: Player Level & Progression Card
                playerProgressionCard

                // MARK: - 1b. Game Center Global Leaderboards Banner
                gameCenterBanner

                // MARK: - 2. Featured Next Trophy
                if let featured = viewModel.featuredNextAchievement {
                    featuredNextTrophyCard(featured)
                }

                // MARK: - 3. Category Filter Chips
                categoryFilterBar

                // MARK: - 4. Categorized Achievements
                VStack(spacing: 20) {
                    ForEach(viewModel.filteredCategories) { category in
                        categorySection(category)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 110) // clearance for persistent bottom navigation dock
        }
        .background(Theme.background)
        .navigationTitle("Trophies")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onTrophiesAppear()
        }
    }

    // MARK: - Subviews: Player Progression

    private var playerProgressionCard: some View {
        VStack(spacing: 14) {
            // Level & XP Header
            HStack(alignment: .center, spacing: 12) {
                // Glowing Level Badge
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.neonViolet.opacity(0.4), Theme.neonViolet.opacity(0.1)],
                                center: .center,
                                startRadius: 4,
                                endRadius: 28
                            )
                        )
                        .frame(width: 54, height: 54)
                        .overlay(
                            Circle().strokeBorder(Theme.neonViolet, lineWidth: 1.5)
                        )
                        .shadow(color: Theme.neonViolet.opacity(0.6), radius: 8)

                    VStack(spacing: 0) {
                        Text("LVL")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(Color.white.opacity(0.6))
                        Text("\(viewModel.playerLevel)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("ARCADE RANK")
                            .font(.system(size: 10, weight: .black))
                            .tracking(1.0)
                            .foregroundStyle(Theme.neonGold)

                        Spacer()

                        Text("\(viewModel.totalXP) XP")
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Theme.neonGold)
                    }

                    // Level XP Progress Bar
                    ArcadeProgressBar(
                        progress: viewModel.levelProgress,
                        height: 7,
                        gradient: LinearGradient(
                            colors: [Theme.neonViolet, Theme.neonGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                    HStack {
                        Text("\(viewModel.xpRemainingForNextLevel) XP to Level \(viewModel.playerLevel + 1)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.5))
                        Spacer()
                        Text("\(Int(viewModel.levelProgress * 100))%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                }
            }

            // Stat Boxes: Puzzles Completed & Current Streak
            HStack(spacing: 10) {
                ArcadeStatCard(
                    label: "Puzzles Solved",
                    value: "\(viewModel.totalSolvedCount)",
                    icon: "puzzlepiece.fill",
                    accentColor: Theme.neonViolet
                )

                ArcadeStatCard(
                    label: "Current Streak",
                    value: "\(viewModel.currentStreak)",
                    icon: "flame.fill",
                    accentColor: Theme.neonOrange
                )

                ArcadeStatCard(
                    label: "Trophies",
                    value: "\(viewModel.unlockedCount)/\(viewModel.totalAchievementCount)",
                    icon: "crown.fill",
                    accentColor: Theme.neonGold
                )
            }
        }
        .padding(18)
        .arcadeGlass(
            stroke: Theme.neonViolet.opacity(0.35),
            cornerRadius: 22,
            fillOpacity: 0.1
        )
    }

    // MARK: - Subviews: Game Center Leaderboard Banner

    private var gameCenterBanner: some View {
        Button {
            AudioManager.shared.playTap()
            GameCenterManager.shared.showLeaderboards()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.neonGold.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.neonGold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("GLOBAL LEADERBOARDS")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.0)
                        .foregroundStyle(Theme.neonGold)
                    Text("View ranks for Daily Blitz & Hard Mode")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.neonGold)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .arcadeGlass(
                stroke: Theme.neonGold.opacity(0.4),
                cornerRadius: 16,
                fillOpacity: 0.12
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("gamecenter.banner")
    }

    // MARK: - Subviews: Featured Next Trophy

    private func featuredNextTrophyCard(_ status: AchievementStatus) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.neonGold)
                    Text("NEXT TARGET")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.2)
                        .foregroundStyle(Theme.neonGold)
                }

                Spacer()

                Text("+\(status.xpReward) XP")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Theme.neonGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.neonGold.opacity(0.18))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(Theme.neonGold.opacity(0.4), lineWidth: 0.8)
                    )
            }

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(status.accentColor.opacity(0.18))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle().strokeBorder(status.accentColor.opacity(0.6), lineWidth: 1.2)
                        )
                    Image(systemName: status.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(status.accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(status.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)

                    Text(status.description)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
                Spacer()
            }

            // Progress Bar
            VStack(spacing: 4) {
                ArcadeProgressBar(
                    progress: status.progressFraction,
                    height: 6,
                    gradient: LinearGradient(
                        colors: [status.accentColor, Theme.neonGold],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

                HStack {
                    Text("\(status.currentProgress) / \(status.targetProgress)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.55))

                    Spacer()

                    Text("\(Int(status.progressFraction * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(status.accentColor)
                }
            }
        }
        .padding(14)
        .arcadeGlass(
            stroke: Theme.neonGold.opacity(0.35),
            cornerRadius: 18,
            fillOpacity: 0.08
        )
        .shadow(color: Theme.neonGold.opacity(0.12), radius: 10)
    }

    // MARK: - Subviews: Category Filter Bar

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All Categories chip
                filterChip(
                    title: "All",
                    icon: "square.grid.2x2.fill",
                    isSelected: viewModel.selectedCategory == nil,
                    accentColor: Theme.neonViolet
                ) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                        viewModel.selectedCategory = nil
                    }
                }

                // Per-category chips
                ForEach(viewModel.categories) { category in
                    let isSelected = viewModel.selectedCategory == category
                    filterChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: isSelected,
                        accentColor: category.accentColor
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            viewModel.selectedCategory = isSelected ? nil : category
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .padding(.horizontal, -16)
    }

    private func filterChip(
        title: String,
        icon: String,
        isSelected: Bool,
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            AudioManager.shared.playTap()
            action()
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .heavy : .semibold))
            }
            .foregroundStyle(isSelected ? .white : Color.white.opacity(0.65))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(accentColor.opacity(0.28))
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                    }
                }
            )
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(isSelected ? accentColor : Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: isSelected ? accentColor.opacity(0.35) : .clear, radius: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews: Category Section

    private func categorySection(_ category: AchievementCategory) -> some View {
        let statuses = viewModel.statuses(for: category)
        let unlocked = viewModel.unlockedCount(in: category)
        let total = viewModel.totalCount(in: category)

        return VStack(alignment: .leading, spacing: 10) {
            // Category Header
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(category.accentColor)

                Text(category.rawValue.uppercased())
                    .font(.system(size: 12, weight: .black))
                    .tracking(1.2)
                    .foregroundStyle(category.accentColor)

                Spacer()

                Text("\(unlocked)/\(total)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(unlocked == total ? Theme.neonGold : Color.white.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2.5)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)

            // Achievement Rows
            VStack(spacing: 8) {
                ForEach(statuses) { status in
                    achievementRow(status)
                }
            }
        }
    }

    // MARK: - Subviews: Achievement Row

    private func achievementRow(_ status: AchievementStatus) -> some View {
        let isUnlocked = status.isUnlocked
        let inProgress = !isUnlocked && status.currentProgress > 0

        return HStack(spacing: 12) {
            // Icon Badge
            ZStack {
                Circle()
                    .fill(
                        isUnlocked
                            ? status.accentColor.opacity(0.22)
                            : (inProgress ? status.accentColor.opacity(0.09) : Color.white.opacity(0.03))
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isUnlocked
                                    ? status.accentColor
                                    : (inProgress ? status.accentColor.opacity(0.4) : Color.white.opacity(0.1)),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: isUnlocked ? status.accentColor.opacity(0.5) : .clear, radius: 6)

                Image(systemName: status.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        isUnlocked
                            ? status.accentColor
                            : (inProgress ? status.accentColor.opacity(0.7) : Color.white.opacity(0.25))
                    )
            }

            // Title & Description
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(status.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isUnlocked ? .white : Color.white.opacity(0.5))

                    Spacer()

                    if isUnlocked {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .black))
                            Text("UNLOCKED")
                                .font(.system(size: 8, weight: .black))
                        }
                        .foregroundStyle(Theme.neonGold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.neonGold.opacity(0.18))
                        .clipShape(Capsule())
                    } else if inProgress {
                        Text("\(status.currentProgress)/\(status.targetProgress)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(status.accentColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(status.accentColor.opacity(0.14))
                            .clipShape(Capsule())
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.25))
                    }
                }

                Text(status.description)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.white.opacity(isUnlocked ? 0.7 : 0.38))

                if inProgress {
                    ArcadeProgressBar(
                        progress: status.progressFraction,
                        height: 4,
                        gradient: LinearGradient(
                            colors: [status.accentColor, Theme.neonGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        showGlow: false
                    )
                    .padding(.top, 2)
                }
            }
        }
        .padding(12)
        .arcadeGlass(
            stroke: isUnlocked ? status.accentColor.opacity(0.35) : Color.white.opacity(0.06),
            cornerRadius: 16,
            fillOpacity: isUnlocked ? 0.08 : 0.03
        )
    }
}
