import SwiftUI
import Charts
import UIKit
import PhotosUI

/// Progress hub: daily weight (±0.25 kg), trend chart, and compressed progress photos.
struct ProgressScreen: View {
    @EnvironmentObject var state: AppState
    @ObservedObject private var health = HealthService.shared
    @State private var importMessage: String?
    @State private var photoItem: PhotosPickerItem?
    @State private var photoBusy = false
    @State private var photoError: String?
    @State private var expandedPhoto: ProgressPhoto?

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
        .sheet(item: $expandedPhoto) { photo in
            photoDetail(photo)
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

                Text("Photos are resized to 1080px and JPEG-compressed (~80–150 KB) so you can keep weeks of shots without filling storage. Max \(AppState.maxProgressPhotos) photos synced.")
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
        Button { expandedPhoto = photo } label: {
            VStack(alignment: .leading, spacing: 4) {
                Group {
                    if let ui = ImageCompressor.image(fromBase64: photo.jpegBase64) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Palette.surface2
                    }
                }
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
            Button(role: .destructive) {
                state.deleteProgressPhoto(id: photo.id)
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func photoDetail(_ photo: ProgressPhoto) -> some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let ui = ImageCompressor.image(fromBase64: photo.jpegBase64) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                }
                Text(photo.date)
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.text)
                if let note = photo.note, !note.isEmpty {
                    Text(note).font(.system(size: 13)).foregroundStyle(Palette.muted)
                }
                Spacer()
            }
            .padding(16)
            .background(Palette.bg)
            .navigationTitle("Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { expandedPhoto = nil }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete", role: .destructive) {
                        state.deleteProgressPhoto(id: photo.id)
                        expandedPhoto = nil
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
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
            state.addProgressPhoto(jpegBase64: b64)
            Haptics.success()
        } catch {
            photoError = error.localizedDescription
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
