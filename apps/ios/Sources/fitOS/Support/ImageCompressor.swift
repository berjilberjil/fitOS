import UIKit

/// Resize + JPEG-compress progress photos before upload to Cloudflare R2
/// (~80–150 KB). Base64 is only used as a wire format for the upload API.
enum ImageCompressor {
    /// Max edge length in pixels (keeps quality for body progress shots).
    static let maxEdge: CGFloat = 1080
    /// JPEG quality — good detail, low bytes.
    static let quality: CGFloat = 0.62

    /// Returns base64 (no data-URI prefix) of a compressed JPEG, or nil on failure.
    static func compressToBase64(_ image: UIImage) -> String? {
        guard let jpeg = compressToJPEG(image) else { return nil }
        return jpeg.base64EncodedString()
    }

    static func compressToJPEG(_ image: UIImage) -> Data? {
        let scaled = resize(image, maxEdge: maxEdge)
        // Prefer sRGB, strip alpha for smaller JPEGs
        let flat = flatten(scaled)
        return flat.jpegData(compressionQuality: quality)
    }

    static func image(fromBase64 b64: String) -> UIImage? {
        guard let data = Data(base64Encoded: b64) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - private

    private static func resize(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxEdge, longest > 0 else { return image }
        let scale = maxEdge / longest
        let newSize = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private static func flatten(_ image: UIImage) -> UIImage {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image }
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
