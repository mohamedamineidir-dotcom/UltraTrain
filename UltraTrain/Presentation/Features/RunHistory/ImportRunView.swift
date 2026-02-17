import SwiftUI
import MapKit

struct ImportRunView: View {
    let fileURL: URL
    let athleteId: UUID
    let runImportUseCase: any RunImportUseCase

    @Environment(\.dismiss) private var dismiss
    @State private var parseResult: GPXParseResult?
    @State private var isLoading = true
    @State private var isImporting = false
    @State private var error: String?
    @State private var importedRun: CompletedRun?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Parsing GPX file...")
                } else if let error {
                    errorView(error)
                } else if let result = parseResult {
                    previewContent(result)
                }
            }
            .navigationTitle("Import Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { await parseFile() }
        }
    }

    // MARK: - Preview

    private func previewContent(_ result: GPXParseResult) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if result.trackPoints.count >= 2 {
                    routeMap(result.trackPoints)
                }
                statsSection(result)
                importButton
            }
            .padding(Theme.Spacing.md)
        }
    }

    private func routeMap(_ points: [TrackPoint]) -> some View {
        let coords = points.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        return RunMapView(
            coordinates: coords,
            showsUserLocation: false,
            startCoordinate: coords.first,
            endCoordinate: coords.last,
            height: 250
        )
    }

    private func statsSection(_ result: GPXParseResult) -> some View {
        let points = result.trackPoints
        let distance = RunStatisticsCalculator.totalDistanceKm(points)
        let elevation = RunStatisticsCalculator.elevationChanges(points)
        let duration = (points.last?.timestamp ?? .now)
            .timeIntervalSince(points.first?.timestamp ?? .now)
        let pace = RunStatisticsCalculator.averagePace(
            distanceKm: distance, duration: duration
        )
        let heartRates = points.compactMap(\.heartRate)

        return VStack(spacing: Theme.Spacing.md) {
            if let name = result.name {
                Text(name)
                    .font(.headline)
            }
            if let date = result.date {
                Text(date, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Grid(
                alignment: .leading,
                horizontalSpacing: Theme.Spacing.lg,
                verticalSpacing: Theme.Spacing.md
            ) {
                GridRow {
                    statItem(
                        label: "Distance",
                        value: String(format: "%.2f km", distance)
                    )
                    statItem(
                        label: "Duration",
                        value: RunStatisticsCalculator.formatDuration(duration)
                    )
                }
                GridRow {
                    statItem(
                        label: "Avg Pace",
                        value: "\(RunStatisticsCalculator.formatPace(pace)) /km"
                    )
                    statItem(
                        label: "Elevation",
                        value: String(format: "+%.0fm / -%.0fm", elevation.gainM, elevation.lossM)
                    )
                }
                if !heartRates.isEmpty {
                    GridRow {
                        statItem(
                            label: "Avg HR",
                            value: "\(heartRates.reduce(0, +) / heartRates.count) bpm"
                        )
                        statItem(
                            label: "Max HR",
                            value: "\(heartRates.max() ?? 0) bpm"
                        )
                    }
                }
                GridRow {
                    statItem(
                        label: "Track Points",
                        value: "\(points.count)"
                    )
                    statItem(
                        label: "Splits",
                        value: "\(RunStatisticsCalculator.buildSplits(from: points).count)"
                    )
                }
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.secondaryBackground)
            )
        }
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
        }
    }

    private var importButton: some View {
        Group {
            if let run = importedRun {
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.Colors.success)
                    Text("Run imported successfully!")
                        .font(.headline)
                    Text(String(format: "%.2f km — %@",
                                run.distanceKm,
                                RunStatisticsCalculator.formatDuration(run.duration)))
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    Button("Done") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, Theme.Spacing.sm)
                }
            } else {
                Button {
                    Task { await importRun() }
                } label: {
                    if isImporting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.sm)
                    } else {
                        Label("Import Run", systemImage: "square.and.arrow.down")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.sm)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isImporting)
            }
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(Theme.Colors.danger)
            Text("Failed to parse GPX file")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
            Button("Dismiss") { dismiss() }
                .buttonStyle(.bordered)
        }
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Actions

    private func parseFile() async {
        defer { isLoading = false }

        guard fileURL.startAccessingSecurityScopedResource() else {
            error = "Cannot access the selected file."
            return
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: fileURL)
            let parser = GPXParser()
            parseResult = try parser.parse(data)
        } catch let domainError as DomainError {
            error = domainError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func importRun() async {
        isImporting = true
        defer { isImporting = false }

        guard fileURL.startAccessingSecurityScopedResource() else {
            error = "Cannot access the selected file."
            return
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: fileURL)
            importedRun = try await runImportUseCase.importFromGPX(
                data: data,
                athleteId: athleteId
            )
        } catch let domainError as DomainError {
            error = domainError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }
}
