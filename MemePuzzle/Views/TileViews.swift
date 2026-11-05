import MemeBlitzCore
import SwiftUI

/// Displays one cropped piece of the meme as a tactile 3D arcade block.
/// Used on the board, in the tray and while dragging.
struct ImageTileView: View {
    let image: CGImage
    var cornerRadius: CGFloat = 3.5
    var showGloss: Bool = true

    var body: some View {
        Image(decorative: image, scale: 1)
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                // Top glossy sheen highlight
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(showGloss ? 0.24 : 0), location: 0),
                                .init(color: .white.opacity(showGloss ? 0.06 : 0), location: 0.35),
                                .init(color: .clear, location: 0.55)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)
            )
            .overlay(
                // 3D Bevel edge: crisp bright top-left, deep shadow bottom-right
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.48), location: 0.0),
                                .init(color: .white.opacity(0.18), location: 0.35),
                                .init(color: .black.opacity(0.45), location: 0.65),
                                .init(color: .black.opacity(0.75), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            )
            .shadow(color: .black.opacity(0.35), radius: 1.5, x: 0, y: 1)
    }
}

/// An empty board socket waiting for its missing puzzle block.
struct EmptySlotView: View {
    var isHovered: Bool
    var isTapTarget: Bool
    var feedback: PlacementFeedback.Kind?
    var shakeTrigger: Int

    var body: some View {
        ZStack {
            // Recessed arcade socket background
            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.13, green: 0.10, blue: 0.24),
                            Color(red: 0.04, green: 0.03, blue: 0.08)
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: 28
                    )
                )

            // Inner dark inset shadow
            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                .stroke(Color.black.opacity(0.8), lineWidth: 1.5)

            // Dashed neon socket border
            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1.2, dash: [4, 3])
                )
                .foregroundStyle(
                    isHovered
                        ? Theme.accent
                        : (isTapTarget ? Theme.accent.opacity(0.75) : Color(red: 0.65, green: 0.35, blue: 0.95).opacity(0.35))
                )

            // Subtle center socket locator cross
            Image(systemName: "plus")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(
                    isHovered
                        ? Theme.accent
                        : (isTapTarget ? Theme.accent.opacity(0.75) : Color(red: 0.65, green: 0.35, blue: 0.95).opacity(0.35))
                )

            if isHovered {
                RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                    .fill(Theme.accent.opacity(0.28))
            }

            if feedback == .wrongSlot || feedback == .occupied {
                RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                    .fill(Theme.failure.opacity(0.6))
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.white)
            }
        }
        .shake(trigger: shakeTrigger)
        .contentShape(Rectangle())
    }
}
