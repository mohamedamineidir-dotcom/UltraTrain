import SwiftUI
import UniformTypeIdentifiers

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
    @State private var checkpoints: [Checkpoint]
    @State private var courseRoute: [TrackPoint]
    @State private var showAddCheckpoint = false
    @State private var editingCheckpoint: Checkpoint?
    @State private var showDocumentPicker = false
    @State private var showImportCourse = false
    @State private var importedFileURL: URL?

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
            _checkpoints = State(initialValue: [])
            _courseRoute = State(initialValue: [])
        case .edit(let race):
            existingId = race.id
            _name = State(initialValue: race.name)
            _date = State(initialValue: race.date)
            _distanceKm = State(initialValue: race.distanceKm)
            _elevationGainM = State(initialValue: race.elevationGainM)
            _elevationLossM = State(initialValue: race.elevationLossM)
            _priority = State(initialValue: race.priority)
            _terrainDifficulty = State(initialValue: race.terrainDifficulty)
            _checkpoints = State(initialValue: race.checkpoints)
            _courseRoute = State(initialValue: race.courseRoute)
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
                checkpointsSection
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
            .sheet(isPresented: $showAddCheckpoint) {
                EditCheckpointSheet(raceDistanceKm: distanceKm) { cp in
                    checkpoints.append(cp)
                }
            }
            .sheet(item: $editingCheckpoint) { cp in
                EditCheckpointSheet(checkpoint: cp, raceDistanceKm: distanceKm) { updated in
                    if let index = checkpoints.firstIndex(where: { $0.id == updated.id }) {
                        checkpoints[index] = updated
                    }
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(contentTypes: [.xml]) { url in
                    importedFileURL = url
                    showDocumentPicker = false
                    showImportCourse = true
                }
            }
            .sheet(isPresented: $showImportCourse) {
                if let url = importedFileURL {
                    ImportCourseView(fileURL: url) { result in
                        applyImportedCourse(result)
                    }
                }
            }
        }
    }

    // MARK: - Sections

    @Environment(\.unitPreference) private var units

    private var isImperial: Bool { units == .imperial }

    private var raceInfoSection: some View {
        Section("Race Info") {
            TextField("Race Name", text: $name)
                .autocorrectionDisabled()
            DatePicker("Race Date", selection: $date, in: Date.now..., displayedComponents: .date)
            LabeledStepper(
                label: "Distance",
                value: distanceBinding,
                range: isImperial ? 1...310 : 1...500,
                step: isImperial ? 3 : 5,
                unit: UnitFormatter.distanceLabel(units)
            )
        }
    }

    private var elevationSection: some View {
        Section("Elevation") {
            LabeledStepper(
                label: "D+ (gain)",
                value: elevationGainBinding,
                range: isImperial ? 0...65600 : 0...20000,
                step: isImperial ? 300 : 100,
                unit: UnitFormatter.elevationShortLabel(units)
            )
            LabeledStepper(
                label: "D- (loss)",
                value: elevationLossBinding,
                range: isImperial ? 0...65600 : 0...20000,
                step: isImperial ? 300 : 100,
                unit: UnitFormatter.elevationShortLabel(units)
            )
        }
    }

    private var distanceBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { UnitFormatter.distanceValue(distanceKm, unit: .imperial) },
                set: { distanceKm = UnitFormatter.distanceToKm($0, unit: .imperial) }
            )
            : $distanceKm
    }

    private var elevationGainBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { UnitFormatter.elevationValue(elevationGainM, unit: .imperial) },
                set: { elevationGainM = UnitFormatter.elevationToMeters($0, unit: .imperial) }
            )
            : $elevationGainM
    }

    private var elevationLossBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { UnitFormatter.elevationValue(elevationLossM, unit: .imperial) },
                set: { elevationLossM = UnitFormatter.elevationToMeters($0, unit: .imperial) }
            )
            : $elevationLossM
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

    private var checkpointsSection: some View {
        Section {
            Button {
                showDocumentPicker = true
            } label: {
                Label("Import GPX Course", systemImage: "doc.badge.arrow.up")
            }
            if checkpoints.isEmpty {
                Text("No checkpoints added yet")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                ForEach(sortedCheckpoints) { cp in
                    Button {
                        editingCheckpoint = cp
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            if cp.hasAidStation {
                                Image(systemName: "cross.circle.fill")
                                    .foregroundStyle(Theme.Colors.success)
                            } else {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(Theme.Colors.primary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cp.name)
                                    .foregroundStyle(Theme.Colors.label)
                                Text("\(UnitFormatter.formatDistance(cp.distanceFromStartKm, unit: units, decimals: 0))  ·  \(UnitFormatter.formatElevation(cp.elevationM, unit: units))")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.secondaryLabel)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                        }
                    }
                }
                .onDelete { offsets in
                    let sorted = sortedCheckpoints
                    for offset in offsets {
                        let cpToRemove = sorted[offset]
                        checkpoints.removeAll { $0.id == cpToRemove.id }
                    }
                }
            }

            Button {
                showAddCheckpoint = true
            } label: {
                Label("Add Checkpoint", systemImage: "plus.circle")
            }
        } header: {
            Text("Checkpoints")
        } footer: {
            Text("Import a GPX file or add waypoints manually for predicted split times.")
        }
    }

    private var sortedCheckpoints: [Checkpoint] {
        checkpoints.sorted { $0.distanceFromStartKm < $1.distanceFromStartKm }
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

    private func applyImportedCourse(_ result: CourseImportResult) {
        distanceKm = result.distanceKm
        elevationGainM = result.elevationGainM
        elevationLossM = result.elevationLossM
        checkpoints = result.checkpoints
        courseRoute = result.courseRoute
        if let gpxName = result.name, name.isEmpty {
            name = gpxName
        }
    }

    private func save() {
        var race = Race(
            id: existingId ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            date: date,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: elevationLossM,
            priority: priority,
            goalType: buildGoal(),
            checkpoints: checkpoints,
            terrainDifficulty: terrainDifficulty
        )
        race.courseRoute = courseRoute
        onSave(race)
        dismiss()
    }
}
