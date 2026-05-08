import SwiftUI
import UniformTypeIdentifiers
import os

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
    @State var locationLatitude: Double?
    @State var locationLongitude: Double?
    @State var locationName: String?
    @State var showLocationPicker = false
    @State var raceType: RaceType
    @State var includesSpecificPrep: Bool

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
            // invariant: Calendar.date(byAdding:) always succeeds for simple offsets
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
            _locationLatitude = State(initialValue: nil)
            _locationLongitude = State(initialValue: nil)
            _locationName = State(initialValue: nil)
            _raceType = State(initialValue: .trail)
            _includesSpecificPrep = State(initialValue: false)
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
            _locationLatitude = State(initialValue: race.locationLatitude)
            _locationLongitude = State(initialValue: race.locationLongitude)
            _locationName = State(initialValue: race.locationName)
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
            _raceType = State(initialValue: race.raceType)
            _includesSpecificPrep = State(initialValue: race.includesSpecificPrep)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                raceInfoSection
                if isShortRoadRace {
                    Section {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                            Text("UltraTrain is built for trail and ultra-distance races. For shorter road events, features like altitude training and nutrition planning shine most on longer distances.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                locationSection
                elevationSection
                prioritySection
                goalSection
                if showSpecificPrepToggle {
                    specificPrepSection
                }
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
            .sheet(isPresented: $showLocationPicker) {
                RaceLocationPickerSheet { lat, lon, name in
                    locationLatitude = lat
                    locationLongitude = lon
                    locationName = name
                }
            }
            .sheet(isPresented: $showRoutePicker) {
                RaceRoutePickerSheet(routes: availableRoutes) { route in
                    applyRoute(route)
                }
            }
            .task {
                guard let repo = routeRepository else { return }
                do {
                    availableRoutes = try await repo.getRoutes()
                } catch {
                    Logger.routePlanning.warning("EditRaceSheet: failed to load routes: \(error)")
                    availableRoutes = []
                }
            }
        }
    }

    // MARK: - Race Info Section

    @Environment(\.unitPreference) var units

    var isImperial: Bool { units == .imperial }

    private var isShortRoadRace: Bool {
        elevationGainM < 100 && distanceKm < 42.195 && distanceKm > 0
    }

    /// True when this race is a road B/C race with a target time —
    /// the only case where B-race specificity opt-in makes sense.
    /// Trail/ultra B/C races and `.finish` goals don't surface the
    /// toggle (consensus: trail/ultra prep IS the specificity; no
    /// time goal = no need for pace work).
    var showSpecificPrepToggle: Bool {
        guard priority != .aRace else { return false }
        guard goalType == .targetTime else { return false }
        let isRoadByType = raceType == .road
        let isRoadByHeuristic = elevationGainM < 100 && distanceKm < 50 && distanceKm > 0
        return isRoadByType || isRoadByHeuristic
    }

    @ViewBuilder
    var specificPrepSection: some View {
        Section {
            Toggle(isOn: $includesSpecificPrep) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Race-pace prep for this race")
                        .font(.subheadline.weight(.semibold))
                    Text("Adds 1-3 race-pace quality sessions in the 2-3 weeks before this race — VO2max for 10K, threshold for HM, MP blocks for marathon. Replaces existing intervals, no extra fatigue.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Theme.Colors.warmCoral)
        } header: {
            Text("Specific prep")
        } footer: {
            Text("Off by default. When off, this race stays on your calendar with a standard mini-taper + recovery, but your training stays focused on your A-race.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var raceInfoSection: some View {
        Section("Race Info") {
            RaceAutoCompleteField(text: $name) { race in
                distanceKm = race.distanceKm
                elevationGainM = race.elevationGainM
                elevationLossM = race.elevationLossM
                if let raceDate = race.nextEditionDate, raceDate > Date.now {
                    date = raceDate
                }
            }
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
