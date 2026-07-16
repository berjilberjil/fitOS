import SwiftUI

/// The fitOS card surface — barely lifted off pure black, hairline border, 22px radius.
struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(Palette.border, lineWidth: 1)
            )
    }
}

/// A single macro progress ring (consumed vs target).
struct MacroRing: View {
    let value: Double
    let target: Double
    let label: String
    let unit: String
    var tint: Color = Palette.red
    var size: CGFloat = 92

    private var pct: Double { target > 0 ? min(value / target, 1) : 0 }
    private var over: Bool { target > 0 && value > target }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(Palette.surface2, lineWidth: 9)
                Circle()
                    .trim(from: 0, to: pct)
                    .stroke(over ? Palette.warn : tint,
                            style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.35), value: pct)
                VStack(spacing: 1) {
                    Text("\(Int(value.rounded()))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.text)
                    Text(unit).font(.system(size: 10)).foregroundStyle(Palette.faint)
                }
            }
            .frame(width: size, height: size)
            Text(label).eyebrow()
            Text("of \(Int(target.rounded()))")
                .font(.system(size: 11)).foregroundStyle(Palette.muted)
        }
    }
}

/// A thin macro bar (protein / carbs / fats) with a filled portion.
struct MacroBar: View {
    let label: String
    let value: Double
    let target: Double
    let tint: Color

    private var pct: Double { target > 0 ? min(value / target, 1) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.muted)
                Spacer()
                Text("\(Int(value.rounded())) / \(Int(target.rounded()))g")
                    .font(.system(size: 12, design: .rounded)).foregroundStyle(Palette.faint)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.surface2)
                    Capsule().fill(tint).frame(width: geo.size.width * pct)
                        .animation(.easeOut(duration: 0.35), value: pct)
                }
            }
            .frame(height: 7)
        }
    }
}

/// Small labelled stat.
struct StatTile: View {
    let label: String
    let value: String
    var accent: Color = Palette.text
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).eyebrow()
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A pill-shaped primary button in the fitOS red.
struct PrimaryButton: View {
    let title: String
    var loading = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                if loading { ProgressView().tint(.white) }
                Text(title).font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Palette.red)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .disabled(loading)
    }
}

/// Screen scaffold: black background + a scrollable, titled body.
struct Screen<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    content
                }
                .padding(16)
            }
            .background(Palette.bg)
            .navigationTitle(title)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
