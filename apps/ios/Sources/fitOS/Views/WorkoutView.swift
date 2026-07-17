import SwiftUI

/// Workout tab: Today's session / weekly Plan / catalog Browse / Body.
struct WorkoutView: View {
    @State private var tab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    Text("Today").tag(0)
                    Text("Plan").tag(1)
                    Text("Browse").tag(2)
                    Text("Body").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)

                // Keep all segments mounted in a fixed frame so switching never
                // relayouts / jumps (different content heights, searchable, etc.).
                ZStack(alignment: .top) {
                    WorkoutSessionView()
                        .opacity(tab == 0 ? 1 : 0)
                        .allowsHitTesting(tab == 0)
                        .accessibilityHidden(tab != 0)
                    WorkoutPlanView()
                        .opacity(tab == 1 ? 1 : 0)
                        .allowsHitTesting(tab == 1)
                        .accessibilityHidden(tab != 1)
                    ExerciseCatalog()
                        .opacity(tab == 2 ? 1 : 0)
                        .allowsHitTesting(tab == 2)
                        .accessibilityHidden(tab != 2)
                    AnatomyView()
                        .opacity(tab == 3 ? 1 : 0)
                        .allowsHitTesting(tab == 3)
                        .accessibilityHidden(tab != 3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .clipped()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.bg)
            .navigationTitle("Workout")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .accessibilityIdentifier("screen.workout")
        }
        // Kill implicit transitions that make segment switches feel like a jump.
        .transaction { $0.animation = nil }
    }
}

/// Exercise catalog with an *inline* search field (not `.searchable`) so the
/// parent nav bar never grows/shrinks when switching Workout segments.
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
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Palette.faint)
                    TextField("Search exercises", text: $search)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(Palette.text)
                    if !search.isEmpty {
                        Button { search = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.faint)
                        }
                    }
                    Button { newEx = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Palette.red)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(Palette.surface2)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
