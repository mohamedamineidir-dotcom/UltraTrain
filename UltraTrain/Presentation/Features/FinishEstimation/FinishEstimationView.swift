import SwiftUI

struct FinishEstimationView: View {
    @Environment(\.unitPreference) private var units
    @ScaledMetric(relativeTo: .largeTitle) private var errorIconSize: CGFloat = 48
    @State private var viewModel: FinishEstimationViewModel

    private let race: Race
    private let finishTimeEstimator: any EstimateFinishTimeUseCase
    private let athleteRepository: any AthleteRepository
    private let runRepository: any RunRepository
    private let fitnessCalculator: any CalculateFitnessUseCase
    private let nutritionRepository: any NutritionRepository
    private let nutritionGenerator: any GenerateNutritionPlanUseCase
    private let raceRepository: any RaceRepository
    private let finishEstimateRepository: any FinishEstimateRepository
    private let weatherService: (any WeatherServiceProtocol)?
    private let locationService: LocationService?
    private let checklistRepository: any RacePrepChecklistRepository

    init(
        race: Race,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        athleteRepository: any AthleteRepository,
        runRepository: any RunRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        nutritionRepository: any NutritionRepository,
        nutritionGenerator: any GenerateNutritionPlanUseCase,
        raceRepository: any RaceRepository,
        finishEstimateRepository: any FinishEstimateRepository,
        weatherService: (any WeatherServiceProtocol)? = nil,
        locationService: LocationService? = nil,
        checklistRepository: any RacePrepChecklistRepository
    ) {
        self.race = race
        self.finishTimeEstimator = finishTimeEstimator
        self.athleteRepository = athleteRepository
        self.runRepository = runRepository
        self.fitnessCalculator = fitnessCalculator
        self.nutritionRepository = nutritionRepository
        self.nutritionGenerator = nutritionGenerator
        self.raceRepository = raceRepository
        self.finishEstimateRepository = finishEstimateRepository
        self.weatherService = weatherService
        self.locationService = locationService
        self.checklistRepository = checklistRepository
        _viewModel = State(initialValue: FinishEstimationViewModel(
            race: race,
            finishTimeEstimator: finishTimeEstimator,
            athleteRepository: athleteRepository,
            runRepository: runRepository,
            fitnessCalculator: fitnessCalculator,
            raceRepository: raceRepository,
            finishEstimateRepository: finishEstimateRepository,
            weatherService: weatherService
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                if viewModel.isLoading {
                    ProgressView("Calculating...")
                        .padding(.top, Theme.Spacing.xl)
                } else if let estimate = viewModel.estimate {
                    raceHeader
                    if !viewModel.race.checkpoints.isEmpty {
                        if !estimate.checkpointSplits.isEmpty {
                            RaceCoursePaceChart(
                                checkpoints: viewModel.race.checkpoints,
                                checkpointSplits: estimate.checkpointSplits
                            )
                        } else {
                            RaceCourseElevationChart(checkpoints: viewModel.race.checkpoints)
                        }
                    }
                    scenarioCards(estimate)
                    if let weatherImpact = viewModel.weatherImpact {
                        WeatherImpactCard(
                            impact: weatherImpact,
                            snapshot: viewModel.weatherSnapshot,
                            forecast: viewModel.dailyForecast
                        )
                    }
                    confidenceSection(estimate)
                    if estimate.raceResultsUsed > 0 {
                        raceCalibrationBadge(estimate: estimate)
                    }
                    if !estimate.checkpointSplits.isEmpty {
                        CheckpointSplitsCard(race: viewModel.race, estimate: estimate)
                    }
                    raceDayPlanLink
                } else if let error = viewModel.error {
                    errorSection(error)
                }
            }
            .padding()
        }
        .navigationTitle("Finish Estimate")
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Race Header

    private var raceHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(viewModel.race.name)
                .font(.title2.bold())
            HStack(spacing: Theme.Spacing.md) {
                Label(
                    UnitFormatter.formatDistance(viewModel.race.distanceKm, unit: units, decimals: 0),
                    systemImage: "point.topleft.down.to.point.bottomright.curvepath"
                )
                Label(
                    "\(UnitFormatter.formatElevation(viewModel.race.elevationGainM, unit: units)) D+",
                    systemImage: "mountain.2"
                )
                Label(
                    viewModel.race.terrainDifficulty.rawValue.capitalized,
                    systemImage: "map"
                )
            }
            .font(.caption)
            .foregroundStyle(Theme.Colors.secondaryLabel)

            if viewModel.race.date > .now {
                Text(viewModel.race.date.formatted(.dateTime.month(.wide).day().year()))
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Scenario Cards

    private func scenarioCards(_ estimate: FinishEstimate) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Predicted Finish Time")
                .font(.headline)

            HStack(spacing: Theme.Spacing.sm) {
                scenarioCard(
                    title: "Optimistic",
                    time: estimate.optimisticTime,
                    color: Theme.Colors.success
                )
                scenarioCard(
                    title: "Expected",
                    time: estimate.expectedTime,
                    color: Theme.Colors.primary
                )
                scenarioCard(
                    title: "Conservative",
                    time: estimate.conservativeTime,
                    color: Theme.Colors.warning
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func scenarioCard(title: String, time: TimeInterval, color: Color) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(FinishEstimate.formatDuration(time))
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(AccessibilityFormatters.duration(time))")
    }

    // MARK: - Confidence

    private func confidenceSection(_ estimate: FinishEstimate) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Confidence")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.0f%%", estimate.confidencePercent))
                    .font(.subheadline.bold().monospacedDigit())
            }

            ProgressView(value: estimate.confidencePercent, total: 100)
                .tint(confidenceColor(estimate.confidencePercent))

            Text(confidenceLabel(estimate.confidencePercent))
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .cardStyle()
    }

    private func confidenceColor(_ percent: Double) -> Color {
        if percent >= 70 { return Theme.Colors.success }
        if percent >= 50 { return Theme.Colors.warning }
        return Theme.Colors.danger
    }

    private func confidenceLabel(_ percent: Double) -> String {
        if percent >= 70 { return "Strong prediction — good training data available" }
        if percent >= 50 { return "Moderate prediction — more training data would improve accuracy" }
        return "Low confidence — keep training to improve prediction accuracy"
    }

    // MARK: - Race Calibration Badge

    private func raceCalibrationBadge(estimate: FinishEstimate) -> some View {
        let count = estimate.raceResultsUsed
        let factor = estimate.calibrationFactor
        let accuracy = (1.0 - abs(1.0 - factor)) * 100

        return VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Theme.Colors.success)
                    .accessibilityHidden(true)
                Text("Calibrated from \(count) results")
                    .font(.subheadline)
            }
            if factor != 1.0 {
                Text(String(format: "Avg. accuracy: %.0f%%", accuracy))
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(calibrationDescription(factor))
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.success.opacity(0.1))
        )
    }

    private func calibrationDescription(_ factor: Double) -> String {
        if factor < 1.0 {
            return "Model adjusted down — you're faster than predicted"
        }
        return "Model adjusted up — you're slower than predicted"
    }

    // MARK: - Race Day Plan Link

    private var raceDayPlanLink: some View {
        NavigationLink {
            RaceDayPlanView(
                race: race,
                finishTimeEstimator: finishTimeEstimator,
                athleteRepository: athleteRepository,
                runRepository: runRepository,
                fitnessCalculator: fitnessCalculator,
                nutritionRepository: nutritionRepository,
                nutritionGenerator: nutritionGenerator,
                raceRepository: raceRepository,
                finishEstimateRepository: finishEstimateRepository,
                weatherService: weatherService,
                locationService: locationService,
                checklistRepository: checklistRepository
            )
        } label: {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundStyle(Theme.Colors.primary)
                    .accessibilityHidden(true)
                Text("Race Day Plan")
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .accessibilityHidden(true)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Error

    private func errorSection(_ message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: errorIconSize))
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            Text(message)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.Spacing.xl)
    }
}
