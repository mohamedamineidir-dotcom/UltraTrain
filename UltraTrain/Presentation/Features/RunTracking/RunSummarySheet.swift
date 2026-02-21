import SwiftUI

struct RunSummarySheet: View {
    @Environment(\.unitPreference) private var units
    @Bindable var viewModel: ActiveRunViewModel
    let exportService: any ExportServiceProtocol
    let onDismiss: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var headerIconSize: CGFloat = 48
    @State private var notes = ""
    @State private var rpe: Int?
    @State private var perceivedFeeling: PerceivedFeeling?
    @State private var terrainType: TerrainType?
    @State private var didSave = false
    @State private var exportFileURL: URL?
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    headerSection
                    statsSection
                    if !viewModel.routeCoordinates.isEmpty {
                        RunMapView(
                            coordinates: viewModel.routeCoordinates,
                            showsUserLocation: false,
                            startCoordinate: viewModel.routeCoordinates.first,
                            endCoordinate: viewModel.routeCoordinates.last,
                            height: 180
                        )
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                    if !viewModel.nutritionHandler.nutritionIntakeLog.isEmpty {
                        NutritionIntakeSummaryView(summary: viewModel.nutritionHandler.nutritionSummary)
                    }
                    if didSave {
                        stravaUploadBanner
                        shareButton
                    } else {
                        notesSection
                    }
                    linkedSessionBanner
                    autoMatchBanner
                }
                .padding(.vertical, Theme.Spacing.md)
            }
            .navigationTitle("Run Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if didSave {
                        Button("Done") { onDismiss() }
                    } else {
                        Button("Discard") {
                            viewModel.discardRun()
                            onDismiss()
                        }
                        .foregroundStyle(Theme.Colors.danger)
                        .accessibilityIdentifier("runTracking.discardButton")
                    }
                }
                if !didSave {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                await viewModel.saveRun(
                                    notes: notes.isEmpty ? nil : notes,
                                    rpe: rpe,
                                    feeling: perceivedFeeling,
                                    terrain: terrainType
                                )
                                didSave = true
                            }
                        }
                        .bold()
                        .disabled(viewModel.isSaving)
                        .accessibilityIdentifier("runTracking.saveButton")
                    }
                }
            }
            .interactiveDismissDisabled()
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: headerIconSize))
                .foregroundStyle(Theme.Colors.success)
                .accessibilityHidden(true)
            Text(didSave ? "Run Saved!" : "Great Run!")
                .font(.title2.bold())
            Text(viewModel.formattedTime)
                .font(.title3.monospacedDigit())
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.top, Theme.Spacing.md)
    }

    private var statsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
            summaryTile(label: "Distance", value: "\(viewModel.formattedDistance) \(UnitFormatter.distanceLabel(units))")
            if viewModel.pausedDuration > 0 {
                summaryTile(label: "Moving Time", value: viewModel.formattedTime)
                summaryTile(label: "Total Time", value: viewModel.formattedTotalTime)
            }
            summaryTile(label: "Avg Pace", value: "\(viewModel.formattedPace) \(UnitFormatter.paceLabel(units))")
            summaryTile(label: "Elevation", value: viewModel.formattedElevation)
            summaryTile(
                label: "Heart Rate",
                value: viewModel.currentHeartRate.map { "\($0) bpm" } ?? "N/A"
            )
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // RPE
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Rate of Perceived Exertion")
                    .font(.subheadline.bold())
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(1...10, id: \.self) { value in
                        Button {
                            rpe = rpe == value ? nil : value
                        } label: {
                            Text("\(value)")
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                        .fill(
                                            rpe == value
                                                ? rpeColor(value)
                                                : Theme.Colors.secondaryBackground
                                        )
                                )
                                .foregroundStyle(
                                    rpe == value
                                        ? .white
                                        : Theme.Colors.label
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Feeling
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("How Did It Feel?")
                    .font(.subheadline.bold())
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(PerceivedFeeling.allCases, id: \.self) { feeling in
                        Button {
                            perceivedFeeling = perceivedFeeling == feeling
                                ? nil
                                : feeling
                        } label: {
                            VStack(spacing: 2) {
                                Text(feelingEmoji(feeling))
                                    .font(.title3)
                                Text(feelingLabel(feeling))
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                    .fill(
                                        perceivedFeeling == feeling
                                            ? Theme.Colors.primary.opacity(0.15)
                                            : Theme.Colors.secondaryBackground
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                    .stroke(
                                        perceivedFeeling == feeling
                                            ? Theme.Colors.primary
                                            : .clear,
                                        lineWidth: 1.5
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Terrain
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Terrain")
                    .font(.subheadline.bold())
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(TerrainType.allCases, id: \.self) { terrain in
                        Button {
                            terrainType = terrainType == terrain
                                ? nil
                                : terrain
                        } label: {
                            Text(terrainLabel(terrain))
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                        .fill(
                                            terrainType == terrain
                                                ? Theme.Colors.primary.opacity(0.15)
                                                : Theme.Colors.secondaryBackground
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                        .stroke(
                                            terrainType == terrain
                                                ? Theme.Colors.primary
                                                : .clear,
                                            lineWidth: 1.5
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Notes
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Notes")
                    .font(.subheadline.bold())
                TextField("How did it feel?", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private var shareButton: some View {
        Button {
            Task { await exportAndShare() }
        } label: {
            Label("Share as GPX", systemImage: "square.and.arrow.up")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
        }
        .buttonStyle(.bordered)
        .padding(.horizontal, Theme.Spacing.md)
    }

    @ViewBuilder
    private var linkedSessionBanner: some View {
        if let session = viewModel.linkedSession {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "link.circle.fill")
                    .foregroundStyle(Theme.Colors.primary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Linked Session")
                        .font(.caption.bold())
                    Text("\(session.type.rawValue.capitalized) — \(UnitFormatter.formatDistance(session.plannedDistanceKm, unit: units))")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundStyle(Theme.Colors.success)
                    .accessibilityHidden(true)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.primary.opacity(0.08))
            )
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    @ViewBuilder
    private var autoMatchBanner: some View {
        if didSave, let match = viewModel.autoMatchedSession, viewModel.linkedSession == nil {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.Colors.primary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Linked to Session")
                        .font(.caption.bold())
                    Text("\(match.session.type.rawValue.capitalized) — \(UnitFormatter.formatDistance(match.session.plannedDistanceKm, unit: units))")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundStyle(Theme.Colors.success)
                    .accessibilityHidden(true)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.primary.opacity(0.08))
            )
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    // MARK: - Strava Upload

    @ViewBuilder
    private var stravaUploadBanner: some View {
        switch viewModel.connectivityHandler.stravaUploadStatus {
        case .idle:
            EmptyView()
        case .uploading, .processing:
            HStack(spacing: Theme.Spacing.sm) {
                ProgressView()
                Text("Uploading to Strava...")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Color.orange.opacity(0.1))
            )
            .padding(.horizontal, Theme.Spacing.md)
        case .success:
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Uploaded to Strava")
                    .font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Color.green.opacity(0.1))
            )
            .padding(.horizontal, Theme.Spacing.md)
        case .failed(let reason):
            VStack(spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.Colors.warning)
                    Text("Strava upload failed")
                        .font(.subheadline.bold())
                }
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Button("Retry") {
                    Task { await viewModel.uploadToStrava() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.warning.opacity(0.1))
            )
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    // MARK: - Helpers

    private func summaryTile(label: String, value: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(value)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
    }

    private func exportAndShare() async {
        guard let run = viewModel.lastSavedRun else { return }
        do {
            exportFileURL = try await exportService.exportRunAsGPX(run)
            showingShareSheet = true
        } catch {
            // Export failed silently
        }
    }

    private func rpeColor(_ value: Int) -> Color {
        switch value {
        case 1...3: return Theme.Colors.success
        case 4...6: return Theme.Colors.warning
        case 7...8: return .orange
        default: return Theme.Colors.danger
        }
    }

    private func feelingEmoji(_ feeling: PerceivedFeeling) -> String {
        switch feeling {
        case .great: "😀"
        case .good: "🙂"
        case .ok: "😐"
        case .tough: "😤"
        case .terrible: "😫"
        }
    }

    private func feelingLabel(_ feeling: PerceivedFeeling) -> String {
        switch feeling {
        case .great: "Great"
        case .good: "Good"
        case .ok: "OK"
        case .tough: "Tough"
        case .terrible: "Terrible"
        }
    }

    private func terrainLabel(_ terrain: TerrainType) -> String {
        switch terrain {
        case .road: "Road"
        case .trail: "Trail"
        case .mountain: "Mountain"
        case .mixed: "Mixed"
        }
    }
}
