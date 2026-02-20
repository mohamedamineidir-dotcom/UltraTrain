import SwiftUI
import CoreLocation

struct RunDetailView: View {
    @Environment(\.unitPreference) private var units
    let run: CompletedRun
    let planRepository: any TrainingPlanRepository
    let athleteRepository: any AthleteRepository
    let raceRepository: any RaceRepository
    let runRepository: any RunRepository
    let exportService: any ExportServiceProtocol
    let stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)?
    let stravaConnected: Bool
    let finishEstimateRepository: any FinishEstimateRepository

    @State private var showingExportOptions = false
    @State private var exportFileURL: URL?
    @State private var showingShareSheet = false
    @State private var isExporting = false
    @State private var elevationProfile: [ElevationProfilePoint] = []

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if !run.gpsTrack.isEmpty {
                    RunMapView(
                        coordinates: run.gpsTrack.map {
                            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                        },
                        showsUserLocation: false,
                        height: 250
                    )
                    .padding(.horizontal, Theme.Spacing.md)
                }

                statsGrid
                    .padding(.horizontal, Theme.Spacing.md)

                if !elevationProfile.isEmpty {
                    CompactElevationCard(
                        profile: elevationProfile,
                        elevationGainM: run.elevationGainM,
                        elevationLossM: run.elevationLossM
                    )
                    .padding(.horizontal, Theme.Spacing.md)
                }

                if !run.splits.isEmpty {
                    splitsSection
                        .padding(.horizontal, Theme.Spacing.md)
                }

                if let notes = run.notes, !notes.isEmpty {
                    notesSection(notes)
                        .padding(.horizontal, Theme.Spacing.md)
                }

                analysisLink
                    .padding(.horizontal, Theme.Spacing.md)

                StravaStatusSection(
                    run: run,
                    stravaConnected: stravaConnected,
                    stravaUploadQueueService: stravaUploadQueueService
                )
                .padding(.horizontal, Theme.Spacing.md)
            }
            .padding(.vertical, Theme.Spacing.md)
        }
        .navigationTitle(run.date.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingExportOptions = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(isExporting)
            }
        }
        .confirmationDialog("Export Run", isPresented: $showingExportOptions) {
            Button("Export as GPX") {
                Task { await exportGPX() }
            }
            Button("Export Track Points (CSV)") {
                Task { await exportTrackCSV() }
            }
            Button("Export as PDF Report") {
                Task { await exportPDF() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .task {
            if run.gpsTrack.count >= 2 {
                elevationProfile = ElevationCalculator.elevationProfile(from: run.gpsTrack)
            }
        }
    }

    // MARK: - Export

    private func exportGPX() async {
        isExporting = true
        do {
            exportFileURL = try await exportService.exportRunAsGPX(run)
            showingShareSheet = true
        } catch {
            // Error handled silently — file just won't share
        }
        isExporting = false
    }

    private func exportTrackCSV() async {
        isExporting = true
        do {
            exportFileURL = try await exportService.exportRunTrackAsCSV(run)
            showingShareSheet = true
        } catch {
            // Error handled silently
        }
        isExporting = false
    }

    private func exportPDF() async {
        isExporting = true
        do {
            let athlete = try await athleteRepository.getAthlete()
            let metrics = AdvancedRunMetricsCalculator.calculate(
                run: run,
                athleteWeightKg: athlete?.weightKg,
                maxHeartRate: athlete?.maxHeartRate
            )
            let recentRuns = try await runRepository.getRecentRuns(limit: 20)
            let otherRuns = recentRuns.filter { $0.id != run.id }
            let comparison = otherRuns.isEmpty ? nil : HistoricalComparisonCalculator.compare(run: run, recentRuns: otherRuns)
            let nutrition = NutritionAnalysisCalculator.analyze(run: run)

            exportFileURL = try await exportService.exportRunAsPDF(
                run,
                metrics: metrics,
                comparison: comparison,
                nutritionAnalysis: nutrition
            )
            showingShareSheet = true
        } catch {
            // Error handled silently
        }
        isExporting = false
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: Theme.Spacing.md
        ) {
            detailTile(label: "Distance", value: UnitFormatter.formatDistance(run.distanceKm, unit: units, decimals: 2))
            if run.pausedDuration > 0 {
                detailTile(label: "Moving Time", value: RunStatisticsCalculator.formatDuration(run.duration))
                detailTile(label: "Total Time", value: RunStatisticsCalculator.formatDuration(run.totalDuration))
            } else {
                detailTile(label: "Duration", value: RunStatisticsCalculator.formatDuration(run.duration))
            }
            detailTile(label: "Avg Pace", value: RunStatisticsCalculator.formatPace(run.averagePaceSecondsPerKm, unit: units) + " " + UnitFormatter.paceLabel(units))
            detailTile(label: "Elevation", value: "+" + UnitFormatter.formatElevation(run.elevationGainM, unit: units) + " / -" + UnitFormatter.formatElevation(run.elevationLossM, unit: units))
            if let avgHR = run.averageHeartRate {
                detailTile(label: "Avg HR", value: "\(avgHR) bpm")
            }
            if let maxHR = run.maxHeartRate {
                detailTile(label: "Max HR", value: "\(maxHR) bpm")
            }
        }
    }

    // MARK: - Splits

    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Splits")
                .font(.headline)

            ForEach(run.splits) { split in
                HStack {
                    Text("\(UnitFormatter.distanceLabel(units).uppercased()) \(split.kilometerNumber)")
                        .font(.subheadline.bold())
                        .frame(width: 50, alignment: .leading)

                    Text(RunStatisticsCalculator.formatPace(split.duration, unit: units))
                        .font(.subheadline.monospacedDigit())

                    Spacer()

                    if split.elevationChangeM != 0 {
                        Text(String(format: "%+.0f %@", UnitFormatter.elevationValue(split.elevationChangeM, unit: units), UnitFormatter.elevationShortLabel(units)))
                            .font(.caption)
                            .foregroundStyle(
                                split.elevationChangeM > 0
                                    ? Theme.Colors.danger
                                    : Theme.Colors.success
                            )
                    }

                    if let hr = split.averageHeartRate {
                        Text("\(hr) bpm")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)

                if split.id != run.splits.last?.id {
                    Divider()
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    // MARK: - Notes

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Notes")
                .font(.headline)
            Text(notes)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    // MARK: - Analysis

    private var analysisLink: some View {
        NavigationLink {
            RunAnalysisView(
                run: run,
                planRepository: planRepository,
                athleteRepository: athleteRepository,
                raceRepository: raceRepository,
                runRepository: runRepository,
                finishEstimateRepository: finishEstimateRepository
            )
        } label: {
            Label("View Analysis", systemImage: "chart.xyaxis.line")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
        }
        .buttonStyle(.borderedProminent)
    }

    // MARK: - Helper

    private func detailTile(label: String, value: String) -> some View {
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
    }
}
