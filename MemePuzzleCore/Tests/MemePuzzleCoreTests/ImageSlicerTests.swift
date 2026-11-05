import CoreGraphics
import XCTest
@testable import MemePuzzleCore

/// Test helpers for building images with known pixels and reading them back.
enum TestImage {
    struct RGBA: Equatable, CustomStringConvertible {
        let r: UInt8, g: UInt8, b: UInt8, a: UInt8
        var description: String { "rgba(\(r),\(g),\(b),\(a))" }
    }

    /// Every pixel encodes its own coordinate: red = x, green = y, blue = 7 (opaque).
    static func coordinateImage(width: Int, height: Int) -> CGImage {
        precondition(width <= 256 && height <= 256)
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                bytes[i] = UInt8(x)
                bytes[i + 1] = UInt8(y)
                bytes[i + 2] = 7
                bytes[i + 3] = 255
            }
        }
        return makeImage(bytes: bytes, width: width, height: height)
    }

    static func solid(width: Int, height: Int) -> CGImage {
        makeImage(bytes: [UInt8](repeating: 200, count: width * height * 4), width: width, height: height)
    }

    static func makeImage(bytes: [UInt8], width: Int, height: Int) -> CGImage {
        let data = CFDataCreate(nil, bytes, bytes.count)!
        return CGImage(
            width: width, height: height,
            bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: CGDataProvider(data: data)!,
            decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )!
    }

    /// Reads pixels (top-left origin) from any CGImage.
    static func pixels(of image: CGImage) -> [[RGBA]] {
        let width = image.width, height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(
            data: &bytes, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (0..<height).map { y in
            (0..<width).map { x in
                let i = (y * width + x) * 4
                return RGBA(r: bytes[i], g: bytes[i + 1], b: bytes[i + 2], a: bytes[i + 3])
            }
        }
    }
}

final class ImageSlicerTests: XCTestCase {
    func testEveryTileContainsTheExactPixelsFromItsOriginalCell() throws {
        let configuration = try PuzzleConfiguration(rows: 10, columns: 10, missingTileCount: 5)
        let source = TestImage.coordinateImage(width: 100, height: 80)

        let sliced = try ImageSlicer.slice(source, configuration: configuration)

        XCTAssertEqual(sliced.tilePixelWidth, 10)
        XCTAssertEqual(sliced.tilePixelHeight, 8)
        XCTAssertEqual(sliced.tileImages.count, 100)
        for tile in PuzzleGenerator.makeTiles(for: configuration) {
            let image = try XCTUnwrap(sliced.tileImages[tile.id])
            XCTAssertEqual(image.width, 10)
            XCTAssertEqual(image.height, 8)
            let pixels = TestImage.pixels(of: image)
            for y in [0, 7] {
                for x in [0, 9] {
                    let expected = TestImage.RGBA(
                        r: UInt8(tile.correctPosition.column * 10 + x),
                        g: UInt8(tile.correctPosition.row * 8 + y),
                        b: 7, a: 255
                    )
                    XCTAssertEqual(pixels[y][x], expected, "\(tile.id) pixel (\(x), \(y))")
                }
            }
        }
    }

    func testTilesReassembleIntoTheNormalizedImageWithoutGapsOrOverlap() throws {
        let configuration = try PuzzleConfiguration(rows: 4, columns: 6, missingTileCount: 3)
        let sliced = try ImageSlicer.slice(TestImage.coordinateImage(width: 60, height: 40), configuration: configuration)
        let full = TestImage.pixels(of: sliced.image)

        for tile in PuzzleGenerator.makeTiles(for: configuration) {
            let pixels = TestImage.pixels(of: sliced.tileImages[tile.id]!)
            let originX = tile.correctPosition.column * sliced.tilePixelWidth
            let originY = tile.correctPosition.row * sliced.tilePixelHeight
            for y in 0..<sliced.tilePixelHeight {
                for x in 0..<sliced.tilePixelWidth {
                    XCTAssertEqual(pixels[y][x], full[originY + y][originX + x])
                }
            }
        }
    }

    func testNonDivisibleDimensionsTrimFewerPixelsThanOneTileAndKeepTilesUniform() throws {
        let configuration = try PuzzleConfiguration(rows: 10, columns: 10, missingTileCount: 5)
        let sliced = try ImageSlicer.slice(TestImage.coordinateImage(width: 107, height: 93), configuration: configuration)

        XCTAssertEqual(sliced.pixelWidth, 100)
        XCTAssertEqual(sliced.pixelHeight, 90)
        XCTAssertTrue(sliced.tileImages.values.allSatisfy { $0.width == 10 && $0.height == 9 })
        // Trim is centered: 7 columns removed -> 3 from the left; content is not resampled.
        let topLeft = TestImage.pixels(of: sliced.tileImages[TileID(0)]!)[0][0]
        XCTAssertEqual(topLeft.r, 3)
    }

    func testLargeImagesAreDownscaledPreservingAspectRatio() throws {
        let configuration = try PuzzleConfiguration(rows: 10, columns: 10, missingTileCount: 5)
        let sliced = try ImageSlicer.slice(
            TestImage.solid(width: 4000, height: 3000),
            configuration: configuration,
            maximumPixelDimension: 1000
        )

        XCTAssertEqual(sliced.pixelWidth, 1000)
        XCTAssertEqual(sliced.pixelHeight, 750)
        XCTAssertEqual(sliced.aspectRatio, 4.0 / 3.0, accuracy: 0.001)
    }

    func testPortraitImagesKeepTheirAspectRatio() throws {
        let configuration = try PuzzleConfiguration(rows: 10, columns: 10, missingTileCount: 5)
        let sliced = try ImageSlicer.slice(TestImage.solid(width: 300, height: 400), configuration: configuration)

        XCTAssertEqual(sliced.aspectRatio, 0.75, accuracy: 0.001)
        XCTAssertEqual(sliced.tilePixelWidth, 30)
        XCTAssertEqual(sliced.tilePixelHeight, 40)
    }

    func testTooSmallImageIsRejected() throws {
        let configuration = try PuzzleConfiguration(rows: 10, columns: 10, missingTileCount: 5)
        XCTAssertThrowsError(try ImageSlicer.slice(TestImage.solid(width: 30, height: 200), configuration: configuration)) {
            XCTAssertEqual(
                $0 as? ImageSlicingError,
                .imageTooSmall(width: 30, height: 200, rows: 10, columns: 10)
            )
        }
    }
}
