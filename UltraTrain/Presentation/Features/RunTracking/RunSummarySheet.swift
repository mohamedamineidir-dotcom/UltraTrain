import SwiftUI

struct RunSummarySheet: View {
    @Environment(\.unitPreference) var units
    @Bindable var viewModel: ActiveRunViewModel
    let exportService: any ExportServiceProtocol
    let onDismiss: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var headerIconSize: CGFloat = 48
    @State var notes = ""
    @State var rpe: Int?
    @State var perceivedFeeling: PerceivedFeeling?
    @State var terrainType: TerrainType?
    @State var didSave = false
    @State private var exportFileURL: URL?
    @State private var showingShareSheet = false
    @State private var showPostSaveLoading = false

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
                                showPostSaveLoading = true
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
            .fullScreenCover(isPresented: $showPostSaveLoading) {
                PostSaveLoadingView { showPostSaveLoading = false }
            }
        }
    }

    // MARK: - Header & Stats

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.Colors.success.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 32
                        )
                    )
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: headerIconSize))
                    .foregroundStyle(Theme.Colors.success)
            }
            .shadow(color: Theme.Colors.success.opacity(0.3), radius: 8)
            .accessibilityHidden(true)

            Text(didSave ? "Run Saved!" : "Great Run!")
                .font(.title2.bold())
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.label, Theme.Colors.label.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text(viewModel.formattedTime)
                .font(.title3.monospacedDigit())
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityLabel("Duration, \(viewModel.formattedTime)")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .futuristicGlassStyle()
        .padding(.horizontal, Theme.Spacing.md)
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

    func summaryTile(label: String, value: String) -> some View {
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
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(Color.white.opacity(0.08))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
    }

    // MARK: - Helpers

    func exportAndShare() async {
        guard let run = viewModel.lastSavedRun else { return }
        do {
            exportFileURL = try await exportService.exportRunAsGPX(run)
            showingShareSheet = true
        } catch {
            // Export failed silently
        }
    }

    func rpeColor(_ value: Int) -> Color {
        switch value {
        case 1...3: return Theme.Colors.success
        case 4...6: return Theme.Colors.warning
        case 7...8: return .orange
        default: return Theme.Colors.danger
        }
    }

    func feelingEmoji(_ feeling: PerceivedFeeling) -> String {
        switch feeling {
        case .great: "😀"
        case .good: "🙂"
        case .ok: "😐"
        case .tough: "😤"
        case .terrible: "😫"
        }
    }

    func feelingLabel(_ feeling: PerceivedFeeling) -> String {
        switch feeling {
        case .great: "Great"
        case .good: "Good"
        case .ok: "OK"
        case .tough: "Tough"
        case .terrible: "Terrible"
        }
    }

    func terrainLabel(_ terrain: TerrainType) -> String {
        switch terrain {
        case .road: "Road"
        case .trail: "Trail"
        case .mixed: "Mixed"
        }
    }
}
