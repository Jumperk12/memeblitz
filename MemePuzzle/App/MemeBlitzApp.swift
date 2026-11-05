import GoogleMobileAds
import MemeBlitzCore
import SwiftUI

@main
struct MemeBlitzApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [
            "9f87e6d072f0cfc222745c3968d25169"
        ]
        #endif
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        Task {
            await RewardedAdService.shared.preload()
        }
        GameCenterManager.shared.authenticateLocalPlayer()
        AudioManager.shared.startBackgroundMusic()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                GameProfile.shared.syncWithCloudStorage()
                AudioManager.shared.resumeBackgroundMusic()
                NotificationManager.shared.cancelAllReminders()
            case .inactive, .background:
                GameProfile.shared.saveNow()
                AudioManager.shared.pauseBackgroundMusic()
                NotificationManager.shared.scheduleInactivityReminders()
            @unknown default:
                break
            }
        }
    }
}

public enum NavigationTab: String, CaseIterable, Identifiable {
    case home
    case collection
    case achievements

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .home: "Blitz"
        case .collection: "Meme Vault"
        case .achievements: "Trophies"
        }
    }

    public var icon: String {
        switch self {
        case .home: "puzzlepiece.extension.fill"
        case .collection: "photo.stack.fill"
        case .achievements: "crown.fill"
        }
    }
}

/// Owns navigation between the meme picker, collection, achievements, and active puzzle sessions.
struct RootView: View {
    @State private var session: PuzzleSession?
    @State private var selectedTab: NavigationTab = .home
    @State private var didHandleLaunchArguments = false
    @State private var activeLevelSelectMode: DifficultyMode? = nil
    @State private var isShowingLaunchScreen = true
    @StateObject private var trackingManager = AppTrackingManager.shared
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some View {
        ZStack {
            if let session {
                PuzzleScreen(
                    session: session,
                    onExit: { self.session = nil },
                    onExitToLevels: {
                        self.activeLevelSelectMode = session.configuration.effectiveMode
                        self.session = nil
                    },
                    onExitToChangeMode: {
                        self.activeLevelSelectMode = nil
                        self.session = nil
                    },
                    onNextSession: { next in
                        withAnimation(.snappy(duration: 0.35)) {
                            self.session = next
                        }
                    }
                )
                .id(session.id)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                mainNavInterface
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            if isShowingLaunchScreen {
                LaunchScreenView {
                    isShowingLaunchScreen = false
                    trackingManager.checkAndRequestTracking()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        notificationManager.checkAndPromptIfNeeded()
                    }
                }
                .transition(.opacity)
                .zIndex(999)
            }

            // App Tracking Transparency (ATT) Explainer on first download
            if trackingManager.showTrackingExplainer {
                ZStack {
                    Color.black.opacity(0.68)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    TrackingExplainerView {
                        trackingManager.requestNativeTracking()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            notificationManager.checkAndPromptIfNeeded()
                        }
                    }
                    .padding(.horizontal, 20)
                    .transition(.scale(scale: 0.93).combined(with: .opacity))
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: trackingManager.showTrackingExplainer)
                .zIndex(500)
            }

            // In-App Notification Permission Request (Allow / Don't Allow)
            if notificationManager.showNotificationPrompt && !trackingManager.showTrackingExplainer {
                ZStack {
                    Color.black.opacity(0.68)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    NotificationPromptView(
                        onAllow: {
                            notificationManager.allowNotifications()
                        },
                        onDeny: {
                            notificationManager.denyNotifications()
                        }
                    )
                    .padding(.horizontal, 20)
                    .transition(.scale(scale: 0.93).combined(with: .opacity))
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: notificationManager.showNotificationPrompt)
                .zIndex(501)
            }
        }
        .animation(.snappy(duration: 0.35), value: session?.id)
        .animation(.easeInOut(duration: 0.35), value: isShowingLaunchScreen)
        .onAppear(perform: handleLaunchArguments)
        .preferredColorScheme(.dark)
    }

    private var mainNavInterface: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        onStart: { session = $0 },
                        onOpenCollection: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedTab = .collection
                            }
                        },
                        activeLevelSelectMode: $activeLevelSelectMode
                    )
                case .collection:
                    NavigationStack {
                        CollectionView(onStart: { session = $0 })
                    }
                case .achievements:
                    NavigationStack {
                        AchievementsView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Persistent Bottom Navigation Bar
            bottomTabBar
        }
        .background(Theme.background)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - G. Persistent Bottom Navigation

    private var bottomTabBar: some View {
        HStack(spacing: 8) {
            ForEach(NavigationTab.allCases) { tab in
                let isSelected = selectedTab == tab
                let tint = tabColor(for: tab)
                Button {
                    AudioManager.shared.playTap()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? tint : Color.white.opacity(0.42))
                            .scaleEffect(isSelected ? 1.12 : 1.0)
                            .shadow(color: isSelected ? tint.opacity(0.65) : .clear, radius: 8)

                        Text(tab.title)
                            .font(.system(size: 11, weight: isSelected ? .heavy : .semibold))
                            .foregroundStyle(isSelected ? .white : Color.white.opacity(0.45))
                            .shadow(color: isSelected ? tint.opacity(0.4) : .clear, radius: 4)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        ZStack {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [tint.opacity(0.22), tint.opacity(0.08)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(tint.opacity(0.42), lineWidth: 1)
                                    )
                                    .shadow(color: tint.opacity(0.3), radius: 10, y: 3)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tab.\(tab.rawValue)")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .background(
            Color(red: 0.06, green: 0.05, blue: 0.12)
                .opacity(0.96)
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.12), Theme.neonViolet.opacity(0.3), Color.white.opacity(0.12)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1),
                    alignment: .top
                )
                .shadow(color: Color.black.opacity(0.5), radius: 16, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabColor(for tab: NavigationTab) -> Color {
        switch tab {
        case .home: Theme.neonViolet
        case .collection: Color(red: 0.96, green: 0.45, blue: 0.71)
        case .achievements: Theme.neonGold
        }
    }

    /// Developer & test arguments: `-autostartMeme <id>` (plus `-autostartDifficulty`, `-puzzleSeed`, etc.).
    private func handleLaunchArguments() {
        guard !didHandleLaunchArguments else { return }
        didHandleLaunchArguments = true
        let defaults = UserDefaults.standard
        if CommandLine.arguments.contains("-skipLaunchScreen") || defaults.string(forKey: "autostartMeme") != nil {
            isShowingLaunchScreen = false
        }
        if CommandLine.arguments.contains("-unlockAllModes") {
            GameProfile.shared.completedModes.insert(DifficultyMode.easy.rawValue)
            GameProfile.shared.completedModes.insert(DifficultyMode.medium.rawValue)
        }
        guard let memeID = defaults.string(forKey: "autostartMeme"),
              let template = MemeCatalog.bundled.first(where: { $0.id == memeID }) else { return }
        let settings = PuzzleSettings.load()
        let modeName = defaults.string(forKey: "autostartDifficulty") ?? ""
        let mode = DifficultyMode(rawValue: modeName) ?? settings.selectedDifficulty
        var configuration = mode.configuration
        let missing = defaults.integer(forKey: "missingTiles")
        let rows = defaults.integer(forKey: "settings.rows")
        let cols = defaults.integer(forKey: "settings.columns")
        let timeLimit = defaults.double(forKey: "timeLimit")
        if missing > 0 || rows > 0 || cols > 0 || timeLimit > 0 {
            configuration = (try? PuzzleConfiguration(
                rows: rows > 0 ? rows : configuration.rows,
                columns: cols > 0 ? cols : configuration.columns,
                missingTileCount: missing > 0 ? missing : configuration.missingTileCount,
                timeLimit: timeLimit > 0 ? timeLimit : configuration.timeLimit,
                mode: configuration.mode
            )) ?? configuration
        }
        let seed = defaults.integer(forKey: "puzzleSeed") > 0 ? UInt64(defaults.integer(forKey: "puzzleSeed")) : nil
        session = PuzzleSession(source: .bundled(template), configuration: configuration, seed: seed)
    }
}
