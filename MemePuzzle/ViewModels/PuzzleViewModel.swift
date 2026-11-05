import MemePuzzleCore
import Observation
import SwiftUI

/// Result of the most recent drop, used for transient highlights, haptics and VoiceOver announcements.
struct PlacementFeedback: Equatable {
    enum Kind: Equatable {
        case correct
        case wrongSlot
        case occupied
        case timeExpired
    }

    let id = UUID()
    let kind: Kind
    let tile: TileID
    let position: GridPosition
}

/// Live drag state for the floating tile.
struct TileDrag: Equatable {
    let tile: TileID
    var location: CGPoint
}

/// Bridges the pure `PuzzleState` to SwiftUI with wall-clock countdown timer, failure handling, and rewarded ad continue.
@MainActor
@Observable
final class PuzzleViewModel {
    enum Phase: Equatable {
        case loading
        case playing
        case completed
        case timeUp
        case failed(String)
    }

    static let coordinateSpace = "puzzle"

    let session: PuzzleSession
    private(set) var phase: Phase = .loading
    private(set) var state: PuzzleState?
    private(set) var sliced: SlicedImage?
    private(set) var drag: TileDrag?
    private(set) var activeDragTile: TileID?
    private(set) var hoveredPosition: GridPosition?
    private(set) var selectedTile: TileID?
    private(set) var feedback: PlacementFeedback?

    // Timing & Competitive Countdown
    private(set) var totalTimeLimit: TimeInterval
    private(set) var timeRemaining: TimeInterval
    private(set) var targetDeadline: Date?
    private(set) var isTimerPaused: Bool = false
    private var pausedRemainingTime: TimeInterval?
    private(set) var isLowTime: Bool = false
    private(set) var pulseTrigger: Int = 0

    private(set) var startedAt = Date()
    private(set) var finishedAt: Date?
    private(set) var slotRejections: [GridPosition: Int] = [:]
    private(set) var trayRejections: [TileID: Int] = [:]
    var boardFrame: CGRect = .zero

    // Rewarded Ad state
    private(set) var isWatchingAd: Bool = false
    private(set) var adErrorMessage: String?
    private var didGrantContinue: Bool = false

    private var timerTask: Task<Void, Never>?
    private var hasTriggeredTimeUp: Bool = false
    private var nextSeed: UInt64?
    private var feedbackClearTask: Task<Void, Never>?

    init(session: PuzzleSession) {
        self.session = session
        let limit = session.configuration.timeLimit
        self.totalTimeLimit = limit
        self.timeRemaining = limit
        self.nextSeed = session.seed
    }

    var configuration: PuzzleConfiguration { session.configuration }

    var timeRemainingFraction: Double {
        guard totalTimeLimit > 0 else { return 0 }
        return max(0, min(1, timeRemaining / totalTimeLimit))
    }

    // MARK: Loading & Lifecycle

    func load() async {
        // Prevent re-slicing and resetting active session if already loaded
        // (e.g. when full-screen ad or modal views dismiss)
        guard sliced == nil else { return }

        phase = .loading
        stopTimer()
        let source = session.source
        let configuration = session.configuration
        do {
            let sliced = try await Task.detached(priority: .userInitiated) {
                let (image, top, bottom) = try await MemeRenderer.loadImage(for: source)
                let rendered = try MemeRenderer.render(image, topText: top, bottomText: bottom)
                do {
                    return try ImageSlicer.slice(rendered, configuration: configuration)
                } catch let error as ImageSlicingError {
                    throw MemeLoadingError.slicing(error)
                }
            }.value
            self.sliced = sliced
            startNewLayout()
        } catch {
            phase = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    /// Same puzzle, reset pieces and fresh timer.
    func retryCurrent() {
        guard sliced != nil else { return }
        startNewLayout()
    }

    /// Same meme, new randomized piece positions.
    func replay() {
        guard sliced != nil else { return }
        startNewLayout()
    }

    private func startNewLayout() {
        stopTimer()
        let layout: PuzzleLayout
        if let seed = nextSeed {
            var generator = SeededRandomNumberGenerator(seed: seed)
            layout = PuzzleGenerator.makeLayout(configuration: configuration, using: &generator)
            nextSeed = seed &+ 1
        } else {
            layout = PuzzleGenerator.makeLayout(configuration: configuration)
        }

        state = PuzzleState(layout: layout)
        drag = nil
        hoveredPosition = nil
        selectedTile = nil
        feedback = nil
        slotRejections = [:]
        trayRejections = [:]
        startedAt = Date()
        finishedAt = nil
        hasTriggeredTimeUp = false
        isLowTime = false
        pulseTrigger = 0
        adErrorMessage = nil

        totalTimeLimit = configuration.timeLimit
        timeRemaining = totalTimeLimit
        phase = .playing
        startTimer(duration: totalTimeLimit)
    }

    // MARK: Countdown Timer

    private func startTimer(duration: TimeInterval) {
        stopTimer()
        hasTriggeredTimeUp = false
        timeRemaining = duration
        targetDeadline = Date().addingTimeInterval(duration)
        isTimerPaused = false
        pausedRemainingTime = nil

        timerTask = Task { [weak self] in
            var lastTickSecond: Int = -1
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, !Task.isCancelled else { break }

                guard !self.isTimerPaused, let deadline = self.targetDeadline else { continue }
                let remaining = max(0, deadline.timeIntervalSince(Date()))
                self.timeRemaining = remaining

                let low = remaining <= 10.0 && remaining > 0
                if low != self.isLowTime {
                    self.isLowTime = low
                }

                // Play countdown tick sound effect and pulse when low time (<= 10 seconds)
                let currentSecond = Int(ceil(remaining))
                if low && currentSecond != lastTickSecond && currentSecond > 0 {
                    lastTickSecond = currentSecond
                    self.pulseTrigger &+= 1
                    AudioManager.shared.playWarningTick(isUrgent: currentSecond <= 5)
                }

                if remaining <= 0 {
                    self.timeExpired()
                    break
                }
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        targetDeadline = nil
    }

    /// Call when app goes to background or modal appears.
    func pauseTimer() {
        guard phase == .playing, !isTimerPaused, let deadline = targetDeadline else { return }
        isTimerPaused = true
        pausedRemainingTime = max(0, deadline.timeIntervalSince(Date()))
        stopTimer()
    }

    /// Call when app returns to foreground.
    func resumeTimer() {
        guard phase == .playing, isTimerPaused, let remaining = pausedRemainingTime else { return }
        isTimerPaused = false
        pausedRemainingTime = nil
        startTimer(duration: remaining)
    }

    /// Apply competitive penalty to timer (e.g. 10 seconds for using the peek eye button).
    func applyPeekPenalty(seconds: TimeInterval = 10.0) {
        guard phase == .playing, !hasTriggeredTimeUp else { return }
        if let deadline = targetDeadline {
            targetDeadline = deadline.addingTimeInterval(-seconds)
            timeRemaining = max(0, targetDeadline?.timeIntervalSince(Date()) ?? 0)
        } else {
            timeRemaining = max(0, timeRemaining - seconds)
        }
        pulseTrigger &+= 1
        if timeRemaining <= 0 {
            timeExpired()
        }
    }

    private func timeExpired() {
        guard !hasTriggeredTimeUp, phase == .playing else { return }
        hasTriggeredTimeUp = true
        stopTimer()
        timeRemaining = 0
        state?.lock()
        drag = nil
        hoveredPosition = nil
        selectedTile = nil
        AudioManager.shared.playFailure()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            phase = .timeUp
        }
    }

    // MARK: Rewarded Ad Continue

    func continueWithRewardedAd() {
        guard phase == .timeUp, !isWatchingAd else { return }
        isWatchingAd = true
        adErrorMessage = nil

        Task {
            let result = await RewardedAdService.shared.showRewardedAd(from: nil) { _ in
                // Acknowledged from AdMob SDK
            }
            isWatchingAd = false
            switch result {
            case .success(let extraSeconds):
                grantTimeExtension(seconds: TimeInterval(extraSeconds))
            case .failure(let error):
                adErrorMessage = error.localizedDescription
            }
        }
    }

    private func grantTimeExtension(seconds: TimeInterval) {
        guard phase == .timeUp else { return }
        didGrantContinue = true
        totalTimeLimit = seconds
        timeRemaining = seconds
        hasTriggeredTimeUp = false
        state?.unlock()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            phase = .playing
        }
        startTimer(duration: seconds)
    }

    // MARK: Queries & Drag-and-Drop

    func image(for tile: TileID) -> CGImage? { sliced?.tileImages[tile] }

    func position(at point: CGPoint) -> GridPosition? {
        guard boardFrame.width > 0, boardFrame.contains(point) else { return nil }
        let column = Int((point.x - boardFrame.minX) / (boardFrame.width / CGFloat(configuration.columns)))
        let row = Int((point.y - boardFrame.minY) / (boardFrame.height / CGFloat(configuration.rows)))
        let position = GridPosition(row: row, column: column)
        return configuration.contains(position) ? position : nil
    }

    var isInteractive: Bool { phase == .playing }

    func beginDrag(_ tile: TileID, at location: CGPoint) {
        guard isInteractive, state?.tray.contains(tile) == true else { return }
        if drag?.tile != tile {
            activeDragTile = tile
            drag = TileDrag(tile: tile, location: location)
            selectedTile = nil
        }
        updateDrag(to: location)
    }

    func updateDrag(to location: CGPoint) {
        guard drag != nil else { return }
        drag?.location = location
        let candidate = position(at: location)
        let target = candidate.flatMap { state?.isEmpty($0) == true ? $0 : nil }
        if target != hoveredPosition { hoveredPosition = target }
    }

    func endDrag(at location: CGPoint) {
        guard let current = drag else { return }
        updateDrag(to: location)
        let target = position(at: location)
        activeDragTile = nil
        drag = nil
        hoveredPosition = nil
        if let target {
            attemptPlacement(current.tile, at: target)
        }
    }

    func cancelDrag(_ tile: TileID) {
        guard drag?.tile == tile else { return }
        activeDragTile = nil
        drag = nil
        hoveredPosition = nil
    }

    func toggleSelection(_ tile: TileID) {
        guard isInteractive, state?.tray.contains(tile) == true else { return }
        selectedTile = selectedTile == tile ? nil : tile
    }

    func tapSlot(_ position: GridPosition) {
        guard isInteractive, let tile = selectedTile else { return }
        attemptPlacement(tile, at: position)
    }

    // MARK: Placement

    private func attemptPlacement(_ tile: TileID, at position: GridPosition) {
        guard var state else { return }
        let result = state.place(tile, at: position)
        self.state = state
        switch result {
        case .placed(_, _, let completed):
            if selectedTile == tile { selectedTile = nil }
            show(PlacementFeedback(kind: .correct, tile: tile, position: position))
            AudioManager.shared.playCorrect()
            if completed {
                stopTimer()
                finishedAt = Date()
                let elapsed = (finishedAt ?? Date()).timeIntervalSince(startedAt)
                if session.source.id.starts(with: "daily_") {
                    GameProfile.shared.recordDailyCompletion(
                        duration: elapsed,
                        mistakes: state.mistakeCount,
                        usedAd: didGrantContinue
                    )
                } else {
                    GameProfile.shared.recordCompletion(
                        mode: session.configuration.effectiveMode,
                        memeID: session.source.id,
                        duration: elapsed,
                        mistakes: state.mistakeCount,
                        usedAd: didGrantContinue
                    )
                }
                GameProfile.shared.saveNow()
                AudioManager.shared.playVictory()
                withAnimation(.easeInOut(duration: 0.6)) { phase = .completed }
            }
        case .rejected(.wrongPosition):
            recordRejection(tile, at: position)
            show(PlacementFeedback(kind: .wrongSlot, tile: tile, position: position))
            AudioManager.shared.playWrong()
        case .rejected(.slotOccupied):
            recordRejection(tile, at: position)
            show(PlacementFeedback(kind: .occupied, tile: tile, position: position))
            AudioManager.shared.playWrong()
        case .rejected(.timeExpired):
            show(PlacementFeedback(kind: .timeExpired, tile: tile, position: position))
            AudioManager.shared.playWrong()
        case .rejected:
            break
        }
    }

    private func recordRejection(_ tile: TileID, at position: GridPosition) {
        slotRejections[position, default: 0] += 1
        trayRejections[tile, default: 0] += 1
    }

    private func show(_ newFeedback: PlacementFeedback) {
        feedback = newFeedback
        feedbackClearTask?.cancel()
        feedbackClearTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled, self?.feedback?.id == newFeedback.id else { return }
            self?.feedback = nil
        }
    }
}
