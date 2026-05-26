import SwiftUI

// MARK: - Form Sections, Bindings, Validation & Save

extension EditRaceSheet {

    // MARK: - Glass card helpers

    /// Wraps a section's content in a futuristic glass card with a tinted
    /// icon + title header and an optional footer underneath. Used by
    /// every section in the sheet so the layout matches the rest of the
    /// app's premium DNA instead of looking like a stock SwiftUI Form.
    @ViewBuilder
    func glassCard<Content: View>(
        title: String,
        icon: String,
        tint: Color,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(tint))
                    .shadow(color: tint.opacity(0.4), radius: 4, y: 2)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
            }

            content()

            if let footer {
                Text(footer)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: tint)
    }

    /// Compact h:m:s stepper used in the 3-up target-time layout. Stacks a
    /// small unit label above a compact LabeledIntStepper so the row
    /// fits in the card width without the per-stepper inline label
    /// blowing the layout out.
    func compactTimeStepper(
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        unit: String
    ) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            LabeledIntStepper(label: title, value: value, range: range, unit: unit, compact: true)
        }
        .frame(maxWidth: .infinity)
    }

    /// Subtle field chrome used to lift DatePicker / Stepper rows off the
    /// glass background so they read as tappable input affordances rather
    /// than free-floating text.
    var fieldChrome: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
            .fill(Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

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

    // MARK: - Location Section

    var locationSection: some View {
        glassCard(
            title: "Location",
            icon: "mappin.and.ellipse",
            tint: Theme.Colors.info,
            footer: "Used for weather forecasts in your race day estimate."
        ) {
            if let name = locationName {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Theme.Colors.info)
                        .accessibilityHidden(true)
                    Text(name)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Button("Change") { showLocationPicker = true }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Colors.warmCoral)
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.sm)
                .background(fieldChrome)
            } else {
                pillButton(
                    title: "Set race location",
                    icon: "mappin.and.ellipse",
                    tint: Theme.Colors.info
                ) {
                    showLocationPicker = true
                }
            }
        }
    }

    // MARK: - Priority Section

    var prioritySection: some View {
        glassCard(
            title: "Priority",
            icon: "star.fill",
            tint: Theme.Colors.amberAccent
        ) {
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
        glassCard(
            title: "Goal",
            icon: "target",
            tint: Theme.Colors.success
        ) {
            VStack(spacing: Theme.Spacing.sm) {
                Picker("Goal Type", selection: $goalType) {
                    ForEach(RaceGoalSelection.allCases, id: \.self) { goal in
                        Text(goal.displayName).tag(goal)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityHint("Choose your race goal: finish, target time, or target ranking")

                if goalType == .targetTime {
                    if showsTargetTimeSeconds {
                        // 3-up (h:m:s) for road races ≤ marathon. Compact
                        // steppers with the unit label stacked above so
                        // the row fits inside the card on every phone.
                        HStack(spacing: Theme.Spacing.sm) {
                            compactTimeStepper(title: "Hours", value: $targetTimeHours, range: 0...100, unit: "h")
                            compactTimeStepper(title: "Min", value: $targetTimeMinutes, range: 0...59, unit: "m")
                            compactTimeStepper(title: "Sec", value: $targetTimeSeconds, range: 0...59, unit: "s")
                        }
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(fieldChrome)
                    } else {
                        HStack(spacing: Theme.Spacing.md) {
                            LabeledIntStepper(label: "Hours", value: $targetTimeHours, range: 0...100, unit: "h")
                            LabeledIntStepper(label: "Min", value: $targetTimeMinutes, range: 0...59, unit: "m")
                        }
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(fieldChrome)
                    }
                }

                if goalType == .targetRanking {
                    LabeledIntStepper(label: "Target Position", value: $targetRanking, range: 1...5000, unit: "")
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(fieldChrome)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: goalType)
    }

    // MARK: - Terrain Section

    var terrainSection: some View {
        glassCard(
            title: "Terrain difficulty",
            icon: "mountain.2",
            tint: Theme.Colors.warning
        ) {
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
        glassCard(
            title: "Checkpoints",
            icon: "mappin.circle.fill",
            tint: Theme.Colors.primary,
            footer: "Import a GPX file or add waypoints manually for predicted split times."
        ) {
            VStack(spacing: Theme.Spacing.sm) {
                pillButton(
                    title: "Import GPX course",
                    icon: "doc.badge.arrow.up",
                    tint: Theme.Colors.primary
                ) {
                    showDocumentPicker = true
                }

                if routeRepository != nil {
                    pillButton(
                        title: "Pick from route library",
                        icon: "map.fill",
                        tint: Theme.Colors.primary
                    ) {
                        showRoutePicker = true
                    }
                }

                if checkpoints.isEmpty {
                    Text("No checkpoints added yet")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Theme.Spacing.sm)
                } else {
                    ForEach(sortedCheckpoints) { cp in
                        checkpointRow(cp)
                    }
                }

                pillButton(
                    title: "Add checkpoint",
                    icon: "plus.circle",
                    tint: Theme.Colors.warmCoral
                ) {
                    showAddCheckpoint = true
                }
            }
        }
    }

    private func checkpointRow(_ cp: Checkpoint) -> some View {
        Button {
            editingCheckpoint = cp
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: cp.hasAidStation ? "cross.circle.fill" : "mappin.circle.fill")
                    .font(.title3)
                    .foregroundStyle(cp.hasAidStation ? Theme.Colors.success : Theme.Colors.primary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(cp.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("\(UnitFormatter.formatDistance(cp.distanceFromStartKm, unit: units, decimals: 0))  ·  \(UnitFormatter.formatElevation(cp.elevationM, unit: units))")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.sm)
            .background(fieldChrome)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(cp.name), \(AccessibilityFormatters.distance(cp.distanceFromStartKm, unit: units)), \(AccessibilityFormatters.elevation(cp.elevationM, unit: units))\(cp.hasAidStation ? ", aid station" : "")")
        .accessibilityHint("Double tap to edit this checkpoint")
        .contextMenu {
            Button(role: .destructive) {
                checkpoints.removeAll { $0.id == cp.id }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    /// Glass pill button used as the "add / import / pick" affordance
    /// inside section cards. Border + label tint via `tint`; subtle
    /// glow underneath. Matches the secondary session-action style.
    private func pillButton(
        title: String,
        icon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                Text(title)
                    .font(.subheadline.bold())
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm + 2)
            .background(
                Capsule()
                    .fill(tint.opacity(0.10))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [tint.opacity(0.55), tint.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
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
        case .targetTime:
            // Seconds component is always added; the picker only
            // shows it for road races ≤ marathon (showsTargetTimeSeconds),
            // so for trail/ultra the field stays at 0.
            .targetTime(TimeInterval(
                targetTimeHours * 3600 + targetTimeMinutes * 60 + targetTimeSeconds
            ))
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
        // Auto-detect raceType when the user hasn't explicitly chosen
        // one but the heuristic says road (low elev + sub-marathon).
        // This catches B/C races added via autocomplete that didn't
        // set raceType, so the trail-pipeline B-race-specificity logic
        // can pick them up.
        let resolvedRaceType: RaceType = {
            if raceType != .trail { return raceType }
            if elevationGainM < 100 && distanceKm < 50 && distanceKm > 0 {
                return .road
            }
            return raceType
        }()
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
            terrainDifficulty: terrainDifficulty,
            raceType: resolvedRaceType
        )
        race.courseRoute = courseRoute
        race.savedRouteId = savedRouteId
        race.locationLatitude = locationLatitude
        race.locationLongitude = locationLongitude
        race.locationName = locationName
        race.includesSpecificPrep = includesSpecificPrep
        onSave(race)
        dismiss()
    }
}
