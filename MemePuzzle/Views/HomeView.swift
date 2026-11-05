import MemeBlitzCore
import PhotosUI
import SwiftUI

/// Premium, dark cinematic, playful arcade Home Screen for MEME BLITZ.
/// Matches the 9:16 reference design with glowing neon accents, 3D arcade branding,
/// interactive difficulty cards, best time crown badge, sound toggle, settings, and collection banner.
struct HomeView: View {
    let onStart: (PuzzleSession) -> Void
    var onOpenCollection: (() -> Void)?
    private var externalMode: Binding<DifficultyMode?>?

    @State private var profile = GameProfile.shared
    @State private var showSettings = false
    @State private var showStats = false
    @State private var floatingPhase: CGFloat = 0
    @State private var showLockedAlert = false
    @State private var lockedAlertMessage = ""
    @State private var internalMode: DifficultyMode? = nil
    @State private var emojiParticles: [FloatingEmojiParticle] = []

    private var activeModeBinding: Binding<DifficultyMode?> {
        externalMode ?? $internalMode
    }

    init(
        onStart: @escaping (PuzzleSession) -> Void,
        onOpenCollection: (() -> Void)? = nil,
        activeLevelSelectMode: Binding<DifficultyMode?>? = nil
    ) {
        self.onStart = onStart
        self.onOpenCollection = onOpenCollection
        self.externalMode = activeLevelSelectMode
    }

    var body: some View {
        ZStack {
            if let activeMode = activeModeBinding.wrappedValue {
                LevelSelectView(
                    mode: activeMode,
                    onSelectSession: { session in
                        onStart(session)
                    },
                    onBack: {
                        withAnimation(.snappy(duration: 0.28)) {
                            activeModeBinding.wrappedValue = nil
                        }
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        topBar
                        heroBranding
                        dailyBlitzCard
                        difficultySectionHeader
                        difficultyCardsRow
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 90)
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.28), value: activeModeBinding.wrappedValue)
        .background(Theme.background)
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        .sheet(isPresented: $showStats) {
            StatsSheet()
        }
        .alert("Difficulty Locked", isPresented: $showLockedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(lockedAlertMessage)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatingPhase = 1
            }
        }
    }

    // MARK: - A. Top Bar (Best Time, Sound Toggle, Settings)

    private var topBar: some View {
        HStack(alignment: .center) {
            // Best Time Pill
            Button {
                AudioManager.shared.playTap()
                showStats = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.neonGold, Theme.neonOrange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Theme.neonGold.opacity(0.5), radius: 6)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Best Time")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.65))
                            .textCase(.uppercase)

                        Text(profile.formattedBestTime)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.neonGold)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .arcadeGlass(
                    stroke: Theme.neonViolet.opacity(0.4),
                    cornerRadius: 22,
                    fillOpacity: 0.14
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("best.time.badge")

            Spacer()

            // Sound Toggle Button
            Button {
                profile.soundEnabled.toggle()
                if profile.soundEnabled {
                    AudioManager.shared.playTap()
                }
            } label: {
                Image(systemName: profile.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .arcadeGlass(
                        stroke: profile.soundEnabled ? Theme.neonViolet.opacity(0.5) : Color.white.opacity(0.15),
                        cornerRadius: 22,
                        fillOpacity: 0.14
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(profile.soundEnabled ? "Sound Effects: On" : "Sound Effects: Off")
            .accessibilityIdentifier("sound.toggle")

            // Game Center Leaderboard Button
            Button {
                AudioManager.shared.playTap()
                GameCenterManager.shared.showLeaderboards()
            } label: {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.neonGold)
                    .frame(width: 44, height: 44)
                    .arcadeGlass(
                        stroke: Theme.neonGold.opacity(0.5),
                        cornerRadius: 22,
                        fillOpacity: 0.14
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Game Center Leaderboards")
            .accessibilityIdentifier("gamecenter.leaderboards")

            // Settings Button
            Button {
                AudioManager.shared.playTap()
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .arcadeGlass(
                        stroke: Theme.neonViolet.opacity(0.5),
                        cornerRadius: 22,
                        fillOpacity: 0.14
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
            .accessibilityIdentifier("settings.button")
        }
    }

    // MARK: - D. Hero Branding (Logo, Crown, Floating Memes, Tagline)

    private var heroBranding: some View {
        let easyList = MemeCatalog.easy
        let m1 = easyList.first?.resourceName ?? "easy_001"
        let m2 = (MemeCatalog.medium.first ?? easyList.dropFirst().first)?.resourceName ?? "medium_001"
        let m3 = (MemeCatalog.hard.first ?? easyList.dropFirst(2).first)?.resourceName ?? "hard_001"
        let m4 = (MemeCatalog.extreme.first ?? easyList.dropFirst(3).first)?.resourceName ?? "extreme_001"

        return ZStack {
            // Floating tilted meme cards behind the logo with tap-burst emoji interactions
            FloatingMemeThumbView(
                resource: m1,
                degrees: -14,
                xOffset: -125,
                yOffset: -40,
                glow: Theme.neonGold,
                floatingPhase: floatingPhase,
                onSpawnBurst: spawnEmojiBurst
            )
            FloatingMemeThumbView(
                resource: m2,
                degrees: 12,
                xOffset: 125,
                yOffset: -35,
                glow: Theme.easyEmerald,
                floatingPhase: floatingPhase,
                onSpawnBurst: spawnEmojiBurst
            )
            FloatingMemeThumbView(
                resource: m3,
                degrees: -9,
                xOffset: -130,
                yOffset: 45,
                glow: Theme.neonViolet,
                floatingPhase: floatingPhase,
                onSpawnBurst: spawnEmojiBurst
            )
            FloatingMemeThumbView(
                resource: m4,
                degrees: 14,
                xOffset: 130,
                yOffset: 50,
                glow: Theme.neonOrange,
                floatingPhase: floatingPhase,
                onSpawnBurst: spawnEmojiBurst
            )

            // Centered Logo & Tagline
            VStack(spacing: 4) {
                if let url = Bundle.main.url(forResource: "app_logo", withExtension: "png"),
                   let image = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 240, maxHeight: 165)
                        .shadow(color: Theme.neonViolet.opacity(0.45), radius: 18, y: 6)
                        .offset(y: floatingPhase * 3)
                } else {
                    // Fallback Crown atop logo
                    Image(systemName: "crown.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.95, blue: 0.5), Theme.neonGold, Theme.neonOrange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Theme.neonGold.opacity(0.7), radius: 12, y: 3)
                        .offset(y: floatingPhase * 3)

                    // MEME Text (White 3D Arcade)
                    Text("MEME")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 0.92, green: 0.90, blue: 1.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(red: 0.35, green: 0.15, blue: 0.65).opacity(0.9), radius: 0, x: 0, y: 4)
                        .shadow(color: Theme.neonViolet.opacity(0.6), radius: 18)
                        .tracking(2)

                    // BLITZ Text (Golden Orange 3D with Lightning Bolt)
                    HStack(spacing: 2) {
                        Text("BLITZ")
                            .font(.system(size: 54, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.92, blue: 0.35),
                                        Theme.neonGold,
                                        Theme.neonOrange
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color(red: 0.5, green: 0.2, blue: 0.05).opacity(0.9), radius: 0, x: 0, y: 4)
                            .shadow(color: Theme.neonOrange.opacity(0.6), radius: 16)
                            .tracking(2)

                        Image(systemName: "bolt.fill")
                            .font(.system(size: 38, weight: .black))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Theme.neonGold, Theme.neonOrange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Theme.neonGold.opacity(0.8), radius: 10)
                            .rotationEffect(.degrees(12))
                            .offset(x: -4, y: -2)
                    }
                    .offset(y: -10)
                }

                // Tagline
                HStack(spacing: 6) {
                    Text("✦")
                        .font(.caption2)
                        .foregroundStyle(Theme.neonGold)
                    Text("Solve Memes. Beat the Clock.")
                        .font(.system(size: 14, weight: .heavy, design: .rounded).italic())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 0.9, green: 0.82, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("✦")
                        .font(.caption2)
                        .foregroundStyle(Theme.neonViolet)
                }
                .padding(.top, 2)
            }

            // Bursting Emojis overlay layer atop the hero branding
            ForEach(emojiParticles) { particle in
                EmojiParticleView(particle: particle) {
                    emojiParticles.removeAll { $0.id == particle.id }
                }
            }
            .zIndex(30)
        }
        .frame(height: 215)
        .padding(.vertical, 4)
    }

    private func spawnEmojiBurst(atX x: CGFloat, atY y: CGFloat) {
        let candidateEmojis = ["😂", "🔥", "✨", "⭐", "🎉", "⚡", "💥", "👑", "🚀", "🐾", "💯", "🤪"]
        let count = 6
        var newParticles: [FloatingEmojiParticle] = []

        for _ in 0..<count {
            let emoji = candidateEmojis.randomElement() ?? "✨"
            let spreadAngle = Double.random(in: -Double.pi * 0.95 ... -Double.pi * 0.05)
            let distance = CGFloat.random(in: 45...85)
            let targetX = x + cos(spreadAngle) * distance
            let targetY = y + sin(spreadAngle) * distance - 25
            let rotation = Double.random(in: -40...40)
            let scale = CGFloat.random(in: 1.05...1.4)

            newParticles.append(
                FloatingEmojiParticle(
                    emoji: emoji,
                    startX: x,
                    startY: y,
                    targetX: targetX,
                    targetY: targetY,
                    rotation: rotation,
                    scale: scale
                )
            )
        }

        emojiParticles.append(contentsOf: newParticles)
    }

    // Floating meme thumb component and emoji particle effects are declared below in this file.

    // MARK: - Daily Blitz Hero Card

    private var dailyBlitzCard: some View {
        let day = DailyBlitzManager.currentDayNumber
        let isDone = profile.isTodayDailyCompleted
        let template = MemeCatalog.dailyTemplate(for: day)

        return VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                // Artwork thumbnail
                ZStack {
                    if let url = Bundle.main.url(forResource: template.resourceName, withExtension: "jpg"),
                       let image = UIImage(contentsOfFile: url.path) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.6), Color.black],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: "flame.fill")
                                    .font(.title2)
                                    .foregroundStyle(Theme.neonGold)
                            )
                    }

                    if isDone {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.black.opacity(0.55))
                            .overlay(
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(Theme.neonGold)
                            )
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(isDone ? Theme.neonGold.opacity(0.8) : Theme.neonViolet.opacity(0.6), lineWidth: 2)
                )
                .shadow(color: (isDone ? Theme.neonGold : Theme.neonViolet).opacity(0.4), radius: 8)

                // Info Block
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("DAY \(day) OF 100")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.neonGold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.neonGold.opacity(0.18))
                            .clipShape(Capsule())

                        if profile.dailyStreak > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10, weight: .bold))
                                Text("\(profile.dailyStreak) STREAK")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                            }
                            .foregroundStyle(Theme.neonOrange)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Theme.neonOrange.opacity(0.18))
                            .clipShape(Capsule())
                        }
                    }

                    Text("DAILY BLITZ")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("10×10 Hard · 32 Pcs · 120s Clock · -10s Eye")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()
            }

            // Play / Completed Button
            if isDone {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.neonGold)
                    Text("COMPLETED TODAY — NEW PUZZLE AT MIDNIGHT")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.neonGold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.neonGold.opacity(0.3), lineWidth: 1)
                )
            } else {
                Button {
                    AudioManager.shared.playTap()
                    let session = DailyBlitzManager.makeDailySession()
                    onStart(session)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14, weight: .black))
                        Text("PLAY TODAY'S BLITZ")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.9, blue: 0.3), Theme.neonGold, Theme.neonOrange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Theme.neonGold.opacity(0.5), radius: 10, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .arcadeGlass(
            stroke: isDone ? Theme.neonGold.opacity(0.35) : Theme.neonViolet.opacity(0.5),
            cornerRadius: 22,
            fillOpacity: 0.16
        )
    }

    // MARK: - Section Header

    private var difficultySectionHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(Theme.neonGold)

            Text("Choose Your Difficulty")
                .font(.title3.weight(.black))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - E. Difficulty Cards (Easy, Medium, Hard, Extreme)

    private var difficultyCardsRow: some View {
        let easyList = MemeCatalog.easy
        let easyThumb = easyList.first?.resourceName ?? "easy_007_48_funniest_cat_thatll"
        let medThumb = (MemeCatalog.medium.first ?? easyList.dropFirst().first)?.resourceName ?? "medium_001"
        let hardThumb = (MemeCatalog.hard.first ?? easyList.dropFirst(2).first)?.resourceName ?? "hard_001"
        let extremeThumb = (MemeCatalog.extreme.first ?? easyList.dropFirst(3).first)?.resourceName ?? "extreme_001_funniest_animal_memes_to"

        return VStack(spacing: 10) {
            difficultyCard(
                mode: .easy,
                title: "Easy",
                badgeText: "EASY",
                icon: "leaf.fill",
                gridText: "6 × 6",
                piecesText: "8",
                timeText: "90s",
                accent: Theme.easyEmerald,
                thumbnailName: easyThumb,
                isUnlocked: profile.isModeUnlocked(.easy),
                unlockHint: nil
            )

            difficultyCard(
                mode: .medium,
                title: "Medium",
                badgeText: "MEDIUM",
                icon: "bolt.fill",
                gridText: "8 × 8",
                piecesText: "18",
                timeText: "60s",
                accent: Theme.mediumAmber,
                thumbnailName: medThumb,
                isUnlocked: profile.isModeUnlocked(.medium),
                unlockHint: "Complete all Easy levels"
            )

            difficultyCard(
                mode: .hard,
                title: "Hard",
                badgeText: "HARD",
                icon: "flame.fill",
                gridText: "10 × 10",
                piecesText: "32",
                timeText: "35s",
                accent: Theme.hardMagenta,
                thumbnailName: hardThumb,
                isUnlocked: profile.isModeUnlocked(.hard),
                unlockHint: "Complete all Medium levels"
            )

            difficultyCard(
                mode: .extreme,
                title: "Extreme",
                badgeText: "EXTREME",
                icon: "skull.fill",
                gridText: "10 × 10",
                piecesText: "48",
                timeText: "20s",
                accent: Theme.extremeCrimson,
                thumbnailName: extremeThumb,
                isUnlocked: profile.isModeUnlocked(.extreme),
                unlockHint: "Complete all Hard levels"
            )
        }
    }

    private func difficultyCard(
        mode: DifficultyMode,
        title: String,
        badgeText: String,
        icon: String,
        gridText: String,
        piecesText: String,
        timeText: String,
        accent: Color,
        thumbnailName: String,
        isUnlocked: Bool,
        unlockHint: String?
    ) -> some View {
        Button {
            if isUnlocked {
                AudioManager.shared.playTap()
                withAnimation(.snappy(duration: 0.28)) {
                    activeModeBinding.wrappedValue = mode
                }
            } else {
                AudioManager.shared.playWrong()
                if let unlockHint {
                    lockedAlertMessage = "🔒 \(title) mode is locked!\n\(unlockHint) to unlock."
                    showLockedAlert = true
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Left: Thumbnail box with mode pill & lock overlay
                ZStack(alignment: .bottomLeading) {
                    if let url = Bundle.main.url(forResource: thumbnailName, withExtension: "jpg"),
                       let uiImage = UIImage(contentsOfFile: url.path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 68, height: 68)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .saturation(isUnlocked ? 1.0 : 0.2)
                            .opacity(isUnlocked ? 1.0 : 0.45)
                    } else {
                        Color.black.opacity(0.4)
                            .frame(width: 68, height: 68)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    // Mode Pill Badge
                    Text(badgeText)
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(isUnlocked ? Color.black : Color.white.opacity(0.85))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(isUnlocked ? accent : Color.white.opacity(0.2))
                        .clipShape(Capsule())
                        .padding(4)

                    if !isUnlocked {
                        ZStack {
                            Color.black.opacity(0.6)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 68, height: 68)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .frame(width: 68, height: 68)

                // Middle: Title & Specs
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: isUnlocked ? icon : "lock.fill")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(isUnlocked ? accent : .white.opacity(0.5))

                        Text(title.uppercased())
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(isUnlocked ? .white : .white.opacity(0.65))
                    }

                    Text("\(gridText) Grid  •  \(piecesText) Pcs  •  \(timeText)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                // Right: Play / Locked capsule button
                if isUnlocked {
                    HStack(spacing: 4) {
                        Text("PLAY")
                            .font(.system(size: 12, weight: .black))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(accent)
                    .clipShape(Capsule())
                    .shadow(color: accent.opacity(0.45), radius: 6, y: 2)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("LOCKED")
                            .font(.system(size: 11, weight: .black))
                    }
                    .foregroundStyle(Color.white.opacity(0.65))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            .padding(10)
            .arcadeGlass(
                stroke: isUnlocked ? accent.opacity(0.4) : Color.white.opacity(0.1),
                lineWidth: 1.2,
                cornerRadius: 18,
                fillOpacity: isUnlocked ? 0.1 : 0.04
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("mode.\(mode.rawValue)")
    }

    // MARK: - Game Launcher

    private func startPuzzleWithDifficulty(_ mode: DifficultyMode) {
        AudioManager.shared.playTap()
        profile.selectedDifficulty = mode

        // Pick a meme from the active difficulty pool
        let pool = MemeCatalog.templates(for: mode)
        let completed = profile.completedMemeIDs
        let candidate = pool.first { !completed.contains($0.id) } ?? (pool.isEmpty ? MemeCatalog.bundled[0] : pool[0])
        startPuzzle(source: .bundled(candidate), mode: mode)
    }

    private func startPuzzle(source: MemeSource, mode: DifficultyMode) {
        let configuration = mode.configuration
        onStart(PuzzleSession(source: source, configuration: configuration))
    }
}

// MARK: - Interactive Floating Meme Card with Spring Bounce

struct FloatingMemeThumbView: View {
    let resource: String
    let degrees: Double
    let xOffset: CGFloat
    let yOffset: CGFloat
    let glow: Color
    let floatingPhase: CGFloat
    let onSpawnBurst: (CGFloat, CGFloat) -> Void

    @State private var isBouncing = false

    var body: some View {
        Group {
            if let template = MemeCatalog.bundled.first(where: { $0.resourceName == resource }),
               let url = Bundle.main.url(forResource: resource, withExtension: "jpg"),
               let image = UIImage(contentsOfFile: url.path) {
                Button {
                    AudioManager.shared.playCorrect()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                    // Playful spring bounce
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.45)) {
                        isBouncing = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                            isBouncing = false
                        }
                    }

                    // Burst floating emojis from this card
                    onSpawnBurst(xOffset, yOffset + (floatingPhase * 4))
                } label: {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 66, height: 66)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(glow.opacity(isBouncing ? 1.0 : 0.75), lineWidth: isBouncing ? 2.5 : 2)
                        )
                        .shadow(color: glow.opacity(isBouncing ? 0.7 : 0.35), radius: isBouncing ? 16 : 10, y: 4)
                }
                .buttonStyle(.plain)
                .scaleEffect(isBouncing ? 1.22 : 1.0)
                .accessibilityIdentifier("meme.\(template.id)")
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 66, height: 66)
            }
        }
        .rotationEffect(.degrees(degrees + (isBouncing ? (degrees > 0 ? 8 : -8) : 0)))
        .offset(x: xOffset, y: yOffset + (floatingPhase * 4))
    }
}

// MARK: - Floating Emoji Particle Effects

struct FloatingEmojiParticle: Identifiable {
    let id = UUID()
    let emoji: String
    let startX: CGFloat
    let startY: CGFloat
    let targetX: CGFloat
    let targetY: CGFloat
    let rotation: Double
    let scale: CGFloat
}

struct EmojiParticleView: View {
    let particle: FloatingEmojiParticle
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0

    var body: some View {
        Text(particle.emoji)
            .font(.system(size: 26))
            .rotationEffect(.degrees(particle.rotation * progress))
            .scaleEffect(progress < 0.25 ? (progress / 0.25) * particle.scale : max(0.2, (1.0 - (progress - 0.25) * 0.4) * particle.scale))
            .opacity(progress > 0.6 ? max(0, Double(1.0 - (progress - 0.6) / 0.4)) : 1.0)
            .offset(
                x: particle.startX + (particle.targetX - particle.startX) * progress,
                y: particle.startY + (particle.targetY - particle.startY) * progress
            )
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    progress = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    onComplete()
                }
            }
            .allowsHitTesting(false)
    }
}
