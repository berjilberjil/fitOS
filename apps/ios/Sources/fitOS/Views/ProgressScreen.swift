import SwiftUI
import Charts

struct ProgressScreen: View {
    @EnvironmentObject var state: AppState
    @State private var showAddWeight = false
    @State private var newWeight = ""

    private struct Point: Identifiable {
        let id = UUID()
        let date: Date
        let kg: Double
    }

    private var points: [Point] {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return state.weightLog.compactMap { key, kg in
            f.date(from: key).map { Point(date: $0, kg: kg) }
        }
        .sorted { $0.date < $1.date }
    }

    var body: some View {
        Screen(title: "Progress") {
            statsCard
            weightCard
            bmiCard
        }
        .sheet(isPresented: $showAddWeight) { addWeightSheet }
    }

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

    private var weightCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Weight trend").eyebrow()
                    Spacer()
                    Button { showAddWeight = true } label: {
                        Label("Log", systemImage: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Palette.red)
                    }
                }
                if points.count < 2 {
                    Text("Log your weight a few times to see the trend.")
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

    private var bmiCard: some View {
        let bmi = Nutrition.bmi(state.profile)
        return Card {
            HStack {
                StatTile(label: "BMI", value: String(format: "%.1f", bmi))
                StatTile(label: "Status", value: Nutrition.bmiLabel(bmi), accent: Palette.ok)
            }
        }
    }

    private var addWeightSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Log weight").font(.system(size: 22, weight: .bold)).foregroundStyle(Palette.text)
            TextField("", text: $newWeight,
                      prompt: Text("kg, e.g. 64.5").foregroundColor(Palette.faint))
                .keyboardType(.decimalPad)
                .padding(14)
                .background(Palette.surface2)
                .foregroundStyle(Palette.text)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            PrimaryButton(title: "Save") {
                if let kg = Double(newWeight.replacingOccurrences(of: ",", with: ".")) {
                    state.recordWeight(kg)
                }
                newWeight = ""
                showAddWeight = false
            }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.bg.ignoresSafeArea())
        .presentationDetents([.height(240)])
    }

    private func fmt(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}
