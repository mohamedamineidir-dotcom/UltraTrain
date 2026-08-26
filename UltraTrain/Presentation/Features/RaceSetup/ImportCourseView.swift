import SwiftUI
import MapKit

struct ImportCourseView: View {
    let fileURL: URL
    let onApply: (CourseImportResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.unitPreference) private var units
    @Environment(\.colorScheme) private var colorScheme
    @State private var result: CourseImportResult?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
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
            .background(screenBackground.ignoresSafeArea())
            .task { await parseFile() }
        }
    }

    // MARK: - Background
    // A subtle indigo fade from the top, same recipe used behind the
    // finish-time evolution screen — lets the premium indigo cards
    // below stand out with real contrast instead of blending into a
    // near-black, generic-looking backdrop.

    private var screenBackground: some View {
        LinearGradient(
            colors: [
                Theme.Colors.premiumBgTop.opacity(0.35),
                Theme.Colors.background
            ],
            startPoint: .top,
            endPoint: .center
        )
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .tint(Theme.Colors.primary)
                .scaleEffect(1.2)
            Text("Parsing GPX course...")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Preview

    private func previewContent(_ result: CourseImportResult) -> some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.lg) {
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

    // MARK: - Route Map

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
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.Gradients.glowBorder(color: Theme.Colors.primary), lineWidth: 1.5)
        )
        .shadow(color: Theme.Colors.primary.opacity(0.20), radius: 18, y: 8)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.10), radius: 10, y: 4)
    }

    // MARK: - Stats

    private func statsSection(_ result: CourseImportResult) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            if let name = result.name {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "signpost.right.and.left.fill")
                        .foregroundStyle(Theme.Colors.primary)
                        .accessibilityHidden(true)
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.label)
                        .lineLimit(2)
                }
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: Theme.Spacing.md
            ) {
                statTile(
                    icon: "figure.run",
                    label: "Distance",
                    value: UnitFormatter.formatDistance(result.distanceKm, unit: units, decimals: 1),
                    tint: Theme.Colors.primary
                )
                statTile(
                    icon: "arrow.up.right",
                    label: "D+ (gain)",
                    value: "+" + UnitFormatter.formatElevation(result.elevationGainM, unit: units),
                    tint: Theme.Colors.danger
                )
                statTile(
                    icon: "arrow.down.right",
                    label: "D- (loss)",
                    value: "-" + UnitFormatter.formatElevation(result.elevationLossM, unit: units),
                    tint: Theme.Colors.success
                )
                statTile(
                    icon: "point.3.connected.trianglepath.dotted",
                    label: "Track Points",
                    value: "\(result.trackPoints.count)",
                    tint: Theme.Colors.info
                )
                statTile(
                    icon: "mappin.circle.fill",
                    label: "Checkpoints",
                    value: "\(result.checkpoints.count)",
                    tint: Theme.Colors.primary
                )
            }
        }
        .premiumChartCardStyle(tint: Theme.Colors.primary)
    }

    private func statTile(icon: String, label: LocalizedStringKey, value: String, tint: Color) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(tint.opacity(colorScheme == .dark ? 0.18 : 0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(value)
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Theme.Colors.label)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Checkpoints

    private func checkpointsSection(_ checkpoints: [Checkpoint]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(Theme.Colors.primary)
                    .accessibilityHidden(true)
                Text("Auto-Generated Checkpoints")
                    .font(.headline)
            }

            VStack(spacing: 0) {
                ForEach(Array(checkpoints.enumerated()), id: \.element.id) { index, cp in
                    checkpointRow(cp)
                    if index < checkpoints.count - 1 {
                        Divider().opacity(0.15)
                    }
                }
            }
        }
        .premiumChartCardStyle(tint: Theme.Colors.primary)
    }

    private func checkpointRow(_ cp: Checkpoint) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(
                        (cp.hasAidStation ? Theme.Colors.danger : Theme.Colors.primary)
                            .opacity(colorScheme == .dark ? 0.18 : 0.12)
                    )
                    .frame(width: 30, height: 30)
                Image(systemName: cp.hasAidStation ? "cross.circle.fill" : "mappin.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(cp.hasAidStation ? Theme.Colors.danger : Theme.Colors.primary)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(cp.name)
                    .font(.subheadline.weight(.semibold))
                Text(
                    "\(UnitFormatter.formatDistance(cp.distanceFromStartKm, unit: units, decimals: 0))  ·  \(UnitFormatter.formatElevation(cp.elevationM, unit: units))"
                )
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Apply

    private var applyButton: some View {
        Button {
            if let result {
                onApply(result)
                dismiss()
            }
        } label: {
            Label("Apply to Race", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm + 2)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Theme.Colors.primary.opacity(0.35), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
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
        .padding(.vertical, Theme.Spacing.md)
        .premiumChartCardStyle(tint: Theme.Colors.danger)
        .padding(Theme.Spacing.md)
    }

    // MARK: - Parse

    private func parseFile() async {
        defer { isLoading = false }

        guard fileURL.startAccessingSecurityScopedResource() else {
            error = String(
                localized: "import.course.error.accessDenied",
                defaultValue: "Cannot access the selected file."
            )
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
