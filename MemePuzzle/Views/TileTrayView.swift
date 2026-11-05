import MemeBlitzCore
import SwiftUI

/// Constants shared by the tray tiles and the floating drag preview.
enum DragGeometry {
    /// The floating tile is drawn this far above the finger so it stays visible; drops use the tile's center.
    static let liftOffset: CGFloat = 56
    /// How much larger than a board cell the floating tile is drawn.
    static let liftScale: CGFloat = 1.3
    /// Hold duration before a tray tile lifts. Shorter swipes scroll the tray instead.
    static let pressDuration: Double = 0.12
}

/// The shuffled missing pieces, shown in a horizontally scrolling tray below the board.
struct TileTrayView: View {
    @Bindable var model: PuzzleViewModel
    let state: PuzzleState
    let tileAspect: CGFloat

    private var tileHeight: CGFloat { state.tray.count > 8 ? 44 : 52 }
    private var tileWidth: CGFloat { min(max(tileHeight * tileAspect, 38), 75) }
    private var rows: Int { state.tray.count > 8 ? 2 : 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: Array(repeating: GridItem(.fixed(tileHeight), spacing: 8), count: rows), spacing: 8) {
                    ForEach(Array(state.tray.enumerated()), id: \.element) { index, id in
                        if let image = model.image(for: id), let tile = state.tile(id) {
                            TrayTileView(
                                model: model,
                                tile: tile,
                                image: image,
                                size: CGSize(width: tileWidth, height: tileHeight),
                                index: index,
                                total: state.tray.count
                            )
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: state.tray)
            }
            .frame(height: CGFloat(rows) * tileHeight + CGFloat(rows - 1) * 8 + 8)
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.tray)
                .shadow(color: .black.opacity(0.3), radius: 12, y: -2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityIdentifier("tray")
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "square.grid.3x3.middle.filled")
                .font(.footnote)
                .foregroundStyle(Theme.trayText.opacity(0.7))
            Text("Missing pieces")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.trayText)
            Spacer()
            Text(model.selectedTile == nil ? "Hold & drag · or tap" : "Tap an empty slot")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.trayText.opacity(0.55))
        }
        .padding(.horizontal, 16)
    }
}

/// One draggable missing piece in the tray.
struct TrayTileView: View {
    @Bindable var model: PuzzleViewModel
    let tile: PuzzleTile
    let image: CGImage
    let size: CGSize
    let index: Int
    let total: Int

    @GestureState private var isTouching = false

    private var isDragging: Bool { model.activeDragTile == tile.id }
    private var isSelected: Bool { model.selectedTile == tile.id }
    private var wasRejected: Bool {
        model.feedback?.tile == tile.id && model.feedback?.kind != .correct
    }

    var body: some View {
        ImageTileView(image: image, cornerRadius: 8)
            .frame(width: size.width, height: size.height)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isSelected || wasRejected ? 3 : 1.5)
            )
            .shadow(color: .black.opacity(isSelected ? 0.35 : 0.18), radius: isSelected ? 8 : 3, y: isSelected ? 5 : 2)
            .scaleEffect(isTouching && !isDragging ? 0.94 : (isSelected ? 1.08 : 1))
            .offset(y: isSelected ? -4 : 0)
            .opacity(isDragging ? 0.25 : 1)
            .shake(trigger: model.trayRejections[tile.id, default: 0])
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isTouching)
            .contentShape(Rectangle())
            .onTapGesture { model.toggleSelection(tile.id) }
            .gesture(dragGesture)
            .onChange(of: isTouching) { _, touching in
                guard !touching else { return }
                // If the system cancelled the gesture (no onEnded), return the tile to the tray.
                // Deferred so a normal onEnded drop is processed first.
                let id = tile.id
                DispatchQueue.main.async { model.cancelDrag(id) }
            }
            .accessibilityElement()
            .accessibilityLabel("Missing piece \(index + 1) of \(total)")
            .accessibilityValue(isSelected ? "Selected" : "")
            .accessibilityHint("Double-tap to select, then choose an empty slot")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("tray.tile.\(tile.correctPosition.row).\(tile.correctPosition.column)")
    }

    private var borderColor: Color {
        if wasRejected { return Theme.failure }
        if isSelected { return Theme.accent }
        return .white
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 5, coordinateSpace: .named(PuzzleViewModel.coordinateSpace))
            .updating($isTouching) { _, touching, _ in touching = true }
            .onChanged { value in
                model.beginDrag(tile.id, at: lifted(value.location))
            }
            .onEnded { value in
                model.endDrag(at: lifted(value.location))
            }
    }

    private func lifted(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x, y: point.y - DragGeometry.liftOffset)
    }
}

/// The tile following the player's finger, drawn at (slightly larger than) board-cell size.
struct DraggedTileOverlay: View {
    let drag: TileDrag
    let image: CGImage
    let cellSize: CGSize
    let isOverTarget: Bool

    var body: some View {
        ImageTileView(image: image, cornerRadius: 3)
            .frame(width: cellSize.width * DragGeometry.liftScale, height: cellSize.height * DragGeometry.liftScale)
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(isOverTarget ? Theme.accent : .white, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.5), radius: 10, y: 8)
            .position(drag.location)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
