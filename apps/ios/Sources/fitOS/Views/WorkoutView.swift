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
                    Text("Body").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 6)

                switch tab {
                case 0: WorkoutSessionView()
                case 1: WorkoutPlanView()
                case 2: ExerciseCatalog()
                default: AnatomyView()
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
    @State private var detail: Exercise?
    @State private var editingEx: Exercise?
    @State private var newEx = false

    private var grouped: [(String, [Exercise])] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        let list = q.isEmpty ? state.allExercises
            : state.allExercises.filter { $0.name.lowercased().contains(q) || $0.primary.lowercased().contains(q) }
        return Dictionary(grouping: list, by: \.category)
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.0 < $1.0 }
    }

    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ForEach(grouped, id: \.0) { category, exercises in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(category).eyebrow()
                        LazyVGrid(columns: cols, spacing: 12) {
                            ForEach(exercises) { ex in card(ex) }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Palette.bg)
        .searchable(text: $search, prompt: "Search exercises")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { newEx = true } label: { Image(systemName: "plus") }.tint(Palette.red)
            }
        }
        .sheet(item: $detail) { ex in
            ExerciseDetailSheet(exercise: ex) { state.addExerciseToday(ex.id) }
        }
        .sheet(item: $editingEx) { ExerciseEditorSheet(editing: $0) }
        .sheet(isPresented: $newEx) { ExerciseEditorSheet(editing: nil) }
    }

    private func card(_ ex: Exercise) -> some View {
        Button { detail = ex } label: {
            VStack(alignment: .leading, spacing: 0) {
                ExerciseThumb(still: state.mediaFor(ex.id)?.still, emoji: ex.icon)
                VStack(alignment: .leading, spacing: 2) {
                    Text(ex.name).font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.text).lineLimit(1)
                    Text(ex.primary).font(.system(size: 11)).foregroundStyle(Palette.faint).lineLimit(1)
                }
                .padding(.horizontal, 10).padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).stroke(Palette.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { detail = ex } label: { Label("View demo", systemImage: "play") }
            Button { editingEx = ex } label: { Label("Edit exercise", systemImage: "pencil") }
        }
    }
}
