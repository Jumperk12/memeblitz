import MemePuzzleCore
import SwiftUI

/// Arcade Level Select UI showing all meme stages for a specific difficulty mode.
/// Implements sequential level unlocking: Level 1 is unlocked initially,
/// and each subsequent level unlocks only after the previous level is completed.
struct LevelSelectView: View {
    let mode: DifficultyMode
    let onSelectSession: (PuzzleSession) -> Void
    let onBack: () -> Void

    @State private var profile = GameProfile.shared
    @State private var lockedAlertMessage: String?
    @State private var shakenLevelIndex: Int?

    private var modeAccent: Color {
        switch mode {
        case .easy: Theme.easyEmerald
        case .medium: Theme.mediumAmber
        case .hard: Theme.hardMagenta
        case .extreme: Theme.extremeCrimson
        }
    }

    private var modeIcon: String {
        switch mode {
        case .easy: "leaf.fill"
        case .medium: "bolt.fill"
        case .hard: "flame.fill"
        case .extreme: "skull.fill"
        }
    }

    private var templates: [MemeTemplate] {
        MemeCatalog.templates(for: mode)
    }

    private var unlockedCount: Int {
        let maxUnlocked = (profile.unlockedLevelByMode[mode.rawValue] ?? 0) + 1
        return min(maxUnlocked, templates.count)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar

            // Scrollable Grid of Level Memes (2 per row)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                        let isUnlocked = profile.isLevelUnlocked(mode: mode, index: index)
                        let isCompleted = profile.isCompleted(memeID: template.id)
                        let levelNum = index + 1

                        levelCard(
                            template: template,
                            index: index,
                            levelNum: levelNum,
                            isUnlocked: isUnlocked,
                            isCompleted: isCompleted
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 32)
            }
        }
        .background(Theme.background)
        .overlay(alignment: .bottom) {
            if let lockedAlertMessage {
                Text(lockedAlertMessage)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.85))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Theme.extremeCrimson.opacity(0.6), lineWidth: 1.5)
                    )
                    .shadow(color: Theme.extremeCrimson.opacity(0.4), radius: 10)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 12) {
            Button {
                AudioManager.shared.playTap()
                onBack()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                    Text("Back")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .arcadeGlass(cornerRadius: 18, fillOpacity: 0.12)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: modeIcon)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(modeAccent)

                    Text("\(mode.title.uppercased()) LEVELS")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text("\(unlockedCount) / \(templates.count) UNLOCKED")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(modeAccent)
            }

            Spacer()

            // Spacer to balance back button
            Color.clear
                .frame(width: 60, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Color.black.opacity(0.25))
    }

    // MARK: - Level Card

    private func levelCard(
        template: MemeTemplate,
        index: Int,
        levelNum: Int,
        isUnlocked: Bool,
        isCompleted: Bool
    ) -> some View {
        Button {
            if isUnlocked {
                AudioManager.shared.playTap()
                profile.selectedDifficulty = mode
                let session = PuzzleSession(
                    source: .bundled(template),
                    configuration: mode.configuration
                )
                onSelectSession(session)
            } else {
                AudioManager.shared.playWrong()
                shakenLevelIndex = index
                lockedAlertMessage = "🔒 Level \(levelNum) is locked! Complete Level \(levelNum - 1) first."
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if lockedAlertMessage?.contains("Level \(levelNum)") == true {
                        lockedAlertMessage = nil
                    }
                }
            }
        } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    // Meme Artwork
                    if let url = Bundle.main.url(forResource: template.resourceName, withExtension: "jpg"),
                       let uiImage = UIImage(contentsOfFile: url.path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .saturation(isUnlocked ? 1.0 : 0.15)
                            .opacity(isUnlocked ? 1.0 : 0.4)
                    } else {
                        Color.white.opacity(0.08)
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    // Level Number Badge (Top Left)
                    HStack {
                        Text("\(levelNum)")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(isUnlocked ? Color.black : Color.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(isUnlocked ? modeAccent : Color.white.opacity(0.2))
                            .clipShape(Capsule())
                        Spacer()
                    }
                    .padding(6)

                    // Completion / Lock Overlay
                    if !isUnlocked {
                        ZStack {
                            Color.black.opacity(0.65)
                            VStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 24, weight: .black))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black, radius: 4)
                                Text("LOCKED")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    } else if isCompleted {
                        // Checkmark Badge
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Theme.success)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .padding(6)
                    }
                }

                // Level Label & Status
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.title.isEmpty ? "Level \(levelNum)" : template.title)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(isUnlocked ? .white : .white.opacity(0.55))
                        .lineLimit(1)

                    Text(isUnlocked ? (isCompleted ? "✓ Completed" : "⚡ Ready") : "🔒 Locked")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isUnlocked ? (isCompleted ? Theme.success : modeAccent) : .white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .padding(8)
            .arcadeGlass(
                stroke: isUnlocked ? (isCompleted ? Theme.success.opacity(0.4) : modeAccent.opacity(0.45)) : Color.white.opacity(0.1),
                lineWidth: 1.2,
                cornerRadius: 18,
                fillOpacity: isUnlocked ? 0.12 : 0.04
            )
            .shake(trigger: shakenLevelIndex == index ? 1 : 0)
        }
        .buttonStyle(.plain)
    }
}
