import MemePuzzleCore
import Observation
import SwiftUI

@Observable
@MainActor
public final class CollectionViewModel {
    public var selectedFilter: DifficultyMode? = nil
    public var selectedMemeForDetail: MemeTemplate? = nil

    public var profile: GameProfile {
        GameProfile.shared
    }

    public init() {}

    public var filteredMemes: [MemeTemplate] {
        if let mode = selectedFilter {
            return MemeCatalog.memes(for: mode)
        }
        return MemeCatalog.bundled
    }

    public var totalCount: Int {
        MemeCatalog.bundled.count
    }

    public var collectedCount: Int {
        // Count how many bundled memes have been completed
        profile.completedMemeIDs.count
    }

    public var completionFraction: Double {
        guard totalCount > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(collectedCount) / Double(totalCount)))
    }

    public var completionPercentage: Int {
        Int((completionFraction * 100).rounded())
    }

    public var countsByFilter: [DifficultyMode?: Int] {
        [
            nil: MemeCatalog.bundled.count,
            .easy: MemeCatalog.easy.count,
            .medium: MemeCatalog.medium.count,
            .hard: MemeCatalog.hard.count,
            .extreme: MemeCatalog.extreme.count
        ]
    }

    public func isSolved(_ template: MemeTemplate) -> Bool {
        profile.isSolved(template.id)
    }

    public struct MemeUnlockStatus {
        public let isSolved: Bool
        public let isPlayable: Bool
        public let requirementText: String
        public let prerequisiteTitle: String

        public init(isSolved: Bool, isPlayable: Bool, requirementText: String, prerequisiteTitle: String) {
            self.isSolved = isSolved
            self.isPlayable = isPlayable
            self.requirementText = requirementText
            self.prerequisiteTitle = prerequisiteTitle
        }
    }

    public func unlockStatus(for template: MemeTemplate) -> MemeUnlockStatus {
        let solved = isSolved(template)
        if solved {
            return MemeUnlockStatus(
                isSolved: true,
                isPlayable: true,
                requirementText: "Restored & Collected",
                prerequisiteTitle: ""
            )
        }

        let mode = template.difficultyMode
        let pool = MemeCatalog.memes(for: mode)
        let modeIndex = pool.firstIndex(where: { $0.id == template.id }) ?? 0

        var prevTitle = ""
        if modeIndex > 0 {
            prevTitle = pool[modeIndex - 1].displayTitle
        } else if let numStr = template.id.split(separator: "_").last,
                  let num = Int(numStr), num > 1 {
            let padded = String(format: "%03d", num - 1)
            prevTitle = "Meme #\(padded)"
        } else {
            // First meme of mode
            switch mode {
            case .easy:
                prevTitle = ""
            case .medium:
                prevTitle = MemeCatalog.easy.last?.displayTitle ?? "Easy Mode"
            case .hard:
                prevTitle = MemeCatalog.medium.last?.displayTitle ?? "Medium Mode"
            case .extreme:
                prevTitle = MemeCatalog.hard.last?.displayTitle ?? "Hard Mode"
            }
        }

        let isPlayable = profile.isLevelUnlocked(mode: mode, index: modeIndex)

        if !isPlayable {
            let target = prevTitle.isEmpty ? "Meme #001" : prevTitle
            return MemeUnlockStatus(
                isSolved: false,
                isPlayable: false,
                requirementText: "Must unlock \(target) to play this one",
                prerequisiteTitle: target
            )
        }

        return MemeUnlockStatus(
            isSolved: false,
            isPlayable: true,
            requirementText: "Solve puzzle to unlock artwork",
            prerequisiteTitle: prevTitle
        )
    }

    public func bestTime(for template: MemeTemplate) -> Double? {
        profile.bestTime(forMeme: template.id)
    }

    public func selectMeme(_ template: MemeTemplate) {
        AudioManager.shared.playTap()
        selectedMemeForDetail = template
    }

    public func clearSelection() {
        selectedMemeForDetail = nil
    }

    public func makeSession(for template: MemeTemplate, mode: DifficultyMode? = nil) -> PuzzleSession {
        let activeMode = mode ?? template.difficultyMode
        let configuration = activeMode.configuration
        return PuzzleSession(source: .bundled(template), configuration: configuration)
    }

    public func onVaultAppear() {
        // Evaluate vault explorer achievement
        profile.unlock("vault_explorer")
        AchievementEngine.shared.evaluateProgress(profile: profile)
    }
}
