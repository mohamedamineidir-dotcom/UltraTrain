import SwiftUI

struct EditAthleteSheet: View {
    let athlete: Athlete
    let onSave: (Athlete) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String
    @State private var lastName: String
    @State private var dateOfBirth: Date
    @State private var weightKg: Double
    @State private var heightCm: Double
    @State private var restingHeartRate: Int
    @State private var maxHeartRate: Int
    @State private var experienceLevel: ExperienceLevel
    @State private var weeklyVolumeKm: Double
    @State private var longestRunKm: Double
    @State private var preferredUnit: UnitPreference
    @State private var weightGoal: WeightGoal
    @State private var biologicalSex: BiologicalSex
    @State private var itraIndexInput: String
    @State private var utmbIndexInput: String

    init(athlete: Athlete, onSave: @escaping (Athlete) -> Void) {
        self.athlete = athlete
        self.onSave = onSave
        _firstName = State(initialValue: athlete.firstName)
        _lastName = State(initialValue: athlete.lastName)
        _dateOfBirth = State(initialValue: athlete.dateOfBirth)
        _weightKg = State(initialValue: athlete.weightKg)
        _heightCm = State(initialValue: athlete.heightCm)
        _restingHeartRate = State(initialValue: athlete.restingHeartRate)
        _maxHeartRate = State(initialValue: athlete.maxHeartRate)
        _experienceLevel = State(initialValue: athlete.experienceLevel)
        _weeklyVolumeKm = State(initialValue: athlete.weeklyVolumeKm)
        _longestRunKm = State(initialValue: athlete.longestRunKm)
        _preferredUnit = State(initialValue: athlete.preferredUnit)
        _weightGoal = State(initialValue: athlete.weightGoal)
        _biologicalSex = State(initialValue: athlete.biologicalSex)
        _itraIndexInput = State(initialValue: athlete.itraIndex.map { Self.formatIndex($0) } ?? "")
        _utmbIndexInput = State(initialValue: athlete.utmbIndex.map { Self.formatIndex($0) } ?? "")
    }

    private static func formatIndex(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                dateOfBirthSection
                biologicalSexSection
                bodyMetricsSection
                weightGoalSection
                heartRateSection
                experienceSection
                runningHistorySection
                performanceIndexSection
                unitSection
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .accessibilityHint("Discards changes and closes the editor")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                        .accessibilityHint("Saves your profile changes")
                }
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section("Name") {
            TextField("First Name", text: $firstName)
                .textContentType(.givenName)
                .autocorrectionDisabled()
            TextField("Last Name", text: $lastName)
                .textContentType(.familyName)
                .autocorrectionDisabled()
        }
    }

    private var dateOfBirthSection: some View {
        Section("Date of Birth") {
            DatePicker(
                "Date of Birth",
                selection: $dateOfBirth,
                in: ...Date.now,
                displayedComponents: .date
            )
            .labelsHidden()
        }
    }

    private var biologicalSexSection: some View {
        Section("Biological Sex") {
            Picker("Biological Sex", selection: $biologicalSex) {
                Text("Male").tag(BiologicalSex.male)
                Text("Female").tag(BiologicalSex.female)
            }
            .pickerStyle(.segmented)
        }
    }

    private var weightGoalSection: some View {
        Section("Weight Goal") {
            Picker("Weight Goal", selection: $weightGoal) {
                Text("Lose Weight").tag(WeightGoal.lose)
                Text("Maintain").tag(WeightGoal.maintain)
                Text("Gain Weight").tag(WeightGoal.gain)
            }
            .pickerStyle(.segmented)
        }
    }

    private var isImperial: Bool { preferredUnit == .imperial }

    private var bodyMetricsSection: some View {
        Section("Body Metrics") {
            LabeledStepper(
                label: "Weight",
                value: weightBinding,
                range: isImperial ? 66...440 : 30...200,
                step: isImperial ? 1 : 0.5,
                unit: UnitFormatter.weightLabel(preferredUnit)
            )
            LabeledStepper(
                label: "Height",
                value: heightBinding,
                range: isImperial ? 39...98 : 100...250,
                step: 1,
                unit: isImperial ? "in" : "cm"
            )
        }
    }

    private var weightBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { UnitFormatter.weightValue(weightKg, unit: .imperial) },
                set: { weightKg = UnitFormatter.weightToKg($0, unit: .imperial) }
            )
            : $weightKg
    }

    private var heightBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { (heightCm / 2.54).rounded() },
                set: { heightCm = $0 * 2.54 }
            )
            : $heightCm
    }

    private var heartRateSection: some View {
        Section("Heart Rate") {
            LabeledIntStepper(label: "Resting HR", value: $restingHeartRate, range: 30...120, unit: "bpm")
            LabeledIntStepper(label: "Max HR", value: $maxHeartRate, range: 120...230, unit: "bpm")
            if maxHeartRate <= restingHeartRate {
                Text("Max HR must be greater than resting HR")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.danger)
            }
        }
    }

    private var experienceSection: some View {
        Section("Experience") {
            Picker("Level", selection: $experienceLevel) {
                ForEach(ExperienceLevel.allCases, id: \.self) { level in
                    Text(level.rawValue.capitalized).tag(level)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityHint("Select your running experience level")
        }
    }

    private var runningHistorySection: some View {
        Section("Running History") {
            LabeledStepper(
                label: "Weekly Volume",
                value: weeklyVolumeBinding,
                range: isImperial ? 0...124 : 0...200,
                step: isImperial ? 3 : 5,
                unit: UnitFormatter.distanceLabel(preferredUnit)
            )
            LabeledStepper(
                label: "Longest Run",
                value: longestRunBinding,
                range: isImperial ? 0...186 : 0...300,
                step: isImperial ? 3 : 5,
                unit: UnitFormatter.distanceLabel(preferredUnit)
            )
        }
    }

    private var weeklyVolumeBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { UnitFormatter.distanceValue(weeklyVolumeKm, unit: .imperial) },
                set: { weeklyVolumeKm = UnitFormatter.distanceToKm($0, unit: .imperial) }
            )
            : $weeklyVolumeKm
    }

    private var longestRunBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { UnitFormatter.distanceValue(longestRunKm, unit: .imperial) },
                set: { longestRunKm = UnitFormatter.distanceToKm($0, unit: .imperial) }
            )
            : $longestRunKm
    }

    private var performanceIndexSection: some View {
        Section {
            HStack {
                Text("ITRA Index")
                Spacer()
                TextField("Optional", text: $itraIndexInput)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
            }
            HStack {
                Text("UTMB Index")
                Spacer()
                TextField("Optional", text: $utmbIndexInput)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
            }
        } header: {
            Text("Racing Index")
        } footer: {
            Text("Sharpens your finish-time predictions with independent racing history, if you have one.")
        }
    }

    private var unitSection: some View {
        Section("Units") {
            Picker("Preferred Unit", selection: $preferredUnit) {
                Text("Metric").tag(UnitPreference.metric)
                Text("Imperial").tag(UnitPreference.imperial)
            }
            .pickerStyle(.segmented)
            .accessibilityHint("Choose between metric and imperial measurement units")
        }
    }

    // MARK: - Validation & Save

    private var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
        && !lastName.trimmingCharacters(in: .whitespaces).isEmpty
        && maxHeartRate > restingHeartRate
    }

    private func save() {
        // Mutate a copy of the ORIGINAL athlete rather than reconstructing
        // one from only this sheet's own fields — the latter silently
        // resets everything this sheet doesn't edit (PBs, VMA, injury
        // data, ITRA/UTMB index, ...) to their struct defaults on every
        // save, since `Athlete`'s memberwise init fills unlisted
        // parameters with defaults rather than the athlete's real values.
        var updated = athlete
        updated.firstName = firstName.trimmingCharacters(in: .whitespaces)
        updated.lastName = lastName.trimmingCharacters(in: .whitespaces)
        updated.dateOfBirth = dateOfBirth
        updated.weightKg = weightKg
        updated.heightCm = heightCm
        updated.restingHeartRate = restingHeartRate
        updated.maxHeartRate = maxHeartRate
        updated.experienceLevel = experienceLevel
        updated.weeklyVolumeKm = weeklyVolumeKm
        updated.longestRunKm = longestRunKm
        updated.preferredUnit = preferredUnit
        updated.weightGoal = weightGoal
        updated.biologicalSex = biologicalSex

        let trimmedItra = itraIndexInput.trimmingCharacters(in: .whitespaces)
        if trimmedItra.isEmpty {
            updated.itraIndex = nil
            updated.itraIndexUpdatedAt = nil
        } else if let itra = Double(trimmedItra), (0...1000).contains(itra), itra != athlete.itraIndex {
            updated.recordITRAIndex(itra)
        }

        let trimmedUtmb = utmbIndexInput.trimmingCharacters(in: .whitespaces)
        if trimmedUtmb.isEmpty {
            updated.utmbIndex = nil
            updated.utmbIndexUpdatedAt = nil
        } else if let utmb = Double(trimmedUtmb), (0...1000).contains(utmb), utmb != athlete.utmbIndex {
            updated.recordUTMBIndex(utmb)
        }

        onSave(updated)
        dismiss()
    }
}
