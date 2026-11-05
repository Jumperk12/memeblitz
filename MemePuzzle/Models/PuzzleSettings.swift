import Foundation
import MemePuzzleCore

/// Centralized player state: selected difficulty mode.
///
/// Player-controlled row/column sliders have been removed per competitive game design.
/// Each difficulty has immutable, balanced board dimensions, piece counts, and time limits.
struct PuzzleSettings: Equatable {
    var selectedDifficulty: DifficultyMode = .easy

    static let `default` = PuzzleSettings(selectedDifficulty: .easy)

    static func load(from defaults: UserDefaults = .standard) -> PuzzleSettings {
        let raw = defaults.string(forKey: "settings.difficulty") ?? DifficultyMode.easy.rawValue
        let diff = DifficultyMode(rawValue: raw) ?? .easy
        return PuzzleSettings(selectedDifficulty: diff)
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(selectedDifficulty.rawValue, forKey: "settings.difficulty")
    }
}
