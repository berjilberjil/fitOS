import SwiftUI

/// Anatomy: front/back body map with tappable muscles → the split every gym-goer
/// should know + the best exercises for that muscle (ranked by activation).
struct AnatomyView: View {
    @EnvironmentObject var state: AppState
    @State private var view = "front"
    @State private var selectedId: String?

    var body: some View {
        Group {
            if let a = state.anatomy {
                content(a)
            } else {
                VStack(spacing: 12) {
                    ProgressView().tint(Palette.red)
                    Text("Loading anatomy…").font(.system(size: 13)).foregroundStyle(Palette.muted)
                }
                .frame(maxWidth: .infinity, minHeight: 320)
            }
        }
        .task {
            await state.loadAnatomy()
            if selectedId == nil { selectedId = state.anatomy?.groups.first?.id }
        }
    }

    @ViewBuilder
    private func content(_ a: AnatomyData) -> some View {
        let selected = a.groups.first { $0.id == selectedId } ?? a.groups.first
        ScrollView {
            VStack(spacing: 16) {
                Picker("", selection: $view) {
                    Text("Front").tag("front")
                    Text("Back").tag("back")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                chips(a.groups, selectedId: selected?.id)

                BodyMapView(
                    bodyView: view == "front" ? a.front : a.back,
                    activeSlugs: Set(selected?.view == view ? (selected?.slugs ?? []) : []),
                    interactiveSlugs: Set(a.groups.filter { $0.view == view }.flatMap { $0.slugs }),
                    onSelect: { slug in
                        if let g = a.groups.first(where: { $0.view == view && $0.slugs.contains(slug) }) {
                            selectedId = g.id
                        }
                    }
                )
                .frame(height: 420)
                .frame(maxWidth: .infinity)

                if let selected {
                    MuscleDetailCard(group: selected).padding(.horizontal, 16)
                    ActivationListView(activation: a.activation[selected.id] ?? []).padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 10)
        }
        .background(Palette.bg)
    }

    private func chips(_ groups: [MuscleGroup], selectedId sel: String?) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(groups) { g in
                    let on = g.id == sel
                    Button {
                        selectedId = g.id; view = g.view
                    } label: {
                        HStack(spacing: 6) {
                            Text(g.icon).font(.system(size: 13))
                            Text(g.name).font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(on ? Palette.redSoft : Palette.surface2)
                        .foregroundStyle(on ? Palette.red : Palette.muted)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(on ? Palette.red.opacity(0.5) : Palette.border, lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

/// Renders the body outline + muscle regions from SVG paths, scaled to fit.
struct BodyMapView: View {
    let bodyView: BodyView
    let activeSlugs: Set<String>
    let interactiveSlugs: Set<String>
    let onSelect: (String) -> Void

    @State private var muscles: [(slug: String, path: CGPath)] = []
    @State private var outline: CGPath = CGMutablePath()

    private var box: CGRect {
        let p = bodyView.viewBox.split(separator: " ").compactMap { Double($0) }
        guard p.count == 4 else { return CGRect(x: 0, y: 0, width: 724, height: 1448) }
        return CGRect(x: p[0], y: p[1], width: p[2], height: p[3])
    }

    var body: some View {
        ZStack {
            ForEach(Array(muscles.enumerated()), id: \.offset) { _, m in
                let active = activeSlugs.contains(m.slug)
                let clickable = interactiveSlugs.contains(m.slug)
                let shape = CGPathShape(cg: m.path, box: box)
                shape
                    .fill(active ? Palette.red : (clickable ? Palette.elevated : Palette.surface2))
                    .overlay(shape.stroke(Palette.bg, lineWidth: 1))
                    .contentShape(shape)
                    .onTapGesture { if clickable { onSelect(m.slug) } }
            }
            CGPathShape(cg: outline, box: box)
                .stroke(Palette.borderStrong, lineWidth: 1.5)
                .allowsHitTesting(false)
        }
        .task(id: bodyView.viewBox) { parse() }
    }

    private func parse() {
        muscles = bodyView.muscles.map { m in
            let cg = CGMutablePath()
            for d in m.paths { cg.addPath(SVGPath.cgPath(from: d)) }
            return (m.slug, cg)
        }
        outline = SVGPath.cgPath(from: bodyView.outline)
    }
}

/// A Shape backed by a CGPath in viewBox coordinates, fitted (aspect-preserving) into its rect.
struct CGPathShape: Shape {
    let cg: CGPath
    let box: CGRect
    func path(in rect: CGRect) -> Path {
        guard box.width > 0, box.height > 0 else { return Path(cg) }
        let scale = min(rect.width / box.width, rect.height / box.height)
        let ox = rect.minX + (rect.width - box.width * scale) / 2 - box.minX * scale
        let oy = rect.minY + (rect.height - box.height * scale) / 2 - box.minY * scale
        var t = CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: ox, ty: oy)
        return Path(cg.copy(using: &t) ?? cg)
    }
}

/// The selected muscle group's blurb + the muscles inside it.
struct MuscleDetailCard: View {
    let group: MuscleGroup
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(group.icon).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name).font(.system(size: 20, weight: .bold)).foregroundStyle(Palette.text)
                    Text("\(group.muscles.count) muscles").eyebrow()
                }
            }
            Text(group.blurb).font(.system(size: 13)).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)

            ForEach(Array(group.muscles.enumerated()), id: \.offset) { i, m in
                Card(padding: 13) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 9) {
                            Text("\(i + 1)")
                                .font(.system(size: 11, weight: .heavy))
                                .frame(width: 20, height: 20)
                                .background(Palette.redSoft).foregroundStyle(Palette.redBright).clipShape(Circle())
                            Text(m.name).font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.text)
                        }
                        Text(m.what).font(.system(size: 12.5)).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
                        (Text("TRAIN  ").font(.system(size: 10, weight: .bold)).foregroundColor(Palette.faint)
                         + Text(m.train).font(.system(size: 12)).foregroundColor(Palette.text))
                    }
                }
            }
        }
    }
}

/// Best exercises for the selected muscle, ranked by activation. Tap → demo.
struct ActivationListView: View {
    @EnvironmentObject var state: AppState
    let activation: [Activation]
    @State private var demo: Exercise?

    private var rows: [(ex: Exercise, percent: Double)] {
        activation.compactMap { a in
            if let ex = state.allExercises.first(where: { $0.name.lowercased() == a.name.lowercased() }) {
                return (ex, a.percent)
            }
            return nil
        }
    }

    var body: some View {
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Best builders").eyebrow()
                    Spacer()
                    Text("ranked by activation").font(.system(size: 10.5)).foregroundStyle(Palette.faint)
                }
                ForEach(Array(rows.enumerated()), id: \.offset) { i, r in
                    Button { demo = r.ex } label: { row(i, r.ex, r.percent) }
                        .buttonStyle(.plain)
                }
            }
            .sheet(item: $demo) { ex in
                ExerciseDetailSheet(exercise: ex) { state.addExerciseToday(ex.id) }
            }
        }
    }

    private func row(_ i: Int, _ ex: Exercise, _ percent: Double) -> some View {
        let top = i == 0
        return HStack(spacing: 10) {
            Text("\(i + 1)")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(top ? Palette.red : Palette.faint).frame(width: 16)
            thumb(ex)
            VStack(alignment: .leading, spacing: 5) {
                Text(ex.name).font(.system(size: 13.5, weight: .semibold)).foregroundStyle(Palette.text).lineLimit(1)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Palette.elevated)
                        Capsule().fill(Palette.red).frame(width: geo.size.width * percent / 100)
                    }
                }
                .frame(height: 5)
            }
            Text("\(Int(percent))%")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(top ? Palette.red : Palette.muted).frame(width: 34, alignment: .trailing)
        }
        .padding(.horizontal, 11).padding(.vertical, 8)
        .background(top ? Palette.redSoft : Palette.surface2)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
            .stroke(top ? Palette.red.opacity(0.42) : Palette.border, lineWidth: 1))
    }

    private func thumb(_ ex: Exercise) -> some View {
        ZStack {
            Palette.surface2
            if let s = state.mediaFor(ex.id)?.still, let url = URL(string: s) {
                AsyncImage(url: url) { img in img.resizable().scaledToFill() } placeholder: { Text(ex.icon).font(.system(size: 15)) }
            } else {
                Text(ex.icon).font(.system(size: 15))
            }
        }
        .frame(width: 40, height: 40).clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}
