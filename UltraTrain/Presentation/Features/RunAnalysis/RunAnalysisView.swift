import SwiftUI
import MapKit

struct RunAnalysisView: View {
    @State private var viewModel: RunAnalysisViewModel

    init(
        run: CompletedRun,
        planRepository: any TrainingPlanRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        runRepository: any RunRepository,
        finishEstimateRepository: any FinishEstimateRepository
    ) {
        _viewModel = State(initialValue: RunAnalysisViewModel(
            run: run,
            planRepository: planRepository,
            athleteRepository: athleteRepository,
            raceRepository: raceRepository,
            runRepository: runRepository,
            finishEstimateRepository: finishEstimateRepository
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
                        ElevationProfileChart(
                            dataPoints: viewModel.elevationProfile,
                            elevationSegments: viewModel.elevationSegments,
                            checkpointDistances: viewModel.checkpointDistanceNames
                        )
                    }

                    if viewModel.hasRouteData, !viewModel.elevationProfile.isEmpty {
                        InteractiveElevationMapView(
                            elevationProfile: viewModel.elevationProfile,
                            trackPoints: viewModel.run.gpsTrack,
                            checkpointDistances: viewModel.checkpointDistanceNames
                        )
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

                    if let performance = viewModel.racePerformance {
                        RacePerformanceCard(performance: performance)
                    }

                    if viewModel.hasAdvancedMetrics {
                        AdvancedMetricsCard(metrics: viewModel.advancedMetrics!)
                    }

                    if viewModel.hasNutritionAnalysis {
                        NutritionTimelineChart(
                            analysis: viewModel.nutritionAnalysis!,
                            splits: viewModel.run.splits
                        )
                        NutritionPerformanceCard(analysis: viewModel.nutritionAnalysis!)
                    }

                    if viewModel.hasHistoricalComparison {
                        HistoricalComparisonSection(comparison: viewModel.historicalComparison!)
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
                endCoordinate: endCLCoordinate,
                checkpointLocations: viewModel.checkpointLocations,
                coloringMode: viewModel.routeColoringMode,
                elevationSegments: viewModel.elevationSegments
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

            Picker("Coloring", selection: $viewModel.routeColoringMode) {
                Text("Pace").tag(RouteColoringMode.pace)
                Text("Elevation").tag(RouteColoringMode.elevation)
            }
            .pickerStyle(.segmented)

            RouteMapView(
                segments: viewModel.routeSegments,
                startCoordinate: startCLCoordinate,
                endCoordinate: endCLCoordinate,
                checkpointLocations: viewModel.checkpointLocations,
                coloringMode: viewModel.routeColoringMode,
                elevationSegments: viewModel.elevationSegments
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
