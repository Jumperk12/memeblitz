import MemePuzzleCore
import SwiftUI

/// Pixel-aligned tile geometry so neighbouring tiles meet without hairline seams.
struct BoardMetrics: Equatable {
    let tileWidth: CGFloat
    let tileHeight: CGFloat
    let columns: Int
    let rows: Int

    var size: CGSize { CGSize(width: tileWidth * CGFloat(columns), height: tileHeight * CGFloat(rows)) }

    func origin(of position: GridPosition) -> CGPoint {
        CGPoint(x: CGFloat(position.column) * tileWidth, y: CGFloat(position.row) * tileHeight)
    }

    /// Largest board that fits `available` while keeping the meme's aspect ratio,
    /// with tile sizes snapped to whole device pixels.
    static func fit(available: CGSize, configuration: PuzzleConfiguration, sliced: SlicedImage, displayScale: CGFloat) -> BoardMetrics {
        let tileAspect = CGFloat(sliced.tilePixelWidth) / CGFloat(sliced.tilePixelHeight)
        let columns = CGFloat(configuration.columns), rows = CGFloat(configuration.rows)
        let fromWidth = available.width / columns
        let fromHeight = available.height / rows * tileAspect
        let raw = max(1 / displayScale, min(fromWidth, fromHeight))
        let tileWidth = max(1, (raw * displayScale).rounded(.down)) / displayScale
        let tileHeight = max(1, (tileWidth / tileAspect * displayScale).rounded()) / displayScale
        return BoardMetrics(tileWidth: tileWidth, tileHeight: tileHeight, columns: configuration.columns, rows: configuration.rows)
    }
}

/// The framed meme: prefilled and placed tiles at their original cells, empty slots elsewhere.
struct PuzzleBoardView: View {
    @Bindable var model: PuzzleViewModel
    let sliced: SlicedImage
    let state: PuzzleState
    let metrics: BoardMetrics
    var isPeeking: Bool

    @Environment(\.displayScale) private var displayScale
    @State private var shimmerPhase: CGFloat = -1
    @State private var celebrationScale: CGFloat = 1

    private var isComplete: Bool { model.phase == .completed }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(state.layout.tiles) { tile in
                cell(for: tile.correctPosition)
                    .frame(width: metrics.tileWidth, height: metrics.tileHeight)
                    .offset(x: metrics.origin(of: tile.correctPosition).x, y: metrics.origin(of: tile.correctPosition).y)
            }
            gridLines
                .opacity(isComplete ? 0 : 1)
                .allowsHitTesting(false)
            if isPeeking {
                Image(decorative: sliced.image, scale: 1)
                    .resizable()
                    .frame(width: metrics.size.width, height: metrics.size.height)
                    .opacity(0.9)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
            if isComplete {
                shimmer.allowsHitTesting(false)
            }
        }
        .frame(width: metrics.size.width, height: metrics.size.height, alignment: .topLeading)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: state.board.count)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named(PuzzleViewModel.coordinateSpace))
        } action: { frame in
            model.boardFrame = frame
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.frame)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Theme.frameHighlight.opacity(isComplete ? 1 : 0.55), Theme.frameHighlight.opacity(0.15)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
        )
        .scaleEffect(celebrationScale)
        .animation(.easeInOut(duration: 0.15), value: isPeeking)
        .animation(.easeInOut(duration: 0.8), value: isComplete)
        .onChange(of: isComplete) { _, complete in
            guard complete else { shimmerPhase = -1; return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { celebrationScale = 1.04 }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) { celebrationScale = 1 }
            withAnimation(.easeInOut(duration: 1.2).delay(0.2)) { shimmerPhase = 1.5 }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("board")
    }

    @ViewBuilder
    private func cell(for position: GridPosition) -> some View {
        if let id = state.tile(at: position), let image = model.image(for: id) {
            let justPlaced = model.feedback?.kind == .correct && model.feedback?.position == position
            ImageTileView(image: image, cornerRadius: 3.5)
                .padding(1)
                .overlay {
                    if justPlaced {
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .strokeBorder(Theme.success, lineWidth: 2.5)
                            .padding(1)
                    }
                }
                .zIndex(justPlaced ? 1 : 0)
                .transition(.scale(scale: 1.35).combined(with: .opacity))
                .accessibilityHidden(true)
        } else {
            let slotFeedback = model.feedback.flatMap { $0.position == position ? $0.kind : nil }
            EmptySlotView(
                isHovered: model.hoveredPosition == position,
                isTapTarget: model.selectedTile != nil,
                feedback: slotFeedback,
                shakeTrigger: model.slotRejections[position, default: 0]
            )
            .padding(1)
            .onTapGesture { model.tapSlot(position) }
            .accessibilityElement()
            .accessibilityLabel("Empty slot, row \(position.row + 1), column \(position.column + 1)")
            .accessibilityHint(model.selectedTile == nil ? "Select a missing piece first" : "Places the selected piece here")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("slot.\(position.row).\(position.column)")
        }
    }

    /// Thin seams that make individual tiles visible; removed when the meme is complete.
    private var gridLines: some View {
        Canvas { context, size in
            let line = 1 / displayScale
            var path = Path()
            for column in 1..<metrics.columns {
                let x = CGFloat(column) * metrics.tileWidth
                path.addRect(CGRect(x: x - line / 2, y: 0, width: line, height: size.height))
            }
            for row in 1..<metrics.rows {
                let y = CGFloat(row) * metrics.tileHeight
                path.addRect(CGRect(x: 0, y: y - line / 2, width: size.width, height: line))
            }
            context.fill(path, with: .color(.black.opacity(0.45)))
        }
        .frame(width: metrics.size.width, height: metrics.size.height)
    }

    private var shimmer: some View {
        LinearGradient(
            colors: [.clear, .white.opacity(0.45), .clear],
            startPoint: .leading, endPoint: .trailing
        )
        .frame(width: metrics.size.width * 0.35, height: metrics.size.height * 1.6)
        .rotationEffect(.degrees(20))
        .offset(x: shimmerPhase * metrics.size.width, y: -metrics.size.height * 0.3)
        .blendMode(.plusLighter)
        .frame(width: metrics.size.width, height: metrics.size.height, alignment: .topLeading)
        .clipped()
    }
}
