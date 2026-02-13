import SwiftUI

struct EditRaceSheet: View {
    enum Mode {
        case add
        case edit(Race)

        var isAdd: Bool {
            if case .add = self { return true }
            return false
        }
    }

    let mode: Mode
    let onSave: (Race) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var date: Date
    @State private var distanceKm: Double
    @State private var elevationGainM: Double
    @State private var elevationLossM: Double
    @State private var priority: RacePriority
    @State private var goalType: RaceGoalSelection
    @State private var targetTimeHours: Int
    @State private var targetTimeMinutes: Int
    @State private var targetRanking: Int
    @State private var terrainDifficulty: TerrainDifficulty

    private let existingId: UUID?

    init(mode: Mode, onSave: @escaping (Race) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .add:
            existingId = nil
            _name = State(initialValue: "")
            _date = State(initialValue: Calendar.current.date(byAdding: .month, value: 3, to: .now)!)
            _distanceKm = State(initialValue: 50)
            _elevationGainM = State(initialValue: 1000)
            _elevationLossM = State(initialValue: 1000)
            _priority = State(initialValue: .bRace)
            _goalType = State(initialValue: .finish)
            _targetTimeHours = State(initialValue: 10)
            _targetTimeMinutes = State(initialValue: 0)
            _targetRanking = State(initialValue: 50)
            _terrainDifficulty = State(initialValue: .moderate)
        case .edit(let race):
            existingId = race.id
            _name = State(initialValue: race.name)
            _date = State(initialValue: race.date)
            _distanceKm = State(initialValue: race.distanceKm)
            _elevationGainM = State(initialValue: race.elevationGainM)
            _elevationLossM = State(initialValue: race.elevationLossM)
            _priority = State(initialValue: race.priority)
            _terrainDifficulty = State(initialValue: race.terrainDifficulty)
            switch race.goalType {
            case .finish:
                _goalType = State(initialValue: .finish)
                _targetTimeHours = State(initialValue: 10)
                _targetTimeMinutes = State(initialValue: 0)
                _targetRanking = State(initialValue: 50)
            case .targetTime(let seconds):
                _goalType = State(initialValue: .targetTime)
                _targetTimeHours = State(initialValue: Int(seconds) / 3600)
                _targetTimeMinutes = State(initialValue: (Int(seconds) % 3600) / 60)
                _targetRanking = State(initialValue: 50)
            case .targetRanking(let rank):
                _goalType = State(initialValue: .targetRanking)
                _targetTimeHours = State(initialValue: 10)
                _targetTimeMinutes = State(initialValue: 0)
                _targetRanking = State(initialValue: rank)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                raceInfoSection
                elevationSection
                prioritySection
                goalSection
                terrainSection
            }
            .navigationTitle(mode.isAdd ? "Add Race" : "Edit Race")
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

    private var raceInfoSection: some View {
        Section("Race Info") {
            TextField("Race Name", text: $name)
                .autocorrectionDisabled()
            DatePicker("Race Date", selection: $date, in: Date.now..., displayedComponents: .date)
            LabeledStepper(label: "Distance", value: $distanceKm, range: 1...500, step: 5, unit: "km")
        }
    }

    private var elevationSection: some View {
        Section("Elevation") {
            LabeledStepper(label: "D+ (gain)", value: $elevationGainM, range: 0...20000, step: 100, unit: "m")
            LabeledStepper(label: "D- (loss)", value: $elevationLossM, range: 0...20000, step: 100, unit: "m")
        }
    }

    private var prioritySection: some View {
        Section("Priority") {
            Picker("Priority", selection: $priority) {
                ForEach(RacePriority.allCases, id: \.self) { p in
                    Text(p.displayName).tag(p)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var goalSection: some View {
        Section("Goal") {
            Picker("Goal Type", selection: $goalType) {
                ForEach(RaceGoalSelection.allCases, id: \.self) { goal in
                    Text(goal.displayName).tag(goal)
                }
            }
            .pickerStyle(.segmented)

            if goalType == .targetTime {
                HStack(spacing: Theme.Spacing.md) {
                    LabeledIntStepper(label: "Hours", value: $targetTimeHours, range: 0...100, unit: "h")
                    LabeledIntStepper(label: "Min", value: $targetTimeMinutes, range: 0...59, unit: "m")
                }
            }

            if goalType == .targetRanking {
                LabeledIntStepper(label: "Target Position", value: $targetRanking, range: 1...5000, unit: "")
            }
        }
        .animation(.easeInOut(duration: 0.2), value: goalType)
    }

    private var terrainSection: some View {
        Section("Terrain Difficulty") {
            Picker("Terrain", selection: $terrainDifficulty) {
                ForEach(TerrainDifficulty.allCases, id: \.self) { terrain in
                    Text(terrain.rawValue.capitalized).tag(terrain)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Validation & Save

    private var isValid: Bool {
        let nameValid = !name.trimmingCharacters(in: .whitespaces).isEmpty
        let goalValid: Bool = switch goalType {
        case .finish: true
        case .targetTime: targetTimeHours > 0 || targetTimeMinutes > 0
        case .targetRanking: targetRanking > 0
        }
        return nameValid && goalValid
    }

    private func buildGoal() -> RaceGoal {
        switch goalType {
        case .finish: .finish
        case .targetTime: .targetTime(TimeInterval(targetTimeHours * 3600 + targetTimeMinutes * 60))
        case .targetRanking: .targetRanking(targetRanking)
        }
    }

    private func save() {
        let race = Race(
            id: existingId ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            date: date,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: elevationLossM,
            priority: priority,
            goalType: buildGoal(),
            checkpoints: [],
            terrainDifficulty: terrainDifficulty
        )
        onSave(race)
        dismiss()
    }
}
