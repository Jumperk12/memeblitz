import Foundation

/// A cell in the puzzle grid, addressed by zero-based row and column.
public struct GridPosition: Hashable, Codable, Sendable, CustomStringConvertible {
    public let row: Int
    public let column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }

    public var description: String { "(r\(row), c\(column))" }
}

/// Stable identity of a tile. Identity is independent of where the tile is currently shown.
public struct TileID: Hashable, Codable, Sendable, Comparable, CustomStringConvertible {
    public let rawValue: Int

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }

    public static func < (lhs: TileID, rhs: TileID) -> Bool { lhs.rawValue < rhs.rawValue }

    public var description: String { "tile-\(rawValue)" }
}

/// Metadata for one image tile: its stable identifier and the grid cell it was cropped from.
public struct PuzzleTile: Identifiable, Hashable, Codable, Sendable {
    public let id: TileID
    /// The grid cell this tile's image content was cropped from. Placement is validated against this.
    public let correctPosition: GridPosition

    public init(id: TileID, correctPosition: GridPosition) {
        self.id = id
        self.correctPosition = correctPosition
    }
}

public enum PuzzleConfigurationError: Error, Equatable, Sendable {
    case invalidGrid(rows: Int, columns: Int)
    case invalidMissingCount(requested: Int, maximum: Int)
}

/// The four fixed competitive game modes.
public enum DifficultyMode: String, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    case easy
    case medium
    case hard
    case extreme

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        case .extreme: "Extreme"
        }
    }

    public var badge: String {
        switch self {
        case .easy: "6×6 · 8 pcs · 90s"
        case .medium: "8×8 · 18 pcs · 60s"
        case .hard: "10×10 · 32 pcs · 35s"
        case .extreme: "10×10 · 48 pcs · 20s"
        }
    }

    public var rows: Int {
        switch self {
        case .easy: 6
        case .medium: 8
        case .hard: 10
        case .extreme: 10
        }
    }

    public var columns: Int {
        switch self {
        case .easy: 6
        case .medium: 8
        case .hard: 10
        case .extreme: 10
        }
    }

    public var missingTileCount: Int {
        switch self {
        case .easy: 8
        case .medium: 18
        case .hard: 32
        case .extreme: 48
        }
    }

    public var timeLimit: TimeInterval {
        switch self {
        case .easy: 90
        case .medium: 60
        case .hard: 35
        case .extreme: 20
        }
    }

    public var configuration: PuzzleConfiguration {
        try! PuzzleConfiguration(
            rows: rows,
            columns: columns,
            missingTileCount: missingTileCount,
            timeLimit: timeLimit,
            mode: self
        )
    }
}

/// Grid dimensions, time limits, and difficulty configuration for one puzzle.
public struct PuzzleConfiguration: Hashable, Codable, Sendable {
    public static let supportedDimensions = 2...20

    public let rows: Int
    public let columns: Int
    public let missingTileCount: Int
    public let timeLimit: TimeInterval
    public let mode: DifficultyMode?

    public static let standard = try! PuzzleConfiguration(
        rows: 10,
        columns: 10,
        missingTileCount: 12,
        timeLimit: 60,
        mode: .hard
    )

    public init(
        rows: Int,
        columns: Int,
        missingTileCount: Int,
        timeLimit: TimeInterval = 60,
        mode: DifficultyMode? = nil
    ) throws {
        guard Self.supportedDimensions.contains(rows), Self.supportedDimensions.contains(columns) else {
            throw PuzzleConfigurationError.invalidGrid(rows: rows, columns: columns)
        }
        let total = rows * columns
        guard (1...total).contains(missingTileCount) else {
            throw PuzzleConfigurationError.invalidMissingCount(requested: missingTileCount, maximum: total)
        }
        self.rows = rows
        self.columns = columns
        self.missingTileCount = missingTileCount
        self.timeLimit = timeLimit
        self.mode = mode
    }

    public var tileCount: Int { rows * columns }

    public var effectiveMode: DifficultyMode {
        if let mode { return mode }
        if rows <= 6 && columns <= 6 { return .easy }
        if rows <= 8 && columns <= 8 { return .medium }
        if missingTileCount >= 40 { return .extreme }
        return .hard
    }

    public func contains(_ position: GridPosition) -> Bool {
        (0..<rows).contains(position.row) && (0..<columns).contains(position.column)
    }

    /// Row-major identifier for the tile cropped from `position`.
    public func tileID(for position: GridPosition) -> TileID {
        TileID(position.row * columns + position.column)
    }
}
