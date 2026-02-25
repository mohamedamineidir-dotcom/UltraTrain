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
    let routeRepository: (any RouteRepository)?
    @Environment(\.dismiss) var dismiss

    @State var name: String
    @State var date: Date
    @State var distanceKm: Double
    @State var elevationGainM: Double
    @State var elevationLossM: Double
    @State var priority: RacePriority
    @State var goalType: RaceGoalSelection
    @State var targetTimeHours: Int
    @State var targetTimeMinutes: Int
    @State var targetRanking: Int
    @State var terrainDifficulty: TerrainDifficulty
    @State var checkpoints: [Checkpoint]
    @State var courseRoute: [TrackPoint]
    @State var savedRouteId: UUID?
    @State var showAddCheckpoint = false
    @State var editingCheckpoint: Checkpoint?
    @State var showDocumentPicker = false
    @State private var showImportCourse = false
    @State private var importedFileURL: URL?
    @State var showRoutePicker = false
    @State private var availableRoutes: [SavedRoute] = []

    let existingId: UUID?

    init(
        mode: Mode,
        routeRepository: (any RouteRepository)? = nil,
        onSave: @escaping (Race) -> Void
    ) {
        self.mode = mode
        self.onSave = onSave
        self.routeRepository = routeRepository
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
            _savedRouteId = State(initialValue: nil)
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
            _savedRouteId = State(initialValue: race.savedRouteId)
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
                        .accessibilityHint("Discards changes and closes the editor")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                        .accessibilityHint("Saves the race configuration")
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
            .sheet(isPresented: $showRoutePicker) {
                RaceRoutePickerSheet(routes: availableRoutes) { route in
                    applyRoute(route)
                }
            }
            .task {
                guard let repo = routeRepository else { return }
                availableRoutes = (try? await repo.getRoutes()) ?? []
            }
        }
    }

    // MARK: - Race Info Section

    @Environment(\.unitPreference) var units

    var isImperial: Bool { units == .imperial }

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
}
