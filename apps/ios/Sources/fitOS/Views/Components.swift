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

/// Compact − / value / + control with a **fixed** value width so 9 → 10 never
/// overflows or jumps the layout (system Stepper is too wide on half-width cards).
struct CompactIntControl: View {
    let label: String
    let value: Int
    var range: ClosedRange<Int> = 1...99
    var step: Int = 1
    /// Digits reserved for the number (2 → "99", 3 → "999").
    var digits: Int = 2
    let onChange: (Int) -> Void

    private var valueWidth: CGFloat {
        // Monospaced 17pt bold ≈ 11pt per digit + padding.
        CGFloat(max(digits, 1)) * 12 + 4
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.muted)
                .lineLimit(1)
            HStack(spacing: 0) {
                stepButton(systemName: "minus", disabled: value <= range.lowerBound) {
                    onChange(max(range.lowerBound, value - step))
                }
                Text("\(value)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.text)
                    .monospacedDigit()
                    .frame(width: valueWidth, alignment: .center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                stepButton(systemName: "plus", disabled: value >= range.upperBound) {
                    onChange(min(range.upperBound, value + step))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 10).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface2)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
    }

    private func stepButton(systemName: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(disabled ? Palette.faint.opacity(0.45) : Palette.text)
                .frame(width: 34, height: 34)
                .background(Palette.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

/// Weight row: fixed layout − / value / + so kg text never shoves the controls.
struct CompactWeightControl: View {
    let valueKg: Double
    var step: Double = WorkoutDefaults.weightStep
    let onDelta: (Double) -> Void

    private var display: String {
        valueKg == valueKg.rounded()
            ? "\(Int(valueKg)) kg"
            : String(format: "%.1f kg", valueKg)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.muted)
            HStack(spacing: 10) {
                Button {
                    Haptics.tap()
                    onDelta(-step)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Palette.text)
                        .frame(width: 34, height: 34)
                        .background(Palette.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                Text(display)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.text)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)

                Button {
                    Haptics.tap()
                    onDelta(step)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Palette.text)
                        .frame(width: 34, height: 34)
                        .background(Palette.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface2)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
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
    @EnvironmentObject var state: AppState
    @ViewBuilder var content: Content
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let err = state.lastHydrateError {
                        Text(err)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Palette.warn)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Palette.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                    }
                    if let sync = state.lastSyncError {
                        Text(sync)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Palette.warn)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Palette.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                    }
                    content
                }
                .padding(16)
            }
            .background(Palette.bg)
            .navigationTitle(title)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .refreshable { await state.refresh() }
        }
    }
}
