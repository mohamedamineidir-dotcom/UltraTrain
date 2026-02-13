import SwiftUI

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
    }
}
