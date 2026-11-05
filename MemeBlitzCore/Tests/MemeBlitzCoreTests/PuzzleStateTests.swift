import XCTest
@testable import MemeBlitzCore

final class PuzzleStateTests: XCTestCase {
    private func makeState(missing: Int = 6, seed: UInt64 = 3) throws -> PuzzleState {
        let configuration = try PuzzleConfiguration(rows: 5, columns: 5, missingTileCount: missing)
        var rng = SeededRandomNumberGenerator(seed: seed)
        return PuzzleState(layout: PuzzleGenerator.makeLayout(configuration: configuration, using: &rng))
    }

    func testInitialBoardHasPrefilledTilesInTheirCorrectCellsAndEmptyMissingCells() throws {
        let state = try makeState()

        XCTAssertEqual(state.board.count, 25 - 6)
        for (position, id) in state.board {
            XCTAssertEqual(state.tile(id)?.correctPosition, position)
        }
        XCTAssertEqual(Set(state.emptyPositions), state.layout.missingPositions)
        XCTAssertEqual(state.progress, PuzzleProgress(placed: 0, total: 6))
        XCTAssertFalse(state.isComplete)
    }

    func testCorrectPlacementMovesTileFromTrayToBoard() throws {
        var state = try makeState()
        let id = state.tray[0]
        let target = state.tile(id)!.correctPosition

        let result = state.place(id, at: target)

        XCTAssertEqual(result, .placed(id, target, completedPuzzle: false))
        XCTAssertEqual(state.tile(at: target), id)
        XCTAssertFalse(state.tray.contains(id))
        XCTAssertEqual(state.progress.placed, 1)
        XCTAssertEqual(state.progress.remaining, 5)
        XCTAssertEqual(state.moveCount, 1)
        XCTAssertEqual(state.mistakeCount, 0)
    }

    func testWrongEmptyCellIsRejectedByCoordinatesAndTileStaysInTray() throws {
        var state = try makeState()
        let id = state.tray[0]
        let correct = state.tile(id)!.correctPosition
        let wrong = try XCTUnwrap(state.emptyPositions.first { $0 != correct })
        let trayBefore = state.tray

        let result = state.place(id, at: wrong)

        XCTAssertEqual(result, .rejected(.wrongPosition(expected: correct)))
        XCTAssertNil(state.tile(at: wrong))
        XCTAssertEqual(state.tray, trayBefore, "rejected tiles keep their tray slot")
        XCTAssertEqual(state.mistakeCount, 1)
        XCTAssertEqual(state.progress.placed, 0)
    }

    func testValidationUsesOriginalCoordinatesNotAppearance() throws {
        // Even if two tiles looked identical (e.g. a flat sky), only the one cropped from the cell is accepted.
        var state = try makeState(missing: 2)
        let first = state.tray[0], second = state.tray[1]
        let firstTarget = state.tile(first)!.correctPosition

        XCTAssertEqual(state.place(second, at: firstTarget), .rejected(.wrongPosition(expected: state.tile(second)!.correctPosition)))
        XCTAssertTrue(state.place(first, at: firstTarget).isSuccess)
    }

    func testOccupiedOutOfBoundsAndUnknownTilesAreRejected() throws {
        var state = try makeState()
        let id = state.tray[0]
        let filled = try XCTUnwrap(state.board.keys.first)

        XCTAssertEqual(state.place(id, at: filled), .rejected(.slotOccupied))
        XCTAssertEqual(state.place(id, at: GridPosition(row: 5, column: 0)), .rejected(.outOfBounds))
        XCTAssertEqual(state.place(id, at: GridPosition(row: -1, column: 2)), .rejected(.outOfBounds))
        XCTAssertEqual(state.place(TileID(999), at: state.emptyPositions[0]), .rejected(.tileNotInTray))
        let prefilledTile = state.board[filled]!
        XCTAssertEqual(state.place(prefilledTile, at: state.emptyPositions[0]), .rejected(.tileNotInTray))
        XCTAssertEqual(state.tray.count, 6)
        XCTAssertEqual(state.mistakeCount, 0, "only wrong-cell drops count as mistakes")
    }

    func testRepeatedPlacementOfTheSameTileIsIgnored() throws {
        var state = try makeState()
        let id = state.tray[0]
        let target = state.tile(id)!.correctPosition

        XCTAssertTrue(state.place(id, at: target).isSuccess)
        XCTAssertEqual(state.place(id, at: target), .rejected(.tileNotInTray))
        XCTAssertEqual(state.progress.placed, 1)
        XCTAssertEqual(state.moveCount, 1)
    }

    func testPuzzleCompletesOnlyAfterEveryMissingTileIsCorrectlyPlaced() throws {
        var state = try makeState(missing: 8)
        let ids = state.tray

        for (index, id) in ids.enumerated() {
            XCTAssertFalse(state.isComplete)
            let result = state.place(id, at: state.tile(id)!.correctPosition)
            let isLast = index == ids.count - 1
            XCTAssertEqual(result, .placed(id, state.tile(id)!.correctPosition, completedPuzzle: isLast))
        }

        XCTAssertTrue(state.isComplete)
        XCTAssertTrue(state.tray.isEmpty)
        XCTAssertEqual(state.progress.fraction, 1)
        XCTAssertEqual(state.board.count, 25)
    }

    func testWrongDropsNeverCompleteThePuzzle() throws {
        var state = try makeState(missing: 3)
        for id in state.tray {
            for position in state.emptyPositions where position != state.tile(id)!.correctPosition {
                _ = state.place(id, at: position)
            }
        }
        XCTAssertFalse(state.isComplete)
        XCTAssertEqual(state.tray.count, 3)
        XCTAssertEqual(state.emptyPositions.count, 3)
    }

    func testLockPreventsPlacementsAndUnlockRestoresThem() throws {
        var state = try makeState(missing: 3)
        let id = state.tray[0]
        let target = state.tile(id)!.correctPosition

        state.lock()
        XCTAssertTrue(state.isLocked)
        XCTAssertEqual(state.place(id, at: target), .rejected(.timeExpired))
        XCTAssertEqual(state.progress.placed, 0)
        XCTAssertTrue(state.tray.contains(id))

        state.unlock()
        XCTAssertFalse(state.isLocked)
        XCTAssertEqual(state.place(id, at: target), .placed(id, target, completedPuzzle: false))
        XCTAssertEqual(state.progress.placed, 1)
    }

    func testMovesAfterCompletionAreRejected() throws {
        var state = try makeState(missing: 1)
        let id = state.tray[0]
        XCTAssertEqual(state.place(id, at: state.tile(id)!.correctPosition), .placed(id, state.tile(id)!.correctPosition, completedPuzzle: true))
        XCTAssertEqual(state.place(id, at: GridPosition(row: 0, column: 0)), .rejected(.puzzleAlreadyComplete))
    }

    func testFullyMissingBoardCanBeSolved() throws {
        var state = try makeState(missing: 25)
        XCTAssertTrue(state.board.isEmpty)
        for id in state.tray { state.place(id, at: state.tile(id)!.correctPosition) }
        XCTAssertTrue(state.isComplete)
    }
}
