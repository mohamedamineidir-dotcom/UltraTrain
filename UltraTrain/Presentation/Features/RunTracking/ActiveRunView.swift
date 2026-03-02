import SwiftUI

struct ActiveRunView: View {
    @Bindable var viewModel: ActiveRunViewModel
    let exportService: any ExportServiceProtocol
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ScaledMetric(relativeTo: .largeTitle) var timerFontSize: CGFloat = 56

    private var isLandscape: Bool { verticalSizeClass == .compact }

    var body: some View {
        Group {
            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
        .onAppear { OrientationLock.unlockAll() }
        .onDisappear { OrientationLock.resetToPortrait() }
        .navigationBarBackButtonHidden()
        .onAppear {
            if viewModel.runState == .notStarted {
                viewModel.startRun()
            }
        }
        .sheet(isPresented: $viewModel.showSummary) {
            RunSummarySheet(viewModel: viewModel, exportService: exportService) {
                dismiss()
            }
        }
    }

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {
        HStack(spacing: 0) {
            RunMapView(
                coordinates: viewModel.routeCoordinates,
                checkpointLocations: viewModel.racePacingHandler.resolvedCheckpointLocations
            )
            .padding(Theme.Spacing.sm)

            ScrollView {
                VStack(spacing: Theme.Spacing.sm) {
                    timerDisplay

                    ActiveRunStatsBar(
                        distance: viewModel.formattedDistance,
                        pace: viewModel.formattedPace,
                        elevation: viewModel.formattedElevation,
                        heartRate: viewModel.currentHeartRate
                    )

                    if let intervalState = viewModel.intervalHandler.currentState {
                        IntervalProgressBar(state: intervalState)
                    }

                    if let zoneState = viewModel.liveZoneState {
                        LiveHRZoneIndicator(state: zoneState, heartRate: viewModel.currentHeartRate)
                    }

                    if !viewModel.nutritionHandler.favoriteProducts.isEmpty {
                        NutritionQuickTapBar(
                            products: viewModel.nutritionHandler.favoriteProducts,
                            totals: viewModel.nutritionHandler.liveNutritionTotals,
                            onProductTapped: { viewModel.nutritionHandler.logProduct($0, elapsedTime: viewModel.elapsedTime) }
                        )
                    }

                    controls
                        .padding(.top, Theme.Spacing.sm)
                }
                .padding(Theme.Spacing.md)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
