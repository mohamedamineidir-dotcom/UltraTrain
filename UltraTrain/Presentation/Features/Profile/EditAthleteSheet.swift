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
    }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                dateOfBirthSection
                bodyMetricsSection
                heartRateSection
                experienceSection
                runningHistorySection
                unitSection
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!isValid)
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

    private var bodyMetricsSection: some View {
        Section("Body Metrics") {
            LabeledStepper(label: "Weight", value: $weightKg, range: 30...200, step: 0.5, unit: "kg")
            LabeledStepper(label: "Height", value: $heightCm, range: 100...250, step: 1, unit: "cm")
        }
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
        }
    }

    private var runningHistorySection: some View {
        Section("Running History") {
            LabeledStepper(label: "Weekly Volume", value: $weeklyVolumeKm, range: 0...200, step: 5, unit: "km")
            LabeledStepper(label: "Longest Run", value: $longestRunKm, range: 0...300, step: 5, unit: "km")
        }
    }

    private var unitSection: some View {
        Section("Units") {
            Picker("Preferred Unit", selection: $preferredUnit) {
                Text("Metric").tag(UnitPreference.metric)
                Text("Imperial").tag(UnitPreference.imperial)
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Validation & Save

    private var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
        && !lastName.trimmingCharacters(in: .whitespaces).isEmpty
        && maxHeartRate > restingHeartRate
    }

    private func save() {
        let updated = Athlete(
            id: athlete.id,
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            dateOfBirth: dateOfBirth,
            weightKg: weightKg,
            heightCm: heightCm,
            restingHeartRate: restingHeartRate,
            maxHeartRate: maxHeartRate,
            experienceLevel: experienceLevel,
            weeklyVolumeKm: weeklyVolumeKm,
            longestRunKm: longestRunKm,
            preferredUnit: preferredUnit
        )
        onSave(updated)
        dismiss()
    }
}
