import SwiftUI
import CoreLocation

struct RunDetailView: View {
    @Environment(\.unitPreference) var units
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
    @State var exportFileURL: URL?
    @State var showingShareSheet = false
    @State var isExporting = false
    @State private var elevationProfile: [ElevationProfilePoint] = []
    @State var displayRun: CompletedRun?
    @State var showReflectionEdit = false

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

                reflectionSection
                    .padding(.horizontal, Theme.Spacing.md)

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
                .accessibilityLabel("Export")
                .accessibilityHint("Opens export options for this run")
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

    func detailTile(label: String, value: String) -> some View {
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
        .accessibilityLabel("\(label): \(value)")
    }
}
