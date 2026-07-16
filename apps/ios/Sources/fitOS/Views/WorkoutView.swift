import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var state: AppState
    @State private var search = ""

    private var filtered: [Exercise] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return state.allExercises }
        return state.allExercises.filter {
            $0.name.lowercased().contains(q) || $0.primary.lowercased().contains(q)
        }
    }

    private var grouped: [(String, [Exercise])] {
        Dictionary(grouping: filtered, by: \.category)
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { category, exercises in
                    Section {
                        ForEach(exercises) { ex in
                            HStack(spacing: 12) {
                                Text(ex.icon).font(.system(size: 22))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ex.name).font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Palette.text)
                                    Text("\(ex.equipment) · \(ex.primary)")
                                        .font(.system(size: 12)).foregroundStyle(Palette.faint)
                                }
                                Spacer()
                                if !ex.weighted {
                                    Text("bodyweight").font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Palette.ok)
                                }
                            }
                            .padding(.vertical, 2)
                            .listRowBackground(Palette.surface)
                        }
                    } header: {
                        Text(category).eyebrow()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.bg)
            .navigationTitle("Workout")
            .searchable(text: $search, prompt: "Search exercises")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
