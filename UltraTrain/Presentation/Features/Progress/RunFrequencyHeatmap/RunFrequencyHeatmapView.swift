import SwiftUI
import MapKit

struct RunFrequencyHeatmapView: View {
    @State private var viewModel: RunFrequencyHeatmapViewModel

    init(
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository
    ) {
        _viewModel = State(initialValue: RunFrequencyHeatmapViewModel(
            runRepository: runRepository,
            athleteRepository: athleteRepository
        ))
    }

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading heatmap...")
            } else if let error = viewModel.error {
                errorView(message: error)
            } else if viewModel.heatmapCells.isEmpty {
                emptyStateView
            } else {
                mapContent
            }
        }
        .navigationTitle("Run Heatmap")
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Map Content

    private var mapContent: some View {
        ZStack(alignment: .topLeading) {
            Map {
                ForEach(viewModel.heatmapCells) { cell in
                    MapCircle(
                        center: CLLocationCoordinate2D(
                            latitude: cell.latitude,
                            longitude: cell.longitude
                        ),
                        radius: 25
                    )
                    .foregroundStyle(
                        HeatmapColorHelper.color(for: cell.normalizedIntensity)
                    )
                }
            }
            .mapStyle(.standard(elevation: .flat))

            headerOverlay
        }
    }

    // MARK: - Header Overlay

    private var headerOverlay: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "map.fill")
                .foregroundStyle(Theme.Colors.primary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Run Heatmap")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.Colors.label)
                Text("\(viewModel.totalRunsIncluded) run\(viewModel.totalRunsIncluded == 1 ? "" : "s") included")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
            colorLegend
        }
        .padding(Theme.Spacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
        .padding(Theme.Spacing.sm)
    }

    // MARK: - Color Legend

    private var colorLegend: some View {
        HStack(spacing: 2) {
            Text("Low")
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { intensity in
                RoundedRectangle(cornerRadius: 2)
                    .fill(HeatmapColorHelper.color(for: intensity))
                    .frame(width: 10, height: 10)
            }
            Text("High")
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "map")
                .font(.largeTitle)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            Text("No GPS data available")
                .font(.headline)
                .foregroundStyle(Theme.Colors.label)
            Text("Complete runs with GPS tracking to see your most frequently run areas.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)
        }
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(Theme.Colors.warning)
                .accessibilityHidden(true)
            Text("Failed to load heatmap")
                .font(.headline)
                .foregroundStyle(Theme.Colors.label)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
