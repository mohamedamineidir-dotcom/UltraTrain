import SwiftUI

struct RunHistoryFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.unitPreference) private var units
    @Binding var filter: RunHistoryAdvancedFilter
    let availableSessionTypes: [SessionType]
    let availableGear: [GearItem]

    @State private var draft = RunHistoryAdvancedFilter()

    // Display-unit values for distance/elevation
    @State private var minDistanceDisplay: Double?
    @State private var maxDistanceDisplay: Double?
    @State private var minElevationDisplay: Double?
    @State private var maxElevationDisplay: Double?

    var body: some View {
        NavigationStack {
            Form {
                distanceSection
                elevationSection
                if !availableSessionTypes.isEmpty {
                    sessionTypeSection
                }
                if !availableGear.isEmpty {
                    gearSection
                }
                importSourceSection
                clearSection
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyDisplayValues()
                        filter = draft
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                draft = filter
                loadDisplayValues()
            }
        }
    }

    // MARK: - Distance

    private var distanceSection: some View {
        RangeFilterSection(
            title: "Distance",
            unitLabel: UnitFormatter.distanceLabel(units),
            minValue: $minDistanceDisplay,
            maxValue: $maxDistanceDisplay
        )
    }

    // MARK: - Elevation

    private var elevationSection: some View {
        RangeFilterSection(
            title: "Elevation Gain",
            unitLabel: UnitFormatter.elevationShortLabel(units),
            minValue: $minElevationDisplay,
            maxValue: $maxElevationDisplay
        )
    }

    // MARK: - Session Type

    private var sessionTypeSection: some View {
        Section("Session Type") {
            ForEach(availableSessionTypes, id: \.self) { type in
                Button {
                    toggleSessionType(type)
                } label: {
                    HStack {
                        Text(type.displayName)
                            .foregroundStyle(Theme.Colors.label)
                        Spacer()
                        if draft.sessionTypes.contains(type) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.Colors.primary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Gear

    private var gearSection: some View {
        Section("Gear") {
            ForEach(availableGear) { gear in
                Button {
                    toggleGear(gear.id)
                } label: {
                    HStack {
                        Text(gear.name)
                            .foregroundStyle(Theme.Colors.label)
                        if !gear.brand.isEmpty {
                            Text(gear.brand)
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                        }
                        Spacer()
                        if draft.gearIds.contains(gear.id) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.Colors.primary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Import Source

    private var importSourceSection: some View {
        Section("Import Source") {
            ForEach(ImportSourceFilter.allCases, id: \.self) { source in
                Button {
                    toggleImportSource(source)
                } label: {
                    HStack {
                        Text(source.displayName)
                            .foregroundStyle(Theme.Colors.label)
                        Spacer()
                        if draft.importSources.contains(source) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.Colors.primary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Clear

    private var clearSection: some View {
        Section {
            Button("Clear All Filters", role: .destructive) {
                draft.clearAll()
                minDistanceDisplay = nil
                maxDistanceDisplay = nil
                minElevationDisplay = nil
                maxElevationDisplay = nil
            }
            .disabled(!draft.isActive && minDistanceDisplay == nil && maxDistanceDisplay == nil
                      && minElevationDisplay == nil && maxElevationDisplay == nil)
        }
    }

    // MARK: - Helpers

    private func toggleSessionType(_ type: SessionType) {
        if draft.sessionTypes.contains(type) {
            draft.sessionTypes.remove(type)
        } else {
            draft.sessionTypes.insert(type)
        }
    }

    private func toggleGear(_ id: UUID) {
        if draft.gearIds.contains(id) {
            draft.gearIds.remove(id)
        } else {
            draft.gearIds.insert(id)
        }
    }

    private func toggleImportSource(_ source: ImportSourceFilter) {
        if draft.importSources.contains(source) {
            draft.importSources.remove(source)
        } else {
            draft.importSources.insert(source)
        }
    }

    private func loadDisplayValues() {
        minDistanceDisplay = draft.minDistanceKm.map { UnitFormatter.distanceValue($0, unit: units) }
        maxDistanceDisplay = draft.maxDistanceKm.map { UnitFormatter.distanceValue($0, unit: units) }
        minElevationDisplay = draft.minElevationM.map { UnitFormatter.elevationValue($0, unit: units) }
        maxElevationDisplay = draft.maxElevationM.map { UnitFormatter.elevationValue($0, unit: units) }
    }

    private func applyDisplayValues() {
        draft.minDistanceKm = minDistanceDisplay.map { UnitFormatter.distanceToKm($0, unit: units) }
        draft.maxDistanceKm = maxDistanceDisplay.map { UnitFormatter.distanceToKm($0, unit: units) }
        draft.minElevationM = minElevationDisplay.map { UnitFormatter.elevationToMeters($0, unit: units) }
        draft.maxElevationM = maxElevationDisplay.map { UnitFormatter.elevationToMeters($0, unit: units) }
    }
}
