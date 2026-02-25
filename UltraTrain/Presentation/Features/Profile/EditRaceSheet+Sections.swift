import SwiftUI

// MARK: - Form Sections, Bindings, Validation & Save

extension EditRaceSheet {

    // MARK: - Bindings

    var distanceBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { UnitFormatter.distanceValue(distanceKm, unit: .imperial) },
                set: { distanceKm = UnitFormatter.distanceToKm($0, unit: .imperial) }
            )
            : $distanceKm
    }

    var elevationGainBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { UnitFormatter.elevationValue(elevationGainM, unit: .imperial) },
                set: { elevationGainM = UnitFormatter.elevationToMeters($0, unit: .imperial) }
            )
            : $elevationGainM
    }

    var elevationLossBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { UnitFormatter.elevationValue(elevationLossM, unit: .imperial) },
                set: { elevationLossM = UnitFormatter.elevationToMeters($0, unit: .imperial) }
            )
            : $elevationLossM
    }

    // MARK: - Priority Section

    var prioritySection: some View {
        Section("Priority") {
            Picker("Priority", selection: $priority) {
                ForEach(RacePriority.allCases, id: \.self) { p in
                    Text(p.displayName).tag(p)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityHint("A Race is your main goal, B Race is important, C Race is a training race")
        }
    }

    // MARK: - Goal Section

    var goalSection: some View {
        Section("Goal") {
            Picker("Goal Type", selection: $goalType) {
                ForEach(RaceGoalSelection.allCases, id: \.self) { goal in
                    Text(goal.displayName).tag(goal)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityHint("Choose your race goal: finish, target time, or target ranking")

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

    // MARK: - Terrain Section

    var terrainSection: some View {
        Section("Terrain Difficulty") {
            Picker("Terrain", selection: $terrainDifficulty) {
                ForEach(TerrainDifficulty.allCases, id: \.self) { terrain in
                    Text(terrain.rawValue.capitalized).tag(terrain)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityHint("Select the terrain difficulty of your race course")
        }
    }

    // MARK: - Checkpoints Section

    var checkpointsSection: some View {
        Section {
            Button {
                showDocumentPicker = true
            } label: {
                Label("Import GPX Course", systemImage: "doc.badge.arrow.up")
            }
            .accessibilityHint("Import a GPX file to automatically populate the course route and checkpoints")
            if routeRepository != nil {
                Button {
                    showRoutePicker = true
                } label: {
                    Label("Pick from Route Library", systemImage: "map.fill")
                }
                .accessibilityHint("Select a saved route to use as the race course")
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
                                    .accessibilityHidden(true)
                            } else {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(Theme.Colors.primary)
                                    .accessibilityHidden(true)
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
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(cp.name), \(AccessibilityFormatters.distance(cp.distanceFromStartKm, unit: units)), \(AccessibilityFormatters.elevation(cp.elevationM, unit: units))\(cp.hasAidStation ? ", aid station" : "")")
                    .accessibilityHint("Double tap to edit this checkpoint")
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
            .accessibilityHint("Opens the form to add a new checkpoint")
        } header: {
            Text("Checkpoints")
        } footer: {
            Text("Import a GPX file or add waypoints manually for predicted split times.")
        }
    }

    var sortedCheckpoints: [Checkpoint] {
        checkpoints.sorted { $0.distanceFromStartKm < $1.distanceFromStartKm }
    }

    // MARK: - Validation & Save

    var isValid: Bool {
        let nameValid = !name.trimmingCharacters(in: .whitespaces).isEmpty
        let goalValid: Bool = switch goalType {
        case .finish: true
        case .targetTime: targetTimeHours > 0 || targetTimeMinutes > 0
        case .targetRanking: targetRanking > 0
        }
        return nameValid && goalValid
    }

    func buildGoal() -> RaceGoal {
        switch goalType {
        case .finish: .finish
        case .targetTime: .targetTime(TimeInterval(targetTimeHours * 3600 + targetTimeMinutes * 60))
        case .targetRanking: .targetRanking(targetRanking)
        }
    }

    func applyImportedCourse(_ result: CourseImportResult) {
        distanceKm = result.distanceKm
        elevationGainM = result.elevationGainM
        elevationLossM = result.elevationLossM
        checkpoints = result.checkpoints
        courseRoute = result.courseRoute
        savedRouteId = nil
        if let gpxName = result.name, name.isEmpty {
            name = gpxName
        }
    }

    func applyRoute(_ route: SavedRoute) {
        distanceKm = route.distanceKm
        elevationGainM = route.elevationGainM
        elevationLossM = route.elevationLossM
        checkpoints = route.checkpoints
        courseRoute = route.courseRoute
        savedRouteId = route.id
        if name.isEmpty {
            name = route.name
        }
    }

    func save() {
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
        race.savedRouteId = savedRouteId
        onSave(race)
        dismiss()
    }
}
