import Foundation

/// Deterministic SplitMix64 generator so puzzles can be reproduced from a seed (tests, UI tests, sharing).
public struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// The generated, UI-independent description of a puzzle.
public struct PuzzleLayout: Hashable, Sendable {
    public let configuration: PuzzleConfiguration
    /// Every tile in row-major order.
    public let tiles: [PuzzleTile]
    /// Grid cells that start empty.
    public let missingPositions: Set<GridPosition>
    /// Missing tiles in the shuffled order they appear in the tray.
    public let trayOrder: [TileID]
}

public enum PuzzleGenerator {
    /// Creates tile metadata for every grid cell in row-major order.
    public static func makeTiles(for configuration: PuzzleConfiguration) -> [PuzzleTile] {
        var tiles: [PuzzleTile] = []
        tiles.reserveCapacity(configuration.tileCount)
        for row in 0..<configuration.rows {
            for column in 0..<configuration.columns {
                let position = GridPosition(row: row, column: column)
                tiles.append(PuzzleTile(id: configuration.tileID(for: position), correctPosition: position))
            }
        }
        return tiles
    }

    public static func makeLayout(configuration: PuzzleConfiguration) -> PuzzleLayout {
        var generator = SystemRandomNumberGenerator()
        return makeLayout(configuration: configuration, using: &generator)
    }

    /// Generates the puzzle layout with prefilled and missing pieces.
    /// Missing blocks are scattered randomly along the image grid across all modes.
    public static func makeLayout<G: RandomNumberGenerator>(
        configuration: PuzzleConfiguration,
        using generator: inout G
    ) -> PuzzleLayout {
        let tiles = makeTiles(for: configuration)
        // Missing blocks are scattered randomly across the image grid
        let missingTiles = Array(tiles.shuffled(using: &generator).prefix(configuration.missingTileCount))

        let boardOrder = missingTiles.map(\.id).sorted()
        return PuzzleLayout(
            configuration: configuration,
            tiles: tiles,
            missingPositions: Set(missingTiles.map(\.correctPosition)),
            trayOrder: shuffledAvoidingIdentity(boardOrder, using: &generator)
        )
    }

    /// Predetermined approachable central positions for introductory easy puzzles.
    public static func predeterminedEasyPositions(for configuration: PuzzleConfiguration) -> [GridPosition] {
        let midRow = configuration.rows / 2
        let midCol = configuration.columns / 2
        return [
            GridPosition(row: midRow - 1, column: midCol - 1),
            GridPosition(row: midRow - 1, column: midCol),
            GridPosition(row: midRow, column: midCol - 1),
            GridPosition(row: midRow, column: midCol),
            GridPosition(row: midRow - 2, column: midCol - 1),
            GridPosition(row: midRow - 2, column: midCol),
            GridPosition(row: midRow + 1, column: midCol - 1),
            GridPosition(row: midRow + 1, column: midCol)
        ].filter { configuration.contains($0) }
    }

    static func shuffledAvoidingIdentity<G: RandomNumberGenerator>(
        _ ordered: [TileID],
        using generator: inout G
    ) -> [TileID] {
        guard ordered.count > 1 else { return ordered }
        var shuffled = ordered.shuffled(using: &generator)
        if shuffled == ordered {
            shuffled.append(shuffled.removeFirst())
        }
        return shuffled
    }
}
