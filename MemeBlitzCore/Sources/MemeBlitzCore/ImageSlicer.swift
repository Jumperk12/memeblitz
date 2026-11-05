import CoreGraphics
import Foundation

public enum ImageSlicingError: Error, Equatable, Sendable {
    /// The image is too small to give each tile at least `ImageSlicer.minimumTilePixels` pixels per side.
    case imageTooSmall(width: Int, height: Int, rows: Int, columns: Int)
    case renderingFailed
    case croppingFailed(TileID)
}

/// The normalized source image and one cropped image per tile.
public struct SlicedImage: @unchecked Sendable {
    /// The exact bitmap the tiles were cut from (after any downscale and edge trim).
    public let image: CGImage
    public let tilePixelWidth: Int
    public let tilePixelHeight: Int
    public let tileImages: [TileID: CGImage]

    public var pixelWidth: Int { image.width }
    public var pixelHeight: Int { image.height }
    /// Width / height of the playable image. The board is laid out with this ratio so nothing is distorted.
    public var aspectRatio: Double { Double(image.width) / Double(image.height) }
}

/// Cuts a source image into a grid of equally sized tiles, each with its exact original pixels.
public enum ImageSlicer {
    public static let minimumTilePixels = 4
    public static let defaultMaximumPixelDimension = 2048

    /// Pixel rect (top-left origin) of the tile at `position` in an image whose size is a multiple of the tile size.
    public static func pixelRect(for position: GridPosition, tileWidth: Int, tileHeight: Int) -> CGRect {
        CGRect(x: position.column * tileWidth, y: position.row * tileHeight, width: tileWidth, height: tileHeight)
    }

    /// Slices `source` for `configuration`.
    ///
    /// 1. Large images are downscaled (aspect ratio preserved) so the longest side is at most `maximumPixelDimension`.
    /// 2. At most `columns - 1` / `rows - 1` pixels are trimmed (centered) so every tile has identical integer size,
    ///    which keeps neighbouring tiles perfectly aligned without resampling.
    /// 3. Each tile is cropped from that normalized bitmap at its original row and column.
    public static func slice(
        _ source: CGImage,
        configuration: PuzzleConfiguration,
        maximumPixelDimension: Int = defaultMaximumPixelDimension
    ) throws -> SlicedImage {
        let scale = min(1, Double(maximumPixelDimension) / Double(max(source.width, source.height)))
        let scaledWidth = max(1, Int((Double(source.width) * scale).rounded(.down)))
        let scaledHeight = max(1, Int((Double(source.height) * scale).rounded(.down)))

        let tileWidth = scaledWidth / configuration.columns
        let tileHeight = scaledHeight / configuration.rows
        guard tileWidth >= minimumTilePixels, tileHeight >= minimumTilePixels else {
            throw ImageSlicingError.imageTooSmall(
                width: source.width, height: source.height,
                rows: configuration.rows, columns: configuration.columns
            )
        }

        let width = tileWidth * configuration.columns
        let height = tileHeight * configuration.rows
        let normalized = try render(
            source,
            scaledSize: CGSize(width: scaledWidth, height: scaledHeight),
            canvas: (width, height)
        )

        var tileImages: [TileID: CGImage] = [:]
        tileImages.reserveCapacity(configuration.tileCount)
        for tile in PuzzleGenerator.makeTiles(for: configuration) {
            let rect = pixelRect(for: tile.correctPosition, tileWidth: tileWidth, tileHeight: tileHeight)
            guard let cropped = normalized.cropping(to: rect) else {
                throw ImageSlicingError.croppingFailed(tile.id)
            }
            tileImages[tile.id] = cropped
        }
        return SlicedImage(
            image: normalized,
            tilePixelWidth: tileWidth,
            tilePixelHeight: tileHeight,
            tileImages: tileImages
        )
    }

    /// Draws the (optionally downscaled) source centered on a canvas, trimming the remainder pixels evenly.
    private static func render(_ source: CGImage, scaledSize: CGSize, canvas: (Int, Int)) throws -> CGImage {
        let (width, height) = canvas
        guard
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { throw ImageSlicingError.renderingFailed }

        context.interpolationQuality = .high
        let originX = -((scaledSize.width - CGFloat(width)) / 2).rounded(.down)
        let originY = -((scaledSize.height - CGFloat(height)) / 2).rounded(.down)
        context.draw(source, in: CGRect(origin: CGPoint(x: originX, y: originY), size: scaledSize))
        guard let image = context.makeImage() else { throw ImageSlicingError.renderingFailed }
        return image
    }
}
