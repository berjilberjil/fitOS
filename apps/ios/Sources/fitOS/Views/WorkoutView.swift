import SwiftUI

/// Workout tab: Today's session / weekly Plan / catalog Browse.
struct WorkoutView: View {
    @State private var tab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                Picker("", selection: $tab) {
                    Text("Today").tag(0)
                    Text("Plan").tag(1)
                    Text("Browse").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 6)

                switch tab {
                case 0: WorkoutSessionView()
                case 1: WorkoutPlanView()
                default: ExerciseCatalog()
                }
            }
            .background(Palette.bg)
            .navigationTitle("Workout")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

/// Read-only exercise catalog with search.
struct ExerciseCatalog: View {
    @EnvironmentObject var state: AppState
    @State private var search = ""

    private var grouped: [(String, [Exercise])] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        let list = q.isEmpty ? state.allExercises
            : state.allExercises.filter { $0.name.lowercased().contains(q) || $0.primary.lowercased().contains(q) }
        return Dictionary(grouping: list, by: \.category)
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        List {
            ForEach(grouped, id: \.0) { category, exercises in
                Section {
                    ForEach(exercises) { ex in
                        HStack(spacing: 12) {
                            Text(ex.icon).font(.system(size: 22))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ex.name).font(.system(size: 15, weight: .medium)).foregroundStyle(Palette.text)
                                Text("\(ex.equipment) · \(ex.primary)").font(.system(size: 12)).foregroundStyle(Palette.faint)
                            }
                            Spacer()
                            if !ex.weighted {
                                Text("bodyweight").font(.system(size: 10, weight: .bold)).foregroundStyle(Palette.ok)
                            }
                        }
                        .padding(.vertical, 2)
                        .listRowBackground(Palette.surface)
                    }
                } header: { Text(category).eyebrow() }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.bg)
        .searchable(text: $search, prompt: "Search exercises")
    }
}
