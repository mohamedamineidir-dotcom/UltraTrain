import SwiftUI

struct FinishEstimationView: View {
    @Environment(\.unitPreference) private var units
    @ScaledMetric(relativeTo: .largeTitle) var errorIconSize: CGFloat = 48
    @State private var viewModel: FinishEstimationViewModel

    let race: Race
    let finishTimeEstimator: any EstimateFinishTimeUseCase
    let athleteRepository: any AthleteRepository
    let runRepository: any RunRepository
    let fitnessCalculator: any CalculateFitnessUseCase
    let nutritionRepository: any NutritionRepository
    let nutritionGenerator: any GenerateNutritionPlanUseCase
    let raceRepository: any RaceRepository
    let finishEstimateRepository: any FinishEstimateRepository
    let weatherService: (any WeatherServiceProtocol)?
    let locationService: LocationService?
    let checklistRepository: any RacePrepChecklistRepository

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
                    if viewModel.race.hasCourseRoute {
                        InteractiveCourseProfileView(
                            viewModel: InteractiveCourseProfileViewModel(
                                courseRoute: viewModel.race.courseRoute,
                                checkpoints: viewModel.race.checkpoints
                            )
                        )
                        .cardStyle()
                    } else if !viewModel.race.checkpoints.isEmpty {
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
}
