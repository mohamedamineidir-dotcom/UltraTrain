import SwiftUI
import CoreLocation

struct RunDetailView: View {
    let run: CompletedRun
    let planRepository: any TrainingPlanRepository
    let athleteRepository: any AthleteRepository
    let raceRepository: any RaceRepository
    let exportService: any ExportServiceProtocol
    let stravaUploadService: (any StravaUploadServiceProtocol)?
    let stravaConnected: Bool

    @State private var showingExportOptions = false
    @State private var exportFileURL: URL?
    @State private var showingShareSheet = false
    @State private var isExporting = false
    @State private var stravaUploadStatus: StravaUploadStatus = .idle

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

                if stravaConnected && !run.gpsTrack.isEmpty {
                    stravaUploadSection
                        .padding(.horizontal, Theme.Spacing.md)
                }
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
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportFileURL {
                ShareSheet(activityItems: [url])
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

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: Theme.Spacing.md
        ) {
            detailTile(label: "Distance", value: String(format: "%.2f km", run.distanceKm))
            if run.pausedDuration > 0 {
                detailTile(label: "Moving Time", value: RunStatisticsCalculator.formatDuration(run.duration))
                detailTile(label: "Total Time", value: RunStatisticsCalculator.formatDuration(run.totalDuration))
            } else {
                detailTile(label: "Duration", value: RunStatisticsCalculator.formatDuration(run.duration))
            }
            detailTile(label: "Avg Pace", value: run.paceFormatted)
            detailTile(label: "Elevation", value: String(format: "+%.0f / -%.0f m", run.elevationGainM, run.elevationLossM))
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
                    Text("KM \(split.kilometerNumber)")
                        .font(.subheadline.bold())
                        .frame(width: 50, alignment: .leading)

                    Text(RunStatisticsCalculator.formatPace(split.duration))
                        .font(.subheadline.monospacedDigit())

                    Spacer()

                    if split.elevationChangeM != 0 {
                        Text(String(format: "%+.0f m", split.elevationChangeM))
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
                raceRepository: raceRepository
            )
        } label: {
            Label("View Analysis", systemImage: "chart.xyaxis.line")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
        }
        .buttonStyle(.borderedProminent)
    }

    // MARK: - Strava Upload

    @ViewBuilder
    private var stravaUploadSection: some View {
        switch stravaUploadStatus {
        case .idle:
            Button {
                uploadToStrava()
            } label: {
                Label("Upload to Strava", systemImage: "arrow.up.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
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
        case .failed(let reason):
            VStack(spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.Colors.warning)
                    Text("Upload failed: \(reason)")
                        .font(.caption)
                }
                Button("Retry") { uploadToStrava() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.warning.opacity(0.1))
            )
        }
    }

    private func uploadToStrava() {
        guard let service = stravaUploadService else { return }
        stravaUploadStatus = .uploading
        Task {
            do {
                let activityId = try await service.uploadRun(run)
                stravaUploadStatus = .success(activityId: activityId)
            } catch {
                stravaUploadStatus = .failed(reason: error.localizedDescription)
            }
        }
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
