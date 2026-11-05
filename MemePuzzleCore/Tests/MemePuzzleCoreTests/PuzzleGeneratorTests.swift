import XCTest
@testable import MemePuzzleCore

final class PuzzleGeneratorTests: XCTestCase {
    func testDefaultConfigurationIsTenByTen() {
        XCTAssertEqual(PuzzleConfiguration.standard.rows, 10)
        XCTAssertEqual(PuzzleConfiguration.standard.columns, 10)
    }

    func testConfigurationRejectsInvalidValues() {
        XCTAssertThrowsError(try PuzzleConfiguration(rows: 1, columns: 10, missingTileCount: 1))
        XCTAssertThrowsError(try PuzzleConfiguration(rows: 10, columns: 10, missingTileCount: 0))
        XCTAssertThrowsError(try PuzzleConfiguration(rows: 3, columns: 3, missingTileCount: 10)) {
            XCTAssertEqual($0 as? PuzzleConfigurationError, .invalidMissingCount(requested: 10, maximum: 9))
        }
    }

    func testTilesHaveStableUniqueIdentifiersAndOriginalCoordinates() throws {
        let configuration = try PuzzleConfiguration(rows: 3, columns: 4, missingTileCount: 2)
        let tiles = PuzzleGenerator.makeTiles(for: configuration)

        XCTAssertEqual(tiles.count, 12)
        XCTAssertEqual(Set(tiles.map(\.id)).count, 12)
        XCTAssertEqual(Set(tiles.map(\.correctPosition)).count, 12)
        XCTAssertEqual(tiles[0].correctPosition, GridPosition(row: 0, column: 0))
        XCTAssertEqual(tiles[5].correctPosition, GridPosition(row: 1, column: 1))
        XCTAssertEqual(tiles[11].correctPosition, GridPosition(row: 2, column: 3))
        XCTAssertEqual(PuzzleGenerator.makeTiles(for: configuration), tiles, "identifiers must be stable")
    }

    func testLayoutRemovesExactlyTheConfiguredNumberOfTiles() throws {
        let configuration = try PuzzleConfiguration(rows: 10, columns: 10, missingTileCount: 17)
        var rng = SeededRandomNumberGenerator(seed: 42)
        let layout = PuzzleGenerator.makeLayout(configuration: configuration, using: &rng)

        XCTAssertEqual(layout.tiles.count, 100)
        XCTAssertEqual(layout.missingPositions.count, 17)
        XCTAssertEqual(layout.trayOrder.count, 17)
        XCTAssertTrue(layout.missingPositions.allSatisfy(configuration.contains))
    }

    func testTrayContainsExactlyTheMissingTiles() throws {
        let configuration = try PuzzleConfiguration(rows: 10, columns: 10, missingTileCount: 25)
        var rng = SeededRandomNumberGenerator(seed: 7)
        let layout = PuzzleGenerator.makeLayout(configuration: configuration, using: &rng)

        let trayPositions = Set(layout.trayOrder.map { id in layout.tiles.first { $0.id == id }!.correctPosition })
        XCTAssertEqual(trayPositions, layout.missingPositions)
        XCTAssertEqual(Set(layout.trayOrder).count, layout.trayOrder.count, "no duplicate tiles in the tray")
    }

    func testTrayOrderIsShuffledAndNeverMatchesBoardOrder() throws {
        for seed in 0..<500 as Range<UInt64> {
            let configuration = try PuzzleConfiguration(rows: 4, columns: 4, missingTileCount: 2 + Int(seed % 5))
            var rng = SeededRandomNumberGenerator(seed: seed)
            let layout = PuzzleGenerator.makeLayout(configuration: configuration, using: &rng)
            XCTAssertNotEqual(layout.trayOrder, layout.trayOrder.sorted(), "seed \(seed)")
        }
    }

    func testIdentityShuffleIsCorrected() {
        struct IdentityShuffle: RandomNumberGenerator {
            // A raw value of 1 maps every `Int.random(in: 0..<n)` to 0 (no rejection loop),
            // so Swift's Fisher-Yates swaps every element with itself.
            mutating func next() -> UInt64 { 1 }
        }
        var rng = IdentityShuffle()
        let ordered = (0..<5).map(TileID.init)
        let shuffled = PuzzleGenerator.shuffledAvoidingIdentity(ordered, using: &rng)
        XCTAssertNotEqual(shuffled, ordered)
        XCTAssertEqual(shuffled.sorted(), ordered)
    }

    func testSameSeedReproducesSamePuzzleAndDifferentSeedsDiffer() throws {
        let configuration = PuzzleConfiguration.standard
        var a = SeededRandomNumberGenerator(seed: 99)
        var b = SeededRandomNumberGenerator(seed: 99)
        var c = SeededRandomNumberGenerator(seed: 100)

        let first = PuzzleGenerator.makeLayout(configuration: configuration, using: &a)
        XCTAssertEqual(first, PuzzleGenerator.makeLayout(configuration: configuration, using: &b))
        XCTAssertNotEqual(first, PuzzleGenerator.makeLayout(configuration: configuration, using: &c))
    }

    func testDifficultyModesHaveBalancedConfigurations() {
        let easy = DifficultyMode.easy.configuration
        XCTAssertEqual(easy.rows, 6)
        XCTAssertEqual(easy.columns, 6)
        XCTAssertEqual(easy.missingTileCount, 8)
        XCTAssertEqual(easy.timeLimit, 90)

        let medium = DifficultyMode.medium.configuration
        XCTAssertEqual(medium.rows, 8)
        XCTAssertEqual(medium.columns, 8)
        XCTAssertEqual(medium.missingTileCount, 18)
        XCTAssertEqual(medium.timeLimit, 60)

        let hard = DifficultyMode.hard.configuration
        XCTAssertEqual(hard.rows, 10)
        XCTAssertEqual(hard.columns, 10)
        XCTAssertEqual(hard.missingTileCount, 32)
        XCTAssertEqual(hard.timeLimit, 35)

        let extreme = DifficultyMode.extreme.configuration
        XCTAssertEqual(extreme.rows, 10)
        XCTAssertEqual(extreme.columns, 10)
        XCTAssertEqual(extreme.missingTileCount, 48)
        XCTAssertEqual(extreme.timeLimit, 20)
    }

    func testBlocksAreScatteredRandomlyAcrossTheImageGrid() {
        let config = DifficultyMode.easy.configuration
        var rng1 = SeededRandomNumberGenerator(seed: 1)
        var rng2 = SeededRandomNumberGenerator(seed: 2)
        let layout1 = PuzzleGenerator.makeLayout(configuration: config, using: &rng1)
        let layout2 = PuzzleGenerator.makeLayout(configuration: config, using: &rng2)

        XCTAssertEqual(layout1.missingPositions.count, 8)
        XCTAssertEqual(layout2.missingPositions.count, 8)
        // Different seeds produce different scattered missing block positions
        XCTAssertNotEqual(layout1.missingPositions, layout2.missingPositions)
        // Check helper method
        XCTAssertEqual(PuzzleGenerator.predeterminedEasyPositions(for: config).count, 8)
    }

    func testSingleMissingTileTray() throws {
        let configuration = try PuzzleConfiguration(rows: 2, columns: 2, missingTileCount: 1)
        let layout = PuzzleGenerator.makeLayout(configuration: configuration)
        XCTAssertEqual(layout.trayOrder.count, 1)
    }
}
