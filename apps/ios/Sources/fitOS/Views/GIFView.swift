import SwiftUI
import ImageIO
import UIKit

/// Decodes an animated GIF's frames + per-frame delays into an animated UIImage.
/// Pure native (ImageIO) — no webview, no third-party library.
enum GIFDecoder {
    static func animatedImage(from data: Data) -> UIImage? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return UIImage(data: data) }
        let count = CGImageSourceGetCount(src)
        guard count > 1 else { return UIImage(data: data) }
        var frames: [UIImage] = []
        var duration = 0.0
        for i in 0..<count {
            guard let cg = CGImageSourceCreateImageAtIndex(src, i, nil) else { continue }
            frames.append(UIImage(cgImage: cg))
            duration += delay(src, i)
        }
        return UIImage.animatedImage(with: frames, duration: duration)
    }

    private static func delay(_ src: CGImageSource, _ i: Int) -> Double {
        guard let props = CGImageSourceCopyPropertiesAtIndex(src, i, nil) as? [CFString: Any],
              let gif = props[kCGImagePropertyGIFDictionary] as? [CFString: Any] else { return 0.1 }
        let t = (gif[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
            ?? (gif[kCGImagePropertyGIFDelayTime] as? Double) ?? 0.1
        return t < 0.02 ? 0.1 : t
    }
}

/// UIImageView wrapper — auto-animates a UIImage that carries `.images`.
struct AnimatedImageView: UIViewRepresentable {
    let image: UIImage?
    func makeUIView(context: Context) -> UIImageView {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }
    func updateUIView(_ v: UIImageView, context: Context) {
        v.image = image
        if image?.images != nil { v.startAnimating() }
    }
}

/// Loads and shows an exercise demo: animated gif → still image → emoji fallback.
struct ExerciseDemoView: View {
    let media: ExerciseMedia?
    let emoji: String

    @State private var image: UIImage?
    @State private var loading = false
    @State private var failed = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(Palette.surface2)
            if let image {
                AnimatedImageView(image: image).padding(6)
            } else if loading {
                ProgressView().tint(Palette.red)
            } else {
                VStack(spacing: 6) {
                    Text(emoji).font(.system(size: 54))
                    if failed {
                        Text("Demo not available").font(.system(size: 12)).foregroundStyle(Palette.faint)
                    }
                }
            }
            if image?.images != nil {
                VStack {
                    HStack {
                        Spacer()
                        Text("▶ live").font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Palette.red).foregroundStyle(.white).clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(10)
            }
        }
        .frame(height: 220)
        .task(id: media?.gif ?? media?.still ?? "") { await load() }
    }

    private func load() async {
        image = nil; failed = false
        guard let urlStr = media?.gif ?? media?.still, let url = URL(string: urlStr) else {
            failed = true; return
        }
        loading = true
        defer { loading = false }
        if let (data, _) = try? await URLSession.shared.data(from: url) {
            image = (media?.gif != nil) ? GIFDecoder.animatedImage(from: data) : UIImage(data: data)
        }
        // Gif failed? try the still.
        if image == nil, let still = media?.still, let url = URL(string: still),
           let (d, _) = try? await URLSession.shared.data(from: url) {
            image = UIImage(data: d)
        }
        if image == nil { failed = true }
    }
}
