import SwiftUI
import MapKit

struct ImportCourseView: View {
    let fileURL: URL
    let onApply: (CourseImportResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.unitPreference) private var units
    @State private var result: CourseImportResult?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Parsing GPX course...")
                } else if let error {
                    errorView(error)
                } else if let result {
                    previewContent(result)
                }
            }
            .navigationTitle("Import Course")
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

    private func previewContent(_ result: CourseImportResult) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if result.trackPoints.count >= 2 {
                    routeMap(result.trackPoints)
                }
                statsSection(result)
                if !result.checkpoints.isEmpty {
                    checkpointsSection(result.checkpoints)
                }
                applyButton
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

    private func statsSection(_ result: CourseImportResult) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            if let name = result.name {
                Text(name)
                    .font(.headline)
            }

            Grid(
                alignment: .leading,
                horizontalSpacing: Theme.Spacing.lg,
                verticalSpacing: Theme.Spacing.md
            ) {
                GridRow {
                    statItem(
                        label: "Distance",
                        value: UnitFormatter.formatDistance(
                            result.distanceKm, unit: units, decimals: 1
                        )
                    )
                    statItem(
                        label: "D+ (gain)",
                        value: "+" + UnitFormatter.formatElevation(
                            result.elevationGainM, unit: units
                        )
                    )
                }
                GridRow {
                    statItem(
                        label: "D- (loss)",
                        value: "-" + UnitFormatter.formatElevation(
                            result.elevationLossM, unit: units
                        )
                    )
                    statItem(
                        label: "Track Points",
                        value: "\(result.trackPoints.count)"
                    )
                }
                GridRow {
                    statItem(
                        label: "Checkpoints",
                        value: "\(result.checkpoints.count)"
                    )
                    Spacer()
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Checkpoints

    private func checkpointsSection(_ checkpoints: [Checkpoint]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Auto-Generated Checkpoints")
                .font(.headline)

            ForEach(checkpoints) { cp in
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Theme.Colors.primary)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cp.name)
                        Text(
                            "\(UnitFormatter.formatDistance(cp.distanceFromStartKm, unit: units, decimals: 0))  ·  \(UnitFormatter.formatElevation(cp.elevationM, unit: units))"
                        )
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                    Spacer()
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    // MARK: - Apply

    private var applyButton: some View {
        Button {
            if let result {
                onApply(result)
                dismiss()
            }
        } label: {
            Label("Apply to Race", systemImage: "checkmark.circle")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
        }
        .buttonStyle(.borderedProminent)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(Theme.Colors.danger)
                .accessibilityHidden(true)
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

    // MARK: - Parse

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
            let parseResult = try parser.parse(data)
            result = try CourseImportUseCase.importCourse(from: parseResult)
        } catch let domainError as DomainError {
            error = domainError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }
}
