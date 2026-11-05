import MemePuzzleCore
import UIKit

enum MemeLoadingError: LocalizedError {
    case missingBundledImage(String)
    case unreadableImage
    case slicing(ImageSlicingError)

    var errorDescription: String? {
        switch self {
        case .missingBundledImage(let name):
            "The bundled meme “\(name)” could not be found."
        case .unreadableImage:
            "This image couldn’t be read. Try a JPEG, PNG or HEIC photo."
        case .slicing(.imageTooSmall(let width, let height, let rows, let columns)):
            "This image (\(width)×\(height) px) is too small for a \(columns)×\(rows) grid. Pick a larger image or a smaller grid."
        case .slicing:
            "The image couldn’t be cut into tiles."
        }
    }
}

/// Turns a meme source into a single captioned bitmap. Captions are burned into the artwork
/// before slicing, so caption letters are split across tiles like the rest of the meme.
enum MemeRenderer {
    static let maximumPixelDimension: CGFloat = 2048

    static func loadImage(for source: MemeSource) async throws -> (UIImage, top: String, bottom: String) {
        switch source {
        case .bundled(let template):
            let candidateURL = Bundle.main.url(forResource: template.resourceName, withExtension: "jpg")
                ?? Bundle.main.url(forResource: template.resourceName, withExtension: "jpeg")
                ?? Bundle.main.url(forResource: template.resourceName, withExtension: nil)
                ?? Bundle.main.url(forResource: template.resourceName, withExtension: "jpg", subdirectory: "Memes")
                ?? Bundle.main.url(forResource: template.resourceName, withExtension: "jpg", subdirectory: "DailyMemes")
            guard let url = candidateURL,
                  let image = UIImage(contentsOfFile: url.path) else {
                throw MemeLoadingError.missingBundledImage(template.title)
            }
            return (image, template.topText, template.bottomText)
        case .imported(let meme):
            return (meme.image, meme.topText, meme.bottomText)
        case .remote(let remote):
            let image = try await RemoteMemeService.shared.loadImage(for: remote)
            return (image, remote.topText, remote.bottomText)
        }
    }

    /// Draws `image` upright (honouring EXIF orientation), downscaled to a sane size, with captions.
    static func render(_ image: UIImage, topText: String, bottomText: String) throws -> CGImage {
        guard image.size.width >= 1, image.size.height >= 1 else { throw MemeLoadingError.unreadableImage }
        let scale = min(1, maximumPixelDimension / max(image.size.width * image.scale, image.size.height * image.scale))
        let size = CGSize(
            width: (image.size.width * image.scale * scale).rounded(.down),
            height: (image.size.height * image.scale * scale).rounded(.down)
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let rendered = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
            drawCaption(topText, in: size, atTop: true)
            drawCaption(bottomText, in: size, atTop: false)
        }
        guard let cgImage = rendered.cgImage else { throw MemeLoadingError.unreadableImage }
        return cgImage
    }

    /// Imported photos: decode once and normalize orientation so later crops match what the user saw.
    static func normalizedImport(from data: Data) throws -> UIImage {
        guard let image = UIImage(data: data) else { throw MemeLoadingError.unreadableImage }
        let cgImage = try render(image, topText: "", bottomText: "")
        return UIImage(cgImage: cgImage)
    }

    private static func drawCaption(_ text: String, in size: CGSize, atTop: Bool) {
        let caption = text.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !caption.isEmpty else { return }

        let fontSize = max(14, min(size.width, size.height * 1.3) * 0.085)
        let font = UIFont.systemFont(ofSize: fontSize, weight: .black, width: .condensed)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -5.0,
            .paragraphStyle: paragraph,
        ]
        let string = NSAttributedString(string: caption, attributes: attributes)
        let inset = size.width * 0.04
        let maxWidth = size.width - inset * 2
        let bounds = string.boundingRect(
            with: CGSize(width: maxWidth, height: size.height / 2.5),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let height = ceil(bounds.height)
        let margin = size.height * 0.025
        let y = atTop ? margin : size.height - height - margin
        string.draw(
            with: CGRect(x: inset, y: y, width: maxWidth, height: height),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
    }
}
