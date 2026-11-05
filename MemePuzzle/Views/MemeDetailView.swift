import MemePuzzleCore
import SwiftUI
import UIKit

public struct MemeDetailView: View {
    public let template: MemeTemplate
    public let onPlay: (PuzzleSession) -> Void
    public let onDismiss: () -> Void

    @State private var profile = GameProfile.shared

    public init(
        template: MemeTemplate,
        onPlay: @escaping (PuzzleSession) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.template = template
        self.onPlay = onPlay
        self.onDismiss = onDismiss
    }

    private var mode: DifficultyMode {
        template.difficultyMode
    }

    private var configuration: PuzzleConfiguration {
        mode.configuration
    }

    private var isSolved: Bool {
        profile.isSolved(template.id)
    }

    private var isPlayable: Bool {
        let pool = MemeCatalog.memes(for: mode)
        let modeIndex = pool.firstIndex(where: { $0.id == template.id }) ?? 0
        return profile.isLevelUnlocked(mode: mode, index: modeIndex)
    }

    private var prerequisiteTitle: String {
        let pool = MemeCatalog.memes(for: mode)
        let modeIndex = pool.firstIndex(where: { $0.id == template.id }) ?? 0
        if modeIndex > 0 {
            return pool[modeIndex - 1].displayTitle
        } else if let numStr = template.id.split(separator: "_").last,
                  let num = Int(numStr), num > 1 {
            let padded = String(format: "%03d", num - 1)
            return "Meme #\(padded)"
        } else {
            switch mode {
            case .easy:
                return "Meme #001"
            case .medium:
                return MemeCatalog.easy.last?.displayTitle ?? "Easy Mode"
            case .hard:
                return MemeCatalog.medium.last?.displayTitle ?? "Medium Mode"
            case .extreme:
                return MemeCatalog.hard.last?.displayTitle ?? "Hard Mode"
            }
        }
    }

    private var requirementMessage: String {
        if isSolved {
            return "Restored & Collected"
        }
        if !isPlayable {
            return "Must unlock \(prerequisiteTitle) to play this one"
        }
        return "Solve puzzle to unlock artwork"
    }

    private var bestTime: Double? {
        profile.bestTime(forMeme: template.id)
    }

    public var body: some View {
        ZStack {
            // Dark arcade background
            Theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    Button {
                        AudioManager.shared.playTap()
                        onDismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("Vault")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundStyle(Theme.neonViolet)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Difficulty Tag
                    Text(template.category.uppercased())
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(modeColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(modeColor.opacity(0.18))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().strokeBorder(modeColor.opacity(0.5), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 10)

                ScrollView {
                    VStack(spacing: 20) {
                        // Large Artwork Card (Only shows artwork if meme is collected!)
                        artworkCardView

                        // Title & Item Number
                        VStack(spacing: 4) {
                            Text(template.displayTitle)
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)

                            Text("Meme ID: \(template.id)")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.45))
                        }

                        // Unlock Requirement Callout for uncollected memes
                        if !isSolved {
                            HStack(spacing: 8) {
                                Image(systemName: isPlayable ? "sparkles" : "lock.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(isPlayable ? Theme.easyEmerald : Theme.neonGold)
                                Text(requirementMessage)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(isPlayable ? Theme.easyEmerald : Theme.neonGold)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background((isPlayable ? Theme.easyEmerald : Theme.neonGold).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder((isPlayable ? Theme.easyEmerald : Theme.neonGold).opacity(0.35), lineWidth: 1)
                            )
                        }

                        // Specs Grid
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            specItem(
                                label: "Difficulty",
                                value: mode.title,
                                icon: "flame.fill",
                                tint: modeColor
                            )

                            specItem(
                                label: "Grid Size",
                                value: "\(configuration.columns)×\(configuration.rows)",
                                icon: "square.grid.3x3.fill",
                                tint: Theme.neonViolet
                            )

                            specItem(
                                label: "Missing Tiles",
                                value: "\(configuration.missingTileCount) Pieces",
                                icon: "puzzlepiece.fill",
                                tint: Theme.neonOrange
                            )

                            specItem(
                                label: "Best Time",
                                value: bestTime != nil ? GameProfile.formatTime(bestTime!) : "Unsolved",
                                icon: bestTime != nil ? "crown.fill" : "timer",
                                tint: bestTime != nil ? Theme.neonGold : Color.white.opacity(0.45)
                            )
                        }

                        // Play Puzzle CTA Button
                        if isPlayable {
                            Button {
                                AudioManager.shared.playTap()
                                let session = PuzzleSession(
                                    source: .bundled(template),
                                    configuration: configuration
                                )
                                onPlay(session)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 16, weight: .bold))
                                    Text(isSolved ? "REPLAY PUZZLE" : "PLAY PUZZLE (SOLVE TO UNLOCK)")
                                        .font(.system(size: 15, weight: .black))
                                        .tracking(0.8)
                                }
                                .foregroundStyle(Color.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Theme.neonGold, Color(red: 1.0, green: 0.65, blue: 0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                                )
                                .shadow(color: Theme.neonGold.opacity(0.45), radius: 12, y: 3)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 6)
                        } else {
                            // Locked State Button
                            HStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color.white.opacity(0.5))
                                Text("Must unlock \(prerequisiteTitle) to play this one")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.white.opacity(0.5))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .padding(.top, 6)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func specItem(label: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(tint)
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .tracking(0.6)
                    .foregroundStyle(Color.white.opacity(0.45))
            }

            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .arcadeGlass(
            stroke: tint.opacity(0.25),
            cornerRadius: 14,
            fillOpacity: 0.08
        )
    }

    @ViewBuilder
    private var artworkCardView: some View {
        ZStack(alignment: .bottomTrailing) {
            if isSolved {
                solvedArtView
                solvedArtBadgeView
            } else {
                mysteryArtView
            }
        }
        .padding(10)
        .arcadeGlass(
            stroke: isSolved ? Theme.neonGold.opacity(0.5) : modeColor.opacity(0.3),
            cornerRadius: 26,
            fillOpacity: 0.1
        )
        .shadow(color: modeColor.opacity(0.18), radius: 16)
    }

    @ViewBuilder
    private var solvedArtView: some View {
        if let url = Bundle.main.url(forResource: template.resourceName, withExtension: "jpg"),
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.white.opacity(0.3))
                )
        }
    }

    @ViewBuilder
    private var solvedArtBadgeView: some View {
        HStack(spacing: 6) {
            Image(systemName: "crown.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.neonGold)
            Text("SOLVED")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(Theme.neonGold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.85))
        .clipShape(Capsule())
        .overlay(
            Capsule().strokeBorder(Theme.neonGold.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Theme.neonGold.opacity(0.4), radius: 8)
        .padding(12)
    }

    @ViewBuilder
    private var mysteryArtView: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                RadialGradient(
                    colors: [Color(red: 0.18, green: 0.08, blue: 0.32), Color(red: 0.06, green: 0.04, blue: 0.12)],
                    center: .center,
                    startRadius: 10,
                    endRadius: 160
                )
            )
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.black.opacity(0.45))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle().strokeBorder(Theme.neonGold.opacity(0.45), lineWidth: 2)
                        )
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(Theme.neonGold)
                        )

                    Text(isPlayable ? "UNCOLLECTED" : "LOCKED")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.2)
                        .foregroundStyle(isPlayable ? Theme.easyEmerald : Theme.neonGold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().strokeBorder((isPlayable ? Theme.easyEmerald : Theme.neonGold).opacity(0.4), lineWidth: 1)
                        )
                }
            )
    }

    private var modeColor: Color {
        switch mode {
        case .easy: return Theme.easyEmerald
        case .medium: return Theme.mediumAmber
        case .hard: return Theme.hardMagenta
        case .extreme: return Theme.extremeCrimson
        }
    }
}
