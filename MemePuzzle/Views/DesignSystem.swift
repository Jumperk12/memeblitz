import MemePuzzleCore
import SwiftUI
import UIKit

// MARK: - A. Section Header Component

public struct ArcadeSectionHeader: View {
    public let title: String
    public let subtitle: String?
    public let icon: String?
    public let badgeText: String?
    public let accentColor: Color

    public init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        badgeText: String? = nil,
        accentColor: Color = Theme.neonViolet
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.badgeText = badgeText
        self.accentColor = accentColor
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 10) {
            if let icon {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.18))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accentColor)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: 13, weight: .black))
                    .tracking(1.4)
                    .foregroundStyle(accentColor)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.6))
                }
            }

            Spacer()

            if let badgeText {
                Text(badgeText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - B. Progress Bar Component

public struct ArcadeProgressBar: View {
    public let progress: Double
    public let height: CGFloat
    public let gradient: LinearGradient
    public let showGlow: Bool

    public init(
        progress: Double,
        height: CGFloat = 8,
        gradient: LinearGradient = LinearGradient(colors: [Theme.neonViolet, Theme.neonGold], startPoint: .leading, endPoint: .trailing),
        showGlow: Bool = true
    ) {
        self.progress = max(0.0, min(1.0, progress))
        self.height = height
        self.gradient = gradient
        self.showGlow = showGlow
    }

    public var body: some View {
        GeometryReader { geo in
            let fillWidth = max(height, geo.size.width * CGFloat(progress))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: height)

                Capsule()
                    .fill(gradient)
                    .frame(width: fillWidth, height: height)
                    .shadow(color: showGlow ? Theme.neonViolet.opacity(0.6) : .clear, radius: 4)
            }
        }
        .frame(height: height)
    }
}

// MARK: - C. Player Stat Card Component

public struct ArcadeStatCard: View {
    public let label: String
    public let value: String
    public let icon: String
    public let accentColor: Color

    public init(label: String, value: String, icon: String, accentColor: Color = Theme.neonViolet) {
        self.label = label
        self.value = value
        self.icon = icon
        self.accentColor = accentColor
    }

    public var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accentColor)
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .tracking(0.6)
                    .foregroundStyle(Color.white.opacity(0.55))
            }

            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .arcadeGlass(
            stroke: accentColor.opacity(0.28),
            cornerRadius: 14,
            fillOpacity: 0.08
        )
    }
}

// MARK: - D. Difficulty Filter Bar Component

public struct ArcadeDifficultyFilterBar: View {
    @Binding public var selectedFilter: DifficultyMode?
    public let counts: [DifficultyMode?: Int]
    public let onSelect: ((DifficultyMode?) -> Void)?

    public init(
        selectedFilter: Binding<DifficultyMode?>,
        counts: [DifficultyMode?: Int] = [:],
        onSelect: ((DifficultyMode?) -> Void)? = nil
    ) {
        self._selectedFilter = selectedFilter
        self.counts = counts
        self.onSelect = onSelect
    }

    private let filterOptions: [DifficultyMode?] = [
        nil,
        .easy,
        .medium,
        .hard,
        .extreme
    ]

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filterOptions, id: \.self) { mode in
                    let isSelected = selectedFilter == mode
                    let title = filterTitle(for: mode)
                    let count = counts[mode]
                    let tint = filterColor(for: mode)

                    Button {
                        AudioManager.shared.playTap()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            selectedFilter = mode
                        }
                        onSelect?(mode)
                    } label: {
                        HStack(spacing: 5) {
                            Text(title)
                                .font(.system(size: 12, weight: isSelected ? .heavy : .semibold))
                                .foregroundStyle(isSelected ? .white : Color.white.opacity(0.7))

                            if let count {
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(isSelected ? tint : Color.white.opacity(0.4))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1.5)
                                    .background(isSelected ? Color.black.opacity(0.4) : Color.white.opacity(0.06))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                if isSelected {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [tint.opacity(0.35), tint.opacity(0.18)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                } else {
                                    Capsule()
                                        .fill(Color.white.opacity(0.05))
                                }
                            }
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(isSelected ? tint.opacity(0.8) : Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: isSelected ? tint.opacity(0.4) : .clear, radius: 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    private func filterTitle(for mode: DifficultyMode?) -> String {
        guard let mode else { return "All" }
        switch mode {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .extreme: return "Extreme"
        }
    }

    private func filterColor(for mode: DifficultyMode?) -> Color {
        guard let mode else { return Theme.neonViolet }
        switch mode {
        case .easy: return Theme.easyEmerald
        case .medium: return Theme.mediumAmber
        case .hard: return Theme.hardMagenta
        case .extreme: return Theme.extremeCrimson
        }
    }
}

// MARK: - E. Meme Gallery Card Component

public struct MemeGalleryCard: View {
    public let template: MemeTemplate
    public let isSolved: Bool
    public let isPlayable: Bool
    public let requirementText: String
    public let bestTime: Double?
    public let action: () -> Void

    public init(
        template: MemeTemplate,
        isSolved: Bool,
        isPlayable: Bool = true,
        requirementText: String = "",
        bestTime: Double? = nil,
        action: @escaping () -> Void
    ) {
        self.template = template
        self.isSolved = isSolved
        self.isPlayable = isPlayable
        self.requirementText = requirementText
        self.bestTime = bestTime
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Meme Artwork Thumbnail (ONLY revealed if collected/solved!)
                thumbnailView

                // Metadata Details
                metadataView
            }
            .padding(7)
            .arcadeGlass(
                stroke: isSolved ? Theme.neonGold.opacity(0.42) : Color.white.opacity(0.09),
                cornerRadius: 18,
                fillOpacity: isSolved ? 0.08 : 0.04
            )
            .shadow(color: isSolved ? Theme.neonGold.opacity(0.12) : Color.clear, radius: 8)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("meme.\(template.id)")
    }

    @ViewBuilder
    private var thumbnailView: some View {
        ZStack(alignment: .topTrailing) {
            if isSolved {
                solvedArtworkView
                solvedBadgeView
            } else {
                mysteryBoxView
                playableBadgeView
            }
        }
    }

    @ViewBuilder
    private var solvedArtworkView: some View {
        if let url = Bundle.main.url(forResource: template.resourceName, withExtension: "jpg"),
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(Color.white.opacity(0.25))
                )
        }
    }

    @ViewBuilder
    private var solvedBadgeView: some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill")
                .font(.system(size: 9))
                .foregroundStyle(Theme.neonGold)
            Text("SOLVED")
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(Theme.neonGold)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.85))
        .clipShape(Capsule())
        .overlay(
            Capsule().strokeBorder(Theme.neonGold.opacity(0.5), lineWidth: 0.8)
        )
        .padding(6)
    }

    @ViewBuilder
    private var mysteryBoxView: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                RadialGradient(
                    colors: [Color(red: 0.16, green: 0.08, blue: 0.28), Color(red: 0.06, green: 0.04, blue: 0.12)],
                    center: .center,
                    startRadius: 5,
                    endRadius: 90
                )
            )
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Circle()
                    .fill(Color.black.opacity(0.45))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle().strokeBorder(Theme.neonGold.opacity(0.4), lineWidth: 1.5)
                    )
                    .overlay(
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.neonGold)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.neonViolet.opacity(0.25), lineWidth: 1)
            )
    }

    @ViewBuilder
    private var playableBadgeView: some View {
        HStack(spacing: 3) {
            Image(systemName: isPlayable ? "bolt.fill" : "lock.fill")
                .font(.system(size: 8))
                .foregroundStyle(isPlayable ? Theme.easyEmerald : Theme.neonGold)
            Text(isPlayable ? "READY" : "LOCKED")
                .font(.system(size: 7, weight: .black))
                .foregroundStyle(isPlayable ? Theme.easyEmerald : Theme.neonGold)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.85))
        .clipShape(Capsule())
        .overlay(
            Capsule().strokeBorder((isPlayable ? Theme.easyEmerald : Theme.neonGold).opacity(0.4), lineWidth: 0.8)
        )
        .padding(6)
    }

    @ViewBuilder
    private var metadataView: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(template.displayTitle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
            }

            // Requirement / Unlock notice for uncollected memes
            if !isSolved && !requirementText.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: isPlayable ? "sparkles" : "lock.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(isPlayable ? Theme.easyEmerald : Theme.neonGold)
                    Text(requirementText)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isPlayable ? Theme.easyEmerald : Theme.neonGold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 1)
            }

            HStack(spacing: 5) {
                Text(template.category.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(modeColor(template.difficultyMode))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(modeColor(template.difficultyMode).opacity(0.14))
                    .clipShape(Capsule())

                Spacer()

                if isSolved {
                    Text("Restored")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.neonGold)
                } else {
                    Text(isPlayable ? "Playable" : "Locked")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(isPlayable ? Theme.easyEmerald : Color.white.opacity(0.45))
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }

    private func modeColor(_ mode: DifficultyMode) -> Color {
        switch mode {
        case .easy: return Theme.easyEmerald
        case .medium: return Theme.mediumAmber
        case .hard: return Theme.hardMagenta
        case .extreme: return Theme.extremeCrimson
        }
    }
}
