import SwiftUI
import MapKit

struct RunAnalysisView: View {
    @State private var viewModel: RunAnalysisViewModel

    init(
        run: CompletedRun,
        planRepository: any TrainingPlanRepository,
        athleteRepository: any AthleteRepository
    ) {
        _viewModel = State(initialValue: RunAnalysisViewModel(
            run: run,
            planRepository: planRepository,
            athleteRepository: athleteRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if viewModel.isLoading {
                    ProgressView("Analyzing...")
                        .padding(.top, Theme.Spacing.xl)
                } else {
                    if viewModel.hasRouteData {
                        routeMapSection
                    }

                    if !viewModel.elevationProfile.isEmpty {
                        ElevationProfileChart(dataPoints: viewModel.elevationProfile)
                    }

                    if !viewModel.run.splits.isEmpty {
                        PaceSplitsChart(splits: viewModel.run.splits)
                    }

                    if viewModel.hasHeartRateData {
                        HeartRateZoneChart(distribution: viewModel.zoneDistribution)
                    }

                    if let comparison = viewModel.planComparison {
                        PlanComparisonCard(comparison: comparison)
                    }
                }
            }
            .padding(Theme.Spacing.md)
        }
        .navigationTitle("Run Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(isPresented: $viewModel.showFullScreenMap) {
            FullScreenMapView(
                segments: viewModel.routeSegments,
                startCoordinate: startCLCoordinate,
                endCoordinate: endCLCoordinate
            )
        }
    }

    // MARK: - Route Map

    private var routeMapSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Route")
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.showFullScreenMap = true
                } label: {
                    Label("Expand", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.primary)
                }
            }

            RouteMapView(
                segments: viewModel.routeSegments,
                startCoordinate: startCLCoordinate,
                endCoordinate: endCLCoordinate
            )
        }
        .cardStyle()
    }

    private var startCLCoordinate: CLLocationCoordinate2D? {
        guard let coord = viewModel.startCoordinate else { return nil }
        return CLLocationCoordinate2D(latitude: coord.0, longitude: coord.1)
    }

    private var endCLCoordinate: CLLocationCoordinate2D? {
        guard let coord = viewModel.endCoordinate else { return nil }
        return CLLocationCoordinate2D(latitude: coord.0, longitude: coord.1)
    }
}
