import MemeBlitzCore
import SwiftUI

/// Compatibility wrapper forwarding to the redesigned arcade-style CompletionPopupView.
struct CompletionView: View {
    @Bindable var model: PuzzleViewModel
    let title: String
    var onReplay: () -> Void
    var onLevels: (() -> Void)?
    var onNewMeme: () -> Void

    init(
        model: PuzzleViewModel,
        title: String,
        onReplay: @escaping () -> Void,
        onLevels: (() -> Void)? = nil,
        onNewMeme: @escaping () -> Void
    ) {
        self.model = model
        self.title = title
        self.onReplay = onReplay
        self.onLevels = onLevels
        self.onNewMeme = onNewMeme
    }

    var body: some View {
        CompletionPopupView(
            model: model,
            title: title,
            onReplay: onReplay,
            onLevels: onLevels ?? onNewMeme,
            onHome: onNewMeme,
            onNextLevel: onNewMeme
        )
    }
}

/// A short, one-shot confetti burst drawn with Canvas (no per-particle views).
struct ConfettiView: View {
    private struct Particle {
        let x: CGFloat, delay: Double, speed: CGFloat, drift: CGFloat, spin: Double, size: CGFloat, color: Color
    }

    private static let colors: [Color] = [Theme.accent, Theme.success, .pink, .cyan, .orange, .white]
    private let particles: [Particle] = (0..<90).map { _ in
        Particle(
            x: .random(in: 0...1), delay: .random(in: 0...0.5), speed: .random(in: 0.45...0.9),
            drift: .random(in: -0.15...0.15), spin: .random(in: 2...8), size: .random(in: 5...10),
            color: colors.randomElement()!
        )
    }
    @State private var start = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if !reduceMotion {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSince(start)
                Canvas { context, size in
                    for particle in particles {
                        let local = t - particle.delay
                        guard local > 0, local < 3 else { continue }
                        let y = -20 + CGFloat(local) * particle.speed * size.height
                        let x = (particle.x + particle.drift * CGFloat(local)) * size.width
                        let alpha = max(0, 1 - local / 3)
                        var copy = context
                        copy.opacity = alpha
                        copy.translateBy(x: x, y: y)
                        copy.rotate(by: .radians(local * particle.spin))
                        copy.fill(
                            Path(CGRect(x: -particle.size / 2, y: -particle.size / 4, width: particle.size, height: particle.size / 2)),
                            with: .color(particle.color)
                        )
                    }
                }
            }
        }
    }
}
