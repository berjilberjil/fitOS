import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var state: AppState

    @State private var name = ""
    @State private var age = 21.0
    @State private var sex = "male"
    @State private var height = 170.0
    @State private var weight = 65.0
    @State private var target = 65.0
    @State private var activity = 1.375
    @State private var saved = false
    @State private var faceIDLock = BiometricLock.isEnabled

    private let activities: [(String, Double)] = [
        ("Sedentary", 1.2), ("Light", 1.375), ("Moderate", 1.55),
        ("Active", 1.725), ("Athlete", 1.9)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("You") {
                    TextField("Name", text: $name)
                    Picker("Sex", selection: $sex) {
                        Text("Male").tag("male"); Text("Female").tag("female")
                    }
                    stepperRow("Age", value: $age, range: 12...90, step: 1, unit: "")
                }
                Section("Body") {
                    stepperRow("Height", value: $height, range: 120...220, step: 1, unit: "cm")
                    stepperRow("Weight", value: $weight, range: 30...200, step: 0.5, unit: "kg")
                    stepperRow("Target", value: $target, range: 30...200, step: 0.5, unit: "kg")
                }
                Section("Activity") {
                    Picker("Level", selection: $activity) {
                        ForEach(activities, id: \.1) { Text($0.0).tag($0.1) }
                    }
                }
                Section("Targets (Mifflin-St Jeor)") {
                    row("Maintenance", "\(Int(Nutrition.tdee(preview).rounded())) kcal")
                    row("Goal calories", "\(Int(Nutrition.calorieTarget(preview).rounded())) kcal")
                    row("Protein", "\(Int(Nutrition.macroTargets(preview).protein)) g")
                }
                if BiometricLock.isAvailable {
                    Section("Security") {
                        Toggle("Require \(BiometricLock.biometryName)", isOn: $faceIDLock)
                            .tint(Palette.red)
                            .onChange(of: faceIDLock) { on in
                                if on {
                                    Task {
                                        let ok = await BiometricLock.authenticate(reason: "Enable \(BiometricLock.biometryName) lock")
                                        if ok { BiometricLock.isEnabled = true; Haptics.success() } else { faceIDLock = false }
                                    }
                                } else {
                                    BiometricLock.isEnabled = false
                                }
                            }
                    }
                }
                Section {
                    Button {
                        state.saveProfile(preview)
                        saved = true
                    } label: {
                        Text(saved ? "Saved ✓" : "Save profile")
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(Palette.red)
                            .fontWeight(.semibold)
                    }
                    Button(role: .destructive) {
                        Task { await state.logout() }
                    } label: {
                        Text("Log out").frame(maxWidth: .infinity)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.bg)
            .navigationTitle("Profile")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear(perform: seed)
    }

    private var preview: Profile {
        Profile(name: name.isEmpty ? nil : name, age: Int(age), sex: sex,
                heightCm: height, currentWeightKg: weight, targetWeightKg: target,
                activity: activity, onboarded: true)
    }

    private func seed() {
        let p = state.profile
        name = p.name ?? ""
        age = Double(p.age); sex = p.sex
        height = p.heightCm; weight = p.currentWeightKg; target = p.targetWeightKg
        activity = p.activity
    }

    private func stepperRow(_ label: String, value: Binding<Double>,
                            range: ClosedRange<Double>, step: Double, unit: String) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(label)
                Spacer()
                Text(value.wrappedValue == value.wrappedValue.rounded()
                     ? "\(Int(value.wrappedValue))\(unit.isEmpty ? "" : " " + unit)"
                     : String(format: "%.1f %@", value.wrappedValue, unit))
                    .foregroundStyle(Palette.muted)
            }
        }
        .onChange(of: value.wrappedValue) { _ in saved = false }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value).foregroundStyle(Palette.muted) }
    }
}
