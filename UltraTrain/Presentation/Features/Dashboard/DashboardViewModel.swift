import Foundation
import os

enum FitnessStatus: Equatable {
    case noData
    case optimal
    case injuryRisk
    case detraining
}

@Observable
@MainActor
final class DashboardViewModel {

    // MARK: - Dependencies

    let planRepository: any TrainingPlanRepository
    let runRepository: any RunRepository
    let athleteRepository: any AthleteRepository
    let fitnessRepository: any FitnessRepository
    let fitnessCalculator: any CalculateFitnessUseCase
    let raceRepository: any RaceRepository
    let finishTimeEstimator: any EstimateFinishTimeUseCase
    let finishEstimateRepository: any FinishEstimateRepository
    let healthKitService: any HealthKitServiceProtocol
    let recoveryRepository: any RecoveryRepository
    let weatherService: (any WeatherServiceProtocol)?
    let locationService: LocationService?
    let challengeRepository: (any ChallengeRepository)?
    let goalRepository: (any GoalRepository)?

    // MARK: - State

    var plan: TrainingPlan?
    var fitnessSnapshot: FitnessSnapshot?
    var fitnessHistory: [FitnessSnapshot] = []
    var runCount = 0
    var isLoading = false
    var fitnessError: String?
    var finishEstimate: FinishEstimate?
    var aRace: Race?
    var lastRun: CompletedRun?
    var upcomingRaces: [Race] = []
    var injuryRiskAlerts: [InjuryRiskAlert] = []
    var coachingInsights: [CoachingInsight] = []
    var currentWeather: WeatherSnapshot?
    var sessionForecast: WeatherSnapshot?
    var recoveryScore: RecoveryScore?
    var readinessScore: ReadinessScore?
    var hrvTrend: HRVAnalyzer.HRVTrend?
    var sleepHistory: [SleepEntry] = []
    var weeklyZoneDistribution: [HeartRateZoneDistribution] = []
    var currentStreak: Int = 0
    var nearestChallengeProgress: ChallengeProgressCalculator.ChallengeProgress?
    var personalRecords: [PersonalRecord] = []
    var weeklyGoalProgress: GoalProgress?
    var monthlyGoalProgress: GoalProgress?
    var optimalSession: OptimalSession?
    var fatiguePatterns: [FatiguePattern] = []
    var performanceTrends: [PerformanceTrend] = []

    // MARK: - Init

    init(
        planRepository: any TrainingPlanRepository,
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository,
        fitnessRepository: any FitnessRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        raceRepository: any RaceRepository,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        finishEstimateRepository: any FinishEstimateRepository,
        healthKitService: any HealthKitServiceProtocol,
        recoveryRepository: any RecoveryRepository,
        weatherService: (any WeatherServiceProtocol)? = nil,
        locationService: LocationService? = nil,
        challengeRepository: (any ChallengeRepository)? = nil,
        goalRepository: (any GoalRepository)? = nil
    ) {
        self.planRepository = planRepository
        self.runRepository = runRepository
        self.athleteRepository = athleteRepository
        self.fitnessRepository = fitnessRepository
        self.fitnessCalculator = fitnessCalculator
        self.raceRepository = raceRepository
        self.finishTimeEstimator = finishTimeEstimator
        self.finishEstimateRepository = finishEstimateRepository
        self.healthKitService = healthKitService
        self.recoveryRepository = recoveryRepository
        self.weatherService = weatherService
        self.locationService = locationService
        self.challengeRepository = challengeRepository
        self.goalRepository = goalRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        do {
            plan = try await planRepository.getActivePlan()
        } catch {
            Logger.training.error("Dashboard failed to load plan: \(error)")
        }

        async let fitnessTask: () = loadFitness()
        async let estimateTask: () = loadFinishEstimate()
        async let lastRunTask: () = loadLastRun()
        async let racesTask: () = loadUpcomingRaces()
        async let weatherTask: () = loadWeather()
        async let challengesTask: () = loadChallenges()
        async let goalsTask: () = loadGoals()
        _ = await (fitnessTask, estimateTask, lastRunTask, racesTask, weatherTask, challengesTask, goalsTask)

        await loadRecovery()
        await loadAICoach()

        isLoading = false
    }

    func loadFitness() async {
        do {
            guard let athlete = try await athleteRepository.getAthlete() else { return }
            let runs = try await runRepository.getRuns(for: athlete.id)
            runCount = runs.count
            personalRecords = PersonalRecordCalculator.computeAll(from: runs)
            guard !runs.isEmpty else {
                fitnessSnapshot = nil
                return
            }
            let snapshot = try await fitnessCalculator.execute(runs: runs, asOf: .now)
            try await fitnessRepository.saveSnapshot(snapshot)
            fitnessSnapshot = snapshot

            let volumes = WeeklyVolumeCalculator.compute(from: runs, weekCount: 3)
            injuryRiskAlerts = InjuryRiskCalculator.assess(
                weeklyVolumes: volumes,
                currentACR: snapshot.acuteToChronicRatio,
                monotony: snapshot.monotony
            )

            coachingInsights = CoachingInsightCalculator.generate(
                fitness: snapshot,
                plan: plan,
                weeklyVolumes: volumes,
                nextRace: upcomingRaces.first,
                adherencePercent: adherencePercent,
                recoveryScore: recoveryScore,
                hrvTrend: hrvTrend,
                readinessScore: readinessScore
            )

            let weekResult = WeeklyZoneDistributionCalculator.calculate(
                runs: runs,
                weekStartDate: Date.now.startOfWeek,
                maxHeartRate: athlete.maxHeartRate,
                customThresholds: athlete.customZoneThresholds
            )
            weeklyZoneDistribution = weekResult.distributions

            let from = Date.now.adding(days: -28)
            fitnessHistory = try await fitnessRepository.getSnapshots(from: from, to: .now)
        } catch {
            fitnessError = error.localizedDescription
            Logger.fitness.error("Failed to load fitness: \(error)")
        }
    }

    func loadLastRun() async {
        do {
            let recent = try await runRepository.getRecentRuns(limit: 1)
            lastRun = recent.first
        } catch {
            Logger.training.debug("Dashboard: could not load last run: \(error)")
        }
    }

    func loadUpcomingRaces() async {
        do {
            let allRaces = try await raceRepository.getRaces()
            let today = Date.now.startOfDay
            upcomingRaces = Array(
                allRaces
                    .filter { $0.date >= today }
                    .sorted { $0.date < $1.date }
                    .prefix(3)
            )
        } catch {
            Logger.training.debug("Dashboard: could not load races: \(error)")
        }
    }
}
