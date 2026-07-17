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
/// Hosted in a plain UIView so the image's intrinsic size cannot blow out SwiftUI layout
/// (raw UIImageView does — that was the exercise-detail overflow bug).
struct AnimatedImageView: UIViewRepresentable {
    let image: UIImage?

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.clipsToBounds = true
        container.backgroundColor = .clear

        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.tag = 100
        // Critical: don't let the image dictate the view's preferred size.
        iv.setContentHuggingPriority(.defaultLow, for: .horizontal)
        iv.setContentHuggingPriority(.defaultLow, for: .vertical)
        iv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        iv.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        iv.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            iv.topAnchor.constraint(equalTo: container.topAnchor),
            iv.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        guard let iv = container.viewWithTag(100) as? UIImageView else { return }
        iv.image = image
        if image?.images != nil {
            iv.startAnimating()
        } else {
            iv.stopAnimating()
        }
    }

    /// Zero intrinsic size so SwiftUI parent frames always win.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
        let w = proposal.width ?? 0
        let h = proposal.height ?? 0
        return CGSize(width: w, height: h)
    }
}

/// Exercise demo: shows the still photo instantly, then swaps in the animated gif.
/// Cached gifs appear with zero delay on re-open.
struct ExerciseDemoView: View {
    let media: ExerciseMedia?
    let emoji: String
    var height: CGFloat = 240

    @State private var gifImage: UIImage?
    @State private var stillImage: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            Palette.surface2
            if let img = gifImage ?? stillImage {
                AnimatedImageView(image: img)
                    .padding(8)
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
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(Palette.border, lineWidth: 1)
        )
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
