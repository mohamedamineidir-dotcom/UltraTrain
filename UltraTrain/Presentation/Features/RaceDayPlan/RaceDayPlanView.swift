import SwiftUI

struct RaceDayPlanView: View {
    @Environment(\.unitPreference) private var units
    @State private var viewModel: RaceDayPlanViewModel
    private let race: Race
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
        self.checklistRepository = checklistRepository
        _viewModel = State(initialValue: RaceDayPlanViewModel(
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
            locationService: locationService
        ))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                if viewModel.isLoading {
                    ProgressView("Building race plan...")
                        .padding(.top, Theme.Spacing.xl)
                } else if !viewModel.segments.isEmpty {
                    raceHeader
                    RaceDayWeatherCard(
                        forecast: viewModel.raceDayForecast,
                        raceDate: viewModel.race.date,
                        isAvailable: viewModel.forecastAvailable,
                        isLoading: viewModel.isLoading
                    )
                    if let plan = viewModel.nutritionPlan, let estimate = viewModel.estimate {
                        summaryCard(estimate: estimate, plan: plan)
                    }
                    checklistLink
                    if let pacing = viewModel.pacingResult, !pacing.segmentPacings.isEmpty {
                        PacingSummaryCard(
                            pacingResult: pacing,
                            aidStationDwellSeconds: viewModel.aidStationDwellSeconds,
                            onDwellTimeChanged: { viewModel.updateDwellTime($0) },
                            terrainPaceProfile: viewModel.terrainPaceProfile,
                            pacingMode: viewModel.pacingMode,
                            onPacingModeChanged: { viewModel.setPacingMode($0) }
                        )
                    }
                    if !viewModel.segments.isEmpty, viewModel.terrainPaceProfile != nil {
                        PaceProfileChart(
                            segments: viewModel.segments,
                            checkpoints: viewModel.race.checkpoints
                        )
                    }
                    startBanner
                    segmentCards
                    finishBanner
                } else if let error = viewModel.error {
                    errorSection(error)
                }
            }
            .padding()
        }
        .navigationTitle("Race Day Plan")
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

            Text(viewModel.race.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Summary Card

    private func summaryCard(estimate: FinishEstimate, plan: NutritionPlan) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Race Overview")
                .font(.headline)

            HStack(spacing: Theme.Spacing.sm) {
                StatCard(
                    title: "Expected",
                    value: FinishEstimate.formatDuration(estimate.expectedTime),
                    unit: ""
                )
                StatCard(
                    title: "Cal/h",
                    value: "\(plan.caloriesPerHour)",
                    unit: "kcal"
                )
                StatCard(
                    title: "Hydration",
                    value: "\(plan.hydrationMlPerHour)",
                    unit: "ml/h"
                )
            }
        }
        .cardStyle()
    }

    // MARK: - Start Banner

    private var startBanner: some View {
        HStack {
            Image(systemName: "flag.fill")
                .foregroundStyle(Theme.Colors.success)
                .accessibilityHidden(true)
            Text("START")
                .font(.subheadline.bold())
            Spacer()
            Text(viewModel.race.date.formatted(.dateTime.hour().minute()))
                .font(.subheadline.bold().monospacedDigit())
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.success.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Start at \(viewModel.race.date.formatted(.dateTime.hour().minute()))")
    }

    // MARK: - Segment Cards

    private var segmentCards: some View {
        ForEach(viewModel.segments) { segment in
            RaceDaySegmentCard(segment: segment)
        }
    }

    // MARK: - Finish Banner

    private var finishBanner: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundStyle(Theme.Colors.primary)
                    .accessibilityHidden(true)
                Text("FINISH")
                    .font(.subheadline.bold())
                Spacer()
            }

            if let estimate = viewModel.estimate {
                HStack(spacing: Theme.Spacing.sm) {
                    finishScenario(
                        label: "Best",
                        time: estimate.optimisticTime,
                        color: Theme.Colors.success
                    )
                    finishScenario(
                        label: "Expected",
                        time: estimate.expectedTime,
                        color: Theme.Colors.primary
                    )
                    finishScenario(
                        label: "Worst",
                        time: estimate.conservativeTime,
                        color: Theme.Colors.warning
                    )
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.primary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }

    private func finishScenario(label: String, time: TimeInterval, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(FinishEstimate.formatDuration(time))
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(AccessibilityFormatters.duration(time))")
    }

    // MARK: - Checklist Link

    private var checklistLink: some View {
        NavigationLink {
            RacePrepChecklistView(race: race, repository: checklistRepository)
        } label: {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(Theme.Colors.primary)
                    .accessibilityHidden(true)
                Text("Race Prep Checklist")
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
            Image(systemName: "map.circle")
                .font(.largeTitle)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            Text(message)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.Spacing.xl)
    }
}
