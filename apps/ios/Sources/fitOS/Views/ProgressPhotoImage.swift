import SwiftUI
import UIKit

/// Loads a progress photo from R2 (via `/api/media`) or legacy base64 in app_state.
struct ProgressPhotoImage: View {
    let photo: ProgressPhoto
    var contentMode: ContentMode = .fill

    @State private var uiImage: UIImage?
    @State private var failed = false
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if failed {
                ZStack {
                    Palette.surface2
                    Image(systemName: "photo")
                        .foregroundStyle(Palette.faint)
                }
            } else {
                ZStack {
                    Palette.surface2
                    ProgressView().tint(Palette.red).scaleEffect(0.8)
                }
            }
        }
        .task(id: photo.id) {
            await load()
        }
    }

    private func load() async {
        // Fast path: legacy base64 still in state.
        if photo.hasLocalBase64, let img = ImageCompressor.image(fromBase64: photo.jpegBase64) {
            uiImage = img
            failed = false
            return
        }
        guard photo.hasRemoteMedia else {
            failed = true
            return
        }
        do {
            let data = try await APIClient().mediaData(for: photo)
            if let img = UIImage(data: data) {
                uiImage = img
                failed = false
            } else {
                failed = true
            }
        } catch {
            failed = true
        }
    }

    /// Load UIImage for export/save (same sources as the view).
    static func loadUIImage(_ photo: ProgressPhoto) async -> UIImage? {
        if photo.hasLocalBase64, let img = ImageCompressor.image(fromBase64: photo.jpegBase64) {
            return img
        }
        guard photo.hasRemoteMedia else { return nil }
        do {
            let data = try await APIClient().mediaData(for: photo)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}
