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

/// In-memory cache of decoded animated gifs, keyed by URL — re-opening is instant.
enum GifMemo { static let cache = NSCache<NSString, UIImage>() }

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

/// Exercise demo: shows the still photo instantly, then swaps in the animated gif.
/// Cached gifs appear with zero delay on re-open.
struct ExerciseDemoView: View {
    let media: ExerciseMedia?
    let emoji: String

    @State private var gifImage: UIImage?
    @State private var stillImage: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(Palette.surface2)
            if let img = gifImage ?? stillImage {
                AnimatedImageView(image: img).padding(6)
            } else if !failed {
                ProgressView().tint(Palette.red)
            } else {
                VStack(spacing: 6) {
                    Text(emoji).font(.system(size: 54))
                    Text("Demo not available").font(.system(size: 12)).foregroundStyle(Palette.faint)
                }
            }
            if gifImage?.images != nil {
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
        gifImage = nil; stillImage = nil; failed = false

        // 1. Cached decoded gif → instant.
        if let gif = media?.gif, let cached = GifMemo.cache.object(forKey: gif as NSString) {
            gifImage = cached; return
        }
        // 2. Show the still immediately (usually already URLCached from the grid).
        if let still = media?.still, let url = URL(string: still),
           let (d, _) = try? await URLSession.shared.data(from: url) {
            stillImage = UIImage(data: d)
        }
        // 3. Download + decode + cache the animated gif, then swap it in.
        if let gif = media?.gif, let url = URL(string: gif),
           let (d, _) = try? await URLSession.shared.data(from: url),
           let anim = GIFDecoder.animatedImage(from: d) {
            GifMemo.cache.setObject(anim, forKey: gif as NSString)
            gifImage = anim
            return
        }
        if gifImage == nil && stillImage == nil { failed = true }
    }
}

/// Still-photo thumbnail for the browse grid (emoji fallback).
struct ExerciseThumb: View {
    let still: String?
    let emoji: String
    var body: some View {
        ZStack {
            Palette.surface2
            if let s = still, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    case .empty: ProgressView().tint(Palette.faint)
                    default: Text(emoji).font(.system(size: 34))
                    }
                }
            } else {
                Text(emoji).font(.system(size: 34))
            }
        }
        .frame(height: 104)
        .clipped()
    }
}
