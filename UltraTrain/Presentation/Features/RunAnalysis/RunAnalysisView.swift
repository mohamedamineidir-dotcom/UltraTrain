import SwiftUI
import MapKit

struct RunAnalysisView: View {
    @Environment(\.unitPreference) private var units
    @State private var viewModel: RunAnalysisViewModel

    init(
        run: CompletedRun,
        planRepository: any TrainingPlanRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        runRepository: any RunRepository,
        finishEstimateRepository: any FinishEstimateRepository,
        exportService: any ExportServiceProtocol
    ) {
        _viewModel = State(initialValue: RunAnalysisViewModel(
            run: run,
            planRepository: planRepository,
            athleteRepository: athleteRepository,
            raceRepository: raceRepository,
            runRepository: runRepository,
            finishEstimateRepository: finishEstimateRepository,
            exportService: exportService
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

                    if viewModel.hasRouteComparison,
                       let courseRoute = viewModel.linkedRaceCourseRoute,
                       let comparison = viewModel.routeComparison {
                        RouteComparisonOverlay(
                            actualRoute: viewModel.run.gpsTrack,
                            plannedRoute: courseRoute,
                            comparison: comparison
                        )
                    }

                    if !viewModel.elevationProfile.isEmpty {
                        ElevationProfileChart(
                            dataPoints: viewModel.elevationProfile,
                            elevationSegments: viewModel.elevationSegments,
                            checkpointDistances: viewModel.checkpointDistanceNames
                        )
                    }

                    if !viewModel.elevationProfile.isEmpty, !viewModel.run.splits.isEmpty {
                        ElevationPaceChart(
                            elevationProfile: viewModel.elevationProfile,
                            splits: viewModel.run.splits,
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

                    if let compliance = viewModel.zoneCompliance {
                        ZoneComplianceCard(compliance: compliance)
                    }

                    if let comparison = viewModel.planComparison {
                        PlanComparisonCard(comparison: comparison)
                    }

                    if let performance = viewModel.racePerformance {
                        RacePerformanceCard(performance: performance)
                    }

                    if viewModel.hasAdvancedMetrics {
                        AdvancedMetricsCard(
                            metrics: viewModel.advancedMetrics!,
                            trainingStressScore: viewModel.trainingStressScore
                        )
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showingExportOptions = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityIdentifier("runAnalysis.exportButton")
                .accessibilityLabel("Share and export")
                .accessibilityHint("Open export options for this run")
                .disabled(viewModel.isExporting || viewModel.isLoading)
            }
        }
        .confirmationDialog("Share & Export", isPresented: $viewModel.showingExportOptions) {
            Button("Share as Image") {
                Task { await viewModel.exportAsShareImage(unitPreference: units) }
            }
            .accessibilityIdentifier("runAnalysis.shareImage")
            Button("Export as GPX") {
                Task { await viewModel.exportAsGPX() }
            }
            .accessibilityIdentifier("runAnalysis.exportGPX")
            Button("Export Track Points (CSV)") {
                Task { await viewModel.exportAsTrackCSV() }
            }
            .accessibilityIdentifier("runAnalysis.exportCSV")
            Button("Export as PDF Report") {
                Task { await viewModel.exportAsPDF() }
            }
            .accessibilityIdentifier("runAnalysis.exportPDF")
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            if let url = viewModel.exportFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Export Error", isPresented: .init(
            get: { viewModel.exportError != nil },
            set: { if !$0 { viewModel.exportError = nil } }
        )) {
            Button("OK") { viewModel.exportError = nil }
        } message: {
            Text(viewModel.exportError ?? "")
        }
        .overlay {
            if viewModel.isExporting {
                ProgressView("Exporting...")
                    .padding(Theme.Spacing.lg)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
            }
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $viewModel.showFullScreenMap) {
            FullScreenMapView(
                segments: viewModel.routeSegments,
                startCoordinate: startCLCoordinate,
                endCoordinate: endCLCoordinate,
                checkpointLocations: viewModel.checkpointLocations,
                coloringMode: viewModel.routeColoringMode,
                elevationSegments: viewModel.elevationSegments,
                heartRateSegments: viewModel.heartRateSegments,
                distanceMarkers: viewModel.distanceMarkers,
                segmentDetails: viewModel.segmentDetails,
                selectedSegment: $viewModel.selectedSegment
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
                if viewModel.hasHeartRateData {
                    Text("HR").tag(RouteColoringMode.heartRate)
                }
            }
            .pickerStyle(.segmented)

            RouteMapView(
                segments: viewModel.routeSegments,
                startCoordinate: startCLCoordinate,
                endCoordinate: endCLCoordinate,
                checkpointLocations: viewModel.checkpointLocations,
                coloringMode: viewModel.routeColoringMode,
                elevationSegments: viewModel.elevationSegments,
                heartRateSegments: viewModel.heartRateSegments,
                distanceMarkers: viewModel.distanceMarkers,
                segmentDetails: viewModel.segmentDetails,
                selectedSegment: $viewModel.selectedSegment
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
