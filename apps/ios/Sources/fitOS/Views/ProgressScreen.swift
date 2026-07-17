import SwiftUI
import Charts
import UIKit
import Photos
import PhotosUI

/// Progress hub: daily weight (±0.25 kg), trend chart, and compressed progress photos.
struct ProgressScreen: View {
    @EnvironmentObject var state: AppState
    @ObservedObject private var health = HealthService.shared
    @State private var importMessage: String?
    @State private var photoItem: PhotosPickerItem?
    @State private var photoBusy = false
    @State private var photoError: String?
    /// Fullscreen gallery start index (nil = closed).
    @State private var galleryIndex: Int?

    private struct Point: Identifiable {
        let id: String
        let date: Date
        let kg: Double
    }

    private var points: [Point] {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return state.weightLog.compactMap { key, kg in
            f.date(from: key).map { Point(id: key, date: $0, kg: kg) }
        }
        .sorted { $0.date < $1.date }
    }

    private var todayWeight: Double {
        state.weightLog[state.todayKey] ?? state.profile.currentWeightKg
    }

    private var photosSorted: [ProgressPhoto] {
        state.progressPhotos.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        Screen(title: "Progress") {
            statsCard
            weightLogCard
            weightTrendCard
            photosCard
            bmiCard
            healthCard
        }
        .accessibilityIdentifier("screen.progress")
        .alert("Apple Health", isPresented: Binding(
            get: { importMessage != nil },
            set: { if !$0 { importMessage = nil } }
        )) {
            Button("OK", role: .cancel) { importMessage = nil }
        } message: { Text(importMessage ?? "") }
        .alert("Photo", isPresented: Binding(
            get: { photoError != nil },
            set: { if !$0 { photoError = nil } }
        )) {
            Button("OK", role: .cancel) { photoError = nil }
        } message: { Text(photoError ?? "") }
        .onChange(of: photoItem) { item in
            guard let item else { return }
            Task { await ingestPhoto(item) }
        }
        .fullScreenCover(isPresented: Binding(
            get: { galleryIndex != nil },
            set: { if !$0 { galleryIndex = nil } }
        )) {
            ProgressPhotoGallery(
                startIndex: galleryIndex ?? 0,
                onClose: { galleryIndex = nil }
            )
            .environmentObject(state)
        }
    }

    // MARK: - Stats

    private var statsCard: some View {
        Card {
            HStack {
                StatTile(label: "Current", value: "\(fmt(state.profile.currentWeightKg)) kg", accent: Palette.text)
                StatTile(label: "Target", value: "\(fmt(state.profile.targetWeightKg)) kg", accent: Palette.red)
                StatTile(label: "To go",
                         value: "\(fmt(abs(state.profile.currentWeightKg - state.profile.targetWeightKg))) kg",
                         accent: Palette.info)
            }
        }
    }

    // MARK: - Weight (tap ±0.25 kg)

    private var weightLogCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Today's weight").eyebrow()
                    Spacer()
                    Text(state.todayKey)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.faint)
                }

                HStack(spacing: 16) {
                    Button {
                        Haptics.tap()
                        state.bumpBodyWeight(delta: -WorkoutDefaults.bodyWeightStep)
                        health.saveWeight(state.profile.currentWeightKg)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Palette.text)
                            .frame(width: 52, height: 52)
                            .background(Palette.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 2) {
                        Text(fmt(todayWeight))
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(Palette.text)
                            .monospacedDigit()
                        Text("kg  ·  ±0.25")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Palette.faint)
                    }
                    .frame(maxWidth: .infinity)

                    Button {
                        Haptics.tap()
                        state.bumpBodyWeight(delta: WorkoutDefaults.bodyWeightStep)
                        health.saveWeight(state.profile.currentWeightKg)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Palette.text)
                            .frame(width: 52, height: 52)
                            .background(Palette.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                Text("Tap + / − to log 0.25 kg (250 g) steps. Saved to your account + Apple Health when connected.")
                    .font(.system(size: 11)).foregroundStyle(Palette.faint)
            }
        }
    }

    private var weightTrendCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Weight trend").eyebrow()
                if points.count < 2 {
                    Text("Log weight a few days in a row to see the trend.")
                        .font(.system(size: 13)).foregroundStyle(Palette.muted)
                        .frame(height: 120)
                } else {
                    Chart(points) { p in
                        LineMark(x: .value("Date", p.date), y: .value("Weight", p.kg))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Palette.red)
                        AreaMark(x: .value("Date", p.date), y: .value("Weight", p.kg))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Palette.redSoft)
                        RuleMark(y: .value("Target", state.profile.targetWeightKg))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(Palette.faint)
                    }
                    .chartYScale(domain: .automatic(includesZero: false))
                    .frame(height: 180)
                }
            }
        }
    }

    // MARK: - Photos

    private var photosCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Progress photos").eyebrow()
                    Spacer()
                    if photoBusy {
                        ProgressView().tint(Palette.red).scaleEffect(0.8)
                    }
                    PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                        Label("Add", systemImage: "camera.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Palette.red)
                    }
                    .disabled(photoBusy)
                }

                Text("Photos are compressed then stored in cloud media (R2). Only metadata syncs with your account. Max \(AppState.maxProgressPhotos) photos.")
                    .font(.system(size: 11)).foregroundStyle(Palette.faint)

                if photosSorted.isEmpty {
                    Text("Add a photo today — next month you'll see the difference.")
                        .font(.system(size: 13)).foregroundStyle(Palette.muted)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(photosSorted) { photo in
                                photoThumb(photo)
                            }
                        }
                    }
                }
            }
        }
    }

    private func photoThumb(_ photo: ProgressPhoto) -> some View {
        Button {
            if let i = photosSorted.firstIndex(where: { $0.id == photo.id }) {
                Haptics.soft()
                galleryIndex = i
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                ProgressPhotoImage(photo: photo, contentMode: .fill)
                    .frame(width: 110, height: 148)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))

                Text(photo.date)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.faint)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                Task {
                    if let ui = await ProgressPhotoImage.loadUIImage(photo) {
                        ProgressPhotoGallery.saveToPhotos(ui) { ok, msg in
                            if ok { Haptics.success() } else { Haptics.error(); photoError = msg }
                        }
                    } else {
                        Haptics.error()
                        photoError = "Couldn't load this photo."
                    }
                }
            } label: { Label("Save to Photos", systemImage: "square.and.arrow.down") }
            Button(role: .destructive) {
                Haptics.warning()
                state.deleteProgressPhoto(id: photo.id)
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func ingestPhoto(_ item: PhotosPickerItem) async {
        photoBusy = true
        defer {
            photoBusy = false
            photoItem = nil
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                photoError = "Couldn't read that photo."
                return
            }
            guard let b64 = ImageCompressor.compressToBase64(image) else {
                photoError = "Couldn't compress that photo."
                return
            }
            // Rough size guard (~250 KB base64 max)
            if b64.count > 350_000 {
                photoError = "Photo is still too large after compression. Try a different shot."
                return
            }
            try await state.addProgressPhoto(jpegBase64: b64)
            Haptics.success()
        } catch {
            photoError = (error as? APIError)?.message ?? error.localizedDescription
            Haptics.error()
        }
    }

    // MARK: - BMI / Health

    private var bmiCard: some View {
        let bmi = Nutrition.bmi(state.profile)
        return Card {
            HStack {
                StatTile(label: "BMI", value: String(format: "%.1f", bmi))
                StatTile(label: "Status", value: Nutrition.bmiLabel(bmi), accent: Palette.ok)
            }
        }
    }

    @ViewBuilder private var healthCard: some View {
        if health.isAvailable {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Apple Health").eyebrow()
                        Spacer()
                        if health.connected {
                            Text("connected").font(.system(size: 10.5, weight: .bold)).foregroundStyle(Palette.ok)
                        }
                    }
                    if health.connected {
                        HStack {
                            StatTile(label: "Steps today", value: "\(health.steps)", accent: Palette.info)
                            Button { Task { await importWeight() } } label: {
                                Text("Import weight").font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Palette.red)
                                    .padding(.horizontal, 14).padding(.vertical, 9)
                                    .background(Palette.redSoft).clipShape(Capsule())
                            }
                        }
                    } else {
                        Button { Task { _ = await health.connect() } } label: {
                            Text("Connect Apple Health").font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity).padding(.vertical, 11)
                                .foregroundStyle(Palette.red).background(Palette.redSoft).clipShape(Capsule())
                        }
                    }
                }
            }
            .task { if health.connected { await health.refreshSteps() } }
        }
    }

    private func importWeight() async {
        if let kg = await health.latestWeightKg() {
            state.recordWeight(kg)
            Haptics.success()
            importMessage = "Imported \(fmt(kg)) kg from Health"
        } else {
            importMessage = "No weight samples found in Apple Health."
        }
    }

    private func fmt(_ v: Double) -> String {
        // Prefer 2 decimals when not whole (0.25 steps)
        if abs(v - v.rounded()) < 0.001 { return String(Int(v.rounded())) }
        if abs(v * 4 - (v * 4).rounded()) < 0.001 {
            return String(format: "%.2f", v)
        }
        return String(format: "%.1f", v)
    }
}

// MARK: - Fullscreen progress photo gallery (swipe left/right, save, delete)

/// Fullscreen pager: swipe between progress photos without dismissing.
struct ProgressPhotoGallery: View {
    @EnvironmentObject var state: AppState
    let startIndex: Int
    let onClose: () -> Void

    @State private var index: Int
    @State private var saveMessage: String?
    @State private var showDeleteConfirm = false

    init(startIndex: Int, onClose: @escaping () -> Void) {
        self.startIndex = startIndex
        self.onClose = onClose
        _index = State(initialValue: max(startIndex, 0))
    }

    private var photos: [ProgressPhoto] {
        state.progressPhotos.sorted { $0.createdAt > $1.createdAt }
    }

    private var current: ProgressPhoto? {
        guard photos.indices.contains(index) else { return photos.first }
        return photos[index]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if photos.isEmpty {
                VStack(spacing: 14) {
                    Text("No photos").foregroundStyle(.white.opacity(0.7))
                    Button("Close") { onClose() }
                        .foregroundStyle(Palette.red)
                }
            } else {
                TabView(selection: $index) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { i, photo in
                        galleryPage(photo)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .onChange(of: index) { _ in Haptics.selection() }
            }

            // Top chrome
            VStack {
                HStack {
                    Button {
                        Haptics.soft()
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }

                    Spacer()

                    if let p = current {
                        VStack(spacing: 2) {
                            Text(p.date)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            if photos.count > 1 {
                                Text("\(min(index + 1, photos.count)) / \(photos.count)")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                        }
                    }

                    Spacer()

                    Button { saveCurrent() } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Save to Photos")
                    .disabled(current == nil)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                HStack(spacing: 14) {
                    Text(photos.count > 1 ? "Pinch to zoom · swipe for next" : "Pinch to zoom · double-tap")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    if current != nil {
                        Button(role: .destructive) {
                            Haptics.warning()
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16).padding(.vertical, 11)
                                .background(Color.red.opacity(0.55))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .statusBarHidden(true)
        .onAppear {
            // Clamp index if start was out of range after a prior delete.
            if index >= photos.count { index = max(photos.count - 1, 0) }
        }
        .alert("Photos", isPresented: Binding(
            get: { saveMessage != nil },
            set: { if !$0 { saveMessage = nil } }
        )) {
            Button("OK", role: .cancel) { saveMessage = nil }
        } message: { Text(saveMessage ?? "") }
        .confirmationDialog("Delete this photo?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteCurrent() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func galleryPage(_ photo: ProgressPhoto) -> some View {
        VStack(spacing: 0) {
            GalleryZoomPage(photo: photo)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let note = photo.note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
    }

    private func deleteCurrent() {
        guard let id = current?.id else { return }
        let remaining = photos.count - 1
        state.deleteProgressPhoto(id: id)
        Haptics.warning()
        if remaining <= 0 {
            onClose()
        } else if index >= remaining {
            index = remaining - 1
        }
    }

    private func saveCurrent() {
        guard let photo = current else {
            Haptics.error()
            saveMessage = "Couldn't load this photo."
            return
        }
        Task {
            guard let ui = await ProgressPhotoImage.loadUIImage(photo) else {
                await MainActor.run {
                    Haptics.error()
                    saveMessage = "Couldn't load this photo."
                }
                return
            }
            Self.saveToPhotos(ui) { ok, msg in
                DispatchQueue.main.async {
                    if ok {
                        Haptics.success()
                        saveMessage = "Saved to Photos"
                    } else {
                        Haptics.error()
                        saveMessage = msg
                    }
                }
            }
        }
    }

    /// Shared helper used by gallery + context menu.
    static func saveToPhotos(_ image: UIImage, completion: @escaping (Bool, String) -> Void) {
        let handler: (PHAuthorizationStatus) -> Void = { status in
            guard status == .authorized || status == .limited else {
                completion(false, "Photos access is required to save. Enable it in Settings → fitOS.")
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { ok, err in
                if ok {
                    completion(true, "Saved")
                } else {
                    completion(false, err?.localizedDescription ?? "Couldn't save photo.")
                }
            }
        }
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly, handler: handler)
        } else {
            PHPhotoLibrary.requestAuthorization(handler)
        }
    }
}

// MARK: - Gallery page (loads R2 or base64, then zooms)

private struct GalleryZoomPage: View {
    let photo: ProgressPhoto
    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let image {
                ZoomableImageView(image: image)
            } else if failed {
                Text("Can't load image")
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                ProgressView().tint(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: photo.id) {
            if let ui = await ProgressPhotoImage.loadUIImage(photo) {
                image = ui
                failed = false
            } else {
                failed = true
            }
        }
    }
}

// MARK: - Zoomable image (pinch + double-tap + pan)

/// UIScrollView-backed zoom so pinch/pan works inside a paging TabView.
struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> ZoomScrollView {
        let scroll = ZoomScrollView()
        scroll.delegate = context.coordinator
        scroll.backgroundColor = .clear
        scroll.minimumZoomScale = 1
        scroll.maximumZoomScale = 5
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = false
        scroll.bouncesZoom = true
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.delaysContentTouches = false

        let iv = UIImageView(image: image)
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = true
        scroll.imageView = iv
        scroll.addSubview(iv)

        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scroll.addGestureRecognizer(doubleTap)

        context.coordinator.scrollView = scroll
        context.coordinator.imageView = iv
        scroll.onLayout = { [weak coordinator = context.coordinator] in
            coordinator?.layoutImage()
        }
        return scroll
    }

    func updateUIView(_ scroll: ZoomScrollView, context: Context) {
        guard let iv = context.coordinator.imageView else { return }
        if iv.image !== image {
            iv.image = image
            scroll.setZoomScale(1, animated: false)
            context.coordinator.layoutImage()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var scrollView: ZoomScrollView?
        weak var imageView: UIImageView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerImage()
        }

        func layoutImage() {
            guard let scroll = scrollView, let iv = imageView, let img = iv.image else { return }
            let bounds = scroll.bounds.size
            guard bounds.width > 1, bounds.height > 1 else { return }

            let imgSize = img.size
            guard imgSize.width > 0, imgSize.height > 0 else { return }

            // Fit image at zoomScale 1
            let fit = min(bounds.width / imgSize.width, bounds.height / imgSize.height)
            let w = imgSize.width * fit
            let h = imgSize.height * fit
            let zoom = scroll.zoomScale
            // Reset base frame at scale 1 then let zoom transform apply via contentSize
            if abs(zoom - 1) < 0.01 {
                iv.frame = CGRect(x: 0, y: 0, width: w, height: h)
                scroll.contentSize = CGSize(width: w, height: h)
            }
            centerImage()
        }

        func centerImage() {
            guard let scroll = scrollView, let iv = imageView else { return }
            let bounds = scroll.bounds.size
            let size = iv.frame.size
            let x = max((bounds.width - size.width) / 2, 0)
            let y = max((bounds.height - size.height) / 2, 0)
            var frame = iv.frame
            frame.origin = CGPoint(x: x, y: y)
            iv.frame = frame
        }

        @objc func handleDoubleTap(_ gr: UITapGestureRecognizer) {
            guard let scroll = scrollView else { return }
            if scroll.zoomScale > 1.05 {
                scroll.setZoomScale(1, animated: true)
                Haptics.soft()
            } else {
                let point = gr.location(in: imageView)
                let target: CGFloat = 2.5
                let size = scroll.bounds.size
                let w = size.width / target
                let h = size.height / target
                let rect = CGRect(x: point.x - w / 2, y: point.y - h / 2, width: w, height: h)
                scroll.zoom(to: rect, animated: true)
                Haptics.soft()
            }
        }
    }
}

/// Scroll view that re-lays out the image when bounds change.
final class ZoomScrollView: UIScrollView {
    var imageView: UIImageView?
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }
}
