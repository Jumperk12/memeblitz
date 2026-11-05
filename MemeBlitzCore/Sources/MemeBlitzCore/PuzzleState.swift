import Foundation

/// Why a placement attempt was refused. A refused tile always stays in the tray.
public enum PlacementRejection: Error, Equatable, Sendable {
    /// The cell is empty, but the tile was cropped from a different cell.
    case wrongPosition(expected: GridPosition)
    /// The cell already contains a tile (prefilled or previously placed).
    case slotOccupied
    /// The drop location is outside the board.
    case outOfBounds
    /// The tile is not currently waiting in the tray (unknown, or already placed).
    case tileNotInTray
    /// The puzzle is already solved; further moves are ignored.
    case puzzleAlreadyComplete
    /// The countdown timer has expired and the puzzle is locked.
    case timeExpired
}

public enum PlacementResult: Equatable, Sendable {
    case placed(TileID, GridPosition, completedPuzzle: Bool)
    case rejected(PlacementRejection)

    public var isSuccess: Bool {
        if case .placed = self { return true }
        return false
    }
}

public struct PuzzleProgress: Equatable, Sendable {
    public let placed: Int
    public let total: Int

    public var remaining: Int { total - placed }
    public var fraction: Double { total == 0 ? 1 : Double(placed) / Double(total) }
}

/// Pure game state: which cells are filled, what remains in the tray, and move statistics.
///
/// Rendering code reads this state; it never decides correctness itself.
public struct PuzzleState: Equatable, Sendable {
    public let layout: PuzzleLayout
    /// Tile currently shown in each filled cell.
    public private(set) var board: [GridPosition: TileID]
    /// Tiles waiting to be placed, in display order.
    public private(set) var tray: [TileID]
    public private(set) var moveCount = 0
    public private(set) var mistakeCount = 0
    /// Locked when the countdown timer expires. Prevents further placements.
    public private(set) var isLocked: Bool = false

    private let tilesByID: [TileID: PuzzleTile]

    public init(layout: PuzzleLayout) {
        self.layout = layout
        tilesByID = Dictionary(uniqueKeysWithValues: layout.tiles.map { ($0.id, $0) })
        var board: [GridPosition: TileID] = [:]
        for tile in layout.tiles where !layout.missingPositions.contains(tile.correctPosition) {
            board[tile.correctPosition] = tile.id
        }
        self.board = board
        tray = layout.trayOrder
    }

    public var configuration: PuzzleConfiguration { layout.configuration }

    public func tile(_ id: TileID) -> PuzzleTile? { tilesByID[id] }

    public func tile(at position: GridPosition) -> TileID? { board[position] }

    public func isEmpty(_ position: GridPosition) -> Bool {
        configuration.contains(position) && board[position] == nil
    }

    public var emptyPositions: [GridPosition] {
        layout.tiles.map(\.correctPosition).filter { board[$0] == nil }
    }

    public var progress: PuzzleProgress {
        PuzzleProgress(placed: layout.trayOrder.count - tray.count, total: layout.trayOrder.count)
    }

    /// Complete only when every cell is filled by the tile that was cropped from that exact cell.
    public var isComplete: Bool {
        board.count == configuration.tileCount
            && board.allSatisfy { position, id in tilesByID[id]?.correctPosition == position }
    }

    /// Locks the board when time expires.
    public mutating func lock() {
        isLocked = true
    }

    /// Unlocks the board when an extension / reward is granted.
    public mutating func unlock() {
        isLocked = false
    }

    /// Checks a placement without mutating state.
    public func validate(_ id: TileID, at position: GridPosition) -> PlacementRejection? {
        if isComplete { return .puzzleAlreadyComplete }
        if isLocked { return .timeExpired }
        guard configuration.contains(position) else { return .outOfBounds }
        guard tray.contains(id), let tile = tilesByID[id] else { return .tileNotInTray }
        guard board[position] == nil else { return .slotOccupied }
        guard tile.correctPosition == position else { return .wrongPosition(expected: tile.correctPosition) }
        return nil
    }

    /// Attempts to move a tray tile into a cell. Wrong drops are counted as mistakes and leave the tray untouched.
    @discardableResult
    public mutating func place(_ id: TileID, at position: GridPosition) -> PlacementResult {
        if let rejection = validate(id, at: position) {
            if case .wrongPosition = rejection {
                moveCount += 1
                mistakeCount += 1
            }
            return .rejected(rejection)
        }
        tray.removeAll { $0 == id }
        board[position] = id
        moveCount += 1
        return .placed(id, position, completedPuzzle: isComplete)
    }
}
