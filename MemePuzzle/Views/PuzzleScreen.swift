import MemeBlitzCore
import SwiftUI

/// Hosts a single puzzle: competitive countdown header, framed board, tray, drag overlay, and completion/failure states.
struct PuzzleScreen: View {
    let onExit: () -> Void
    var onExitToLevels: (() -> Void)? = nil
    var onExitToChangeMode: (() -> Void)? = nil
    var onNextSession: ((PuzzleSession) -> Void)? = nil
    @State private var model: PuzzleViewModel
    @State private var isPeeking = false
    @StateObject private var reviewManager = AppReviewManager.shared
    @Environment(\.displayScale) private var displayScale
    @Environment(\.scenePhase) private var scenePhase

    init(
        session: PuzzleSession,
        onExit: @escaping () -> Void,
        onExitToLevels: (() -> Void)? = nil,
        onExitToChangeMode: (() -> Void)? = nil,
        onNextSession: ((PuzzleSession) -> Void)? = nil
    ) {
        self.onExit = onExit
        self.onExitToLevels = onExitToLevels
        self.onExitToChangeMode = onExitToChangeMode
        self.onNextSession = onNextSession
        _model = State(initialValue: PuzzleViewModel(session: session))
    }

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
            content
        }
        .overlay(alignment: .topLeading) {
            DragOverlayContainer(model: model)
        }
        .overlay {
            if model.phase == .timeUp {
                ZStack {
                    // Dark translucent backdrop
                    Color.black.opacity(0.68)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    // Centered Arcade Failure Modal
                    TimeUpPopupView(
                        model: model,
                        onTryAgain: { model.retryCurrent() },
                        onLevels: {
                            if let onExitToLevels {
                                onExitToLevels()
                            } else {
                                onExit()
                            }
                        },
                        onChangeMode: {
                            if let onExitToChangeMode {
                                onExitToChangeMode()
                            } else {
                                onExit()
                            }
                        }
                    )
                    .padding(.horizontal, 20)
                    .transition(.scale(scale: 0.93).combined(with: .opacity))
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: model.phase == .timeUp)
                .zIndex(100)
            } else if model.phase == .completed {
                ZStack {
                    // Dark translucent backdrop
                    Color.black.opacity(0.68)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    // Centered Arcade Completion Modal
                    CompletionPopupView(
                        model: model,
                        title: model.session.source.title,
                        onReplay: { model.replay() },
                        onLevels: {
                            if let onExitToLevels {
                                onExitToLevels()
                            } else {
                                onExit()
                            }
                        },
                        onHome: {
                            onExit()
                        },
                        onNextLevel: {
                            advanceToNextLevel()
                        }
                    )
                    .padding(.horizontal, 20)
                    .transition(.scale(scale: 0.93).combined(with: .opacity))

                    // Celebratory Confetti Burst
                    ConfettiView()
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: model.phase == .completed)
                .zIndex(100)
            }

            // App Store Review Request after first 2 completed puzzles
            if reviewManager.showReviewPrompt {
                ZStack {
                    Color.black.opacity(0.72)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    AppReviewPromptView(
                        onRate: {
                            reviewManager.requestNativeReview()
                        },
                        onDismiss: {
                            reviewManager.dismissPrompt()
                        }
                    )
                    .padding(.horizontal, 20)
                    .transition(.scale(scale: 0.93).combined(with: .opacity))
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: reviewManager.showReviewPrompt)
                .zIndex(200)
            }
        }
        .coordinateSpace(name: PuzzleViewModel.coordinateSpace)
        .task { await model.load() }
        .onChange(of: model.phase) { _, newPhase in
            if newPhase == .completed {
                reviewManager.checkMilestone()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                model.resumeTimer()
            case .inactive, .background:
                model.pauseTimer()
            @unknown default:
                break
            }
        }
        .sensoryFeedback(trigger: model.feedback) { _, new in
            switch new?.kind {
            case .correct: .impact(weight: .medium)
            case .wrongSlot, .occupied: .error
            case .timeExpired: .error
            case nil: nil
            }
        }
        .sensoryFeedback(.success, trigger: model.phase == .completed)
        .sensoryFeedback(.error, trigger: model.phase == .timeUp)
        .sensoryFeedback(.selection, trigger: model.drag?.tile)
        .sensoryFeedback(.warning, trigger: model.pulseTrigger)
        .onChange(of: model.feedback) { _, new in announce(new) }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .loading:
            VStack(spacing: 14) {
                ProgressView().controlSize(.large).tint(.white)
                Text("Slicing your meme…").foregroundStyle(.white.opacity(0.8))
            }
            .accessibilityIdentifier("loading")
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn’t load this meme", systemImage: "photo.badge.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { Task { await model.load() } }
                    .buttonStyle(.borderedProminent)
                Button("Back to Memes", action: onExit)
            }
            .foregroundStyle(.white)
        case .playing, .completed, .timeUp:
            if let state = model.state, let sliced = model.sliced {
                game(state: state, sliced: sliced)
            }
        }
    }

    private func game(state: PuzzleState, sliced: SlicedImage) -> some View {
        VStack(spacing: 14) {
            PuzzleHeader(model: model, state: state, isPeeking: $isPeeking, onExit: onExit)
                .padding(.horizontal, 16)

            GeometryReader { proxy in
                let metrics = BoardMetrics.fit(
                    available: CGSize(width: proxy.size.width - 16, height: proxy.size.height - 16),
                    configuration: state.configuration,
                    sliced: sliced,
                    displayScale: displayScale
                )
                PuzzleBoardView(model: model, sliced: sliced, state: state, metrics: metrics, isPeeking: isPeeking)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 8)

            ZStack {
                TileTrayView(
                    model: model,
                    state: state,
                    tileAspect: CGFloat(sliced.tilePixelWidth) / CGFloat(sliced.tilePixelHeight)
                )
                .disabled(model.phase == .timeUp || model.phase == .completed)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            .safeAreaPadding(.bottom, 6)
        }
    }

    private func advanceToNextLevel() {
        if let next = nextSession() {
            if let onNextSession {
                onNextSession(next)
            } else {
                model = PuzzleViewModel(session: next)
                Task {
                    await model.load()
                }
            }
        } else if let onExitToLevels {
            onExitToLevels()
        } else {
            onExit()
        }
    }

    private func nextSession() -> PuzzleSession? {
        let mode = model.session.configuration.effectiveMode
        let templates = MemeCatalog.templates(for: mode)
        guard let currentIndex = templates.firstIndex(where: { $0.id == model.session.source.id }) else { return nil }
        let nextIndex = currentIndex + 1
        guard nextIndex < templates.count else { return nil }
        let nextTemplate = templates[nextIndex]
        return PuzzleSession(source: .bundled(nextTemplate), configuration: model.session.configuration, seed: nil)
    }
}

/// Isolated container for the floating dragged tile overlay.
/// Observing `model.drag` exclusively inside this separate view prevents the entire
/// 100-cell board and 32-cell tray from invalidating during 120Hz finger movement.
struct DragOverlayContainer: View {
    let model: PuzzleViewModel

    var body: some View {
        if let drag = model.drag, let image = model.image(for: drag.tile), model.boardFrame.width > 0 {
            DraggedTileOverlay(
                drag: drag,
                image: image,
                cellSize: CGSize(
                    width: model.boardFrame.width / CGFloat(model.configuration.columns),
                    height: model.boardFrame.height / CGFloat(model.configuration.rows)
                ),
                isOverTarget: model.hoveredPosition != nil
            )
        }
    }
}

extension PuzzleScreen {

    private func announce(_ feedback: PlacementFeedback?) {
        guard let feedback else { return }
        let message: String
        switch feedback.kind {
        case .correct:
            message = model.phase == .completed ? "Puzzle complete!" : "Correct. \(model.state?.progress.remaining ?? 0) pieces left."
        case .wrongSlot: message = "That piece belongs somewhere else."
        case .occupied: message = "That slot is already filled."
        case .timeExpired: message = "Time expired!"
        }
        AccessibilityNotification.Announcement(message).post()
    }
}

/// Header featuring competitive countdown timer progress ring, mode badge, and progress bar.
struct PuzzleHeader: View {
    @Bindable var model: PuzzleViewModel
    let state: PuzzleState
    @Binding var isPeeking: Bool
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                CircleButton(systemName: "chevron.left", label: "Back to memes", action: onExit)
                    .accessibilityIdentifier("back")

                VStack(alignment: .leading, spacing: 2) {
                    Text(model.session.source.title)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        if let mode = state.configuration.mode {
                            Text(mode.title)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Theme.accent.opacity(0.2)))
                        }
                        Text("\(state.configuration.columns)×\(state.configuration.rows) · \(state.mistakeCount) misses")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                countdownTimerRing
                peekButton
                CircleButton(systemName: "arrow.counterclockwise", label: "Restart puzzle") { model.retryCurrent() }
                    .accessibilityIdentifier("restart")
            }

            progressBar
        }
    }

    /// Candy Crush-style animated countdown ring with urgency pulse.
    private var countdownTimerRing: some View {
        let remaining = Int(ceil(model.timeRemaining))
        let fraction = model.timeRemainingFraction
        let isLow = model.isLowTime

        return HStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 3.5)
                Circle()
                    .trim(from: 0, to: CGFloat(fraction))
                    .stroke(
                        ringColor(fraction: fraction, isLow: isLow),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: fraction)

                Text("\(remaining)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(isLow ? Theme.failure : .white)
            }
            .frame(width: 38, height: 38)
            .scaleEffect(isLow ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 0.25), value: model.pulseTrigger)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(remaining) seconds remaining")
        .accessibilityIdentifier("timer.countdown")
    }

    private func ringColor(fraction: Double, isLow: Bool) -> Color {
        if isLow { return Theme.failure }
        if fraction < 0.35 { return Theme.accent }
        return Theme.success
    }

    private var progressBar: some View {
        let progress = state.progress
        return HStack(spacing: 10) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12))
                    Capsule()
                        .fill(LinearGradient(colors: [Theme.accent, Theme.success], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, proxy.size.width * progress.fraction))
                }
            }
            .frame(height: 7)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress.placed)

            Text("\(progress.placed)/\(progress.total) placed")
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(.white.opacity(0.85))
                .contentTransition(.numericText())
                .accessibilityIdentifier("progress")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progress.placed) of \(progress.total) pieces placed, \(progress.remaining) remaining")
    }

    private var peekButton: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: isPeeking ? "eye.fill" : "eye")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(.white.opacity(isPeeking ? 0.3 : 0.12)))
                .onLongPressGesture(minimumDuration: 0, maximumDistance: 40, perform: {}) { pressing in
                    if pressing && !isPeeking {
                        model.applyPeekPenalty(seconds: 10)
                    }
                    isPeeking = pressing
                }
                .accessibilityLabel("Peek at the full meme (-10s penalty)")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction {
                    model.applyPeekPenalty(seconds: 10)
                    isPeeking.toggle()
                }

            Text("-10s")
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(Theme.failure)
                .clipShape(Capsule())
                .offset(x: 4, y: 4)
        }
    }
}

struct CircleButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(.white.opacity(0.12)))
        }
        .accessibilityLabel(label)
    }
}
