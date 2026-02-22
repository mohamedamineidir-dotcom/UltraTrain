import Foundation
import os

@Observable
@MainActor
final class RunTrackingLaunchViewModel {

    // MARK: - Dependencies

    private let athleteRepository: any AthleteRepository
    private let planRepository: any TrainingPlanRepository
    private let runRepository: any RunRepository
    private let raceRepository: any RaceRepository
    private let appSettingsRepository: any AppSettingsRepository
    private let hapticService: any HapticServiceProtocol
    private let gearRepository: any GearRepository
    private let finishTimeEstimator: any EstimateFinishTimeUseCase
    private let finishEstimateRepository: any FinishEstimateRepository
    private let weatherService: (any WeatherServiceProtocol)?
    private let locationService: LocationService?
    private let healthKitService: (any HealthKitServiceProtocol)?
    private let recoveryRepository: (any RecoveryRepository)?
    private let intervalWorkoutRepository: (any IntervalWorkoutRepository)?

    // MARK: - State

    var athlete: Athlete?
    var todaysSessions: [TrainingSession] = []
    var selectedSession: TrainingSession?
    var isLoading = false
    var error: String?
    var showActiveRun = false
    var autoPauseEnabled = true
    var nutritionRemindersEnabled = false
    var nutritionAlertSoundEnabled = true
    var raceId: UUID?
    var todaysRace: Race?
    var stravaAutoUploadEnabled = false
    var hydrationIntervalSeconds: TimeInterval = 1200
    var fuelIntervalSeconds: TimeInterval = 2700
    var electrolyteIntervalSeconds: TimeInterval = 0
    var smartRemindersEnabled = false
    var activeGear: [GearItem] = []
    var selectedGearIds: Set<UUID> = []
    var saveToHealthEnabled = false
    var pacingAlertsEnabled = true
    var voiceCoachingConfig = VoiceCoachingConfig()
    var preRunWeather: WeatherSnapshot?
    var preRunBriefing: PreRunBriefing?
    var intervalWorkout: IntervalWorkout?
    var safetyConfig = SafetyConfig()
    var raceCourseRoute: [TrackPoint]?
    var raceCheckpoints: [Checkpoint]?
    var raceCheckpointSplits: [CheckpointSplit]?
    var raceTotalDistanceKm: Double?

    // MARK: - Init

    init(
        athleteRepository: any AthleteRepository,
        planRepository: any TrainingPlanRepository,
        runRepository: any RunRepository,
        raceRepository: any RaceRepository,
        appSettingsRepository: any AppSettingsRepository,
        hapticService: any HapticServiceProtocol,
        gearRepository: any GearRepository,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        finishEstimateRepository: any FinishEstimateRepository,
        weatherService: (any WeatherServiceProtocol)? = nil,
        locationService: LocationService? = nil,
        healthKitService: (any HealthKitServiceProtocol)? = nil,
        recoveryRepository: (any RecoveryRepository)? = nil,
        intervalWorkoutRepository: (any IntervalWorkoutRepository)? = nil
    ) {
        self.athleteRepository = athleteRepository
        self.planRepository = planRepository
        self.runRepository = runRepository
        self.raceRepository = raceRepository
        self.appSettingsRepository = appSettingsRepository
        self.hapticService = hapticService
        self.gearRepository = gearRepository
        self.finishTimeEstimator = finishTimeEstimator
        self.finishEstimateRepository = finishEstimateRepository
        self.weatherService = weatherService
        self.locationService = locationService
        self.healthKitService = healthKitService
        self.recoveryRepository = recoveryRepository
        self.intervalWorkoutRepository = intervalWorkoutRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            athlete = try await athleteRepository.getAthlete()
            if let plan = try await planRepository.getActivePlan() {
                todaysSessions = extractTodaysSessions(from: plan)
                if todaysSessions.count == 1 {
                    selectedSession = todaysSessions.first
                }
            }

            // Detect today's race for race-run linking
            let allRaces = try await raceRepository.getRaces()
            let calendar = Calendar.current
            todaysRace = allRaces.first { calendar.isDate($0.date, inSameDayAs: Date.now) }
            raceId = todaysRace?.id

            if let race = todaysRace, race.hasCourseRoute {
                raceCourseRoute = race.courseRoute
                raceCheckpoints = race.checkpoints
                raceTotalDistanceKm = race.distanceKm
                await loadCheckpointSplits(raceId: race.id)
            }

            if let settings = try await appSettingsRepository.getSettings() {
                autoPauseEnabled = settings.autoPauseEnabled
                nutritionRemindersEnabled = settings.nutritionRemindersEnabled
                nutritionAlertSoundEnabled = settings.nutritionAlertSoundEnabled
                stravaAutoUploadEnabled = settings.stravaAutoUploadEnabled
                hydrationIntervalSeconds = settings.hydrationIntervalSeconds
                fuelIntervalSeconds = settings.fuelIntervalSeconds
                electrolyteIntervalSeconds = settings.electrolyteIntervalSeconds
                smartRemindersEnabled = settings.smartRemindersEnabled
                saveToHealthEnabled = settings.saveToHealthEnabled
                pacingAlertsEnabled = settings.pacingAlertsEnabled
                voiceCoachingConfig = settings.voiceCoachingConfig
                safetyConfig = settings.safetyConfig
            }

            activeGear = try await gearRepository.getActiveGear(ofType: nil)
            restoreLastUsedGear()

            if let workoutId = selectedSession?.intervalWorkoutId,
               let repo = intervalWorkoutRepository {
                intervalWorkout = try await repo.getWorkout(id: workoutId)
            }
        } catch {
            self.error = error.localizedDescription
            Logger.tracking.error("Failed to load run launch data: \(error)")
        }

        isLoading = false
        await loadWeather()
        await loadPreRunBriefing()
    }

    // MARK: - Weather

    private func loadWeather() async {
        guard let weatherService, let locationService else { return }
        guard let location = locationService.currentLocation else { return }
        do {
            preRunWeather = try await weatherService.currentWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        } catch {
            Logger.weather.debug("Pre-run: could not load weather: \(error)")
        }
    }

    // MARK: - Session Selection

    func selectSession(_ session: TrainingSession?) {
        selectedSession = session
    }

    func startRun() {
        hapticService.playButtonTap()
        saveLastUsedGear()
        showActiveRun = true
    }

    // MARK: - Private

    private static let lastUsedGearKey = "lastUsedGearIds"

    private func saveLastUsedGear() {
        let ids = selectedGearIds.map(\.uuidString)
        UserDefaults.standard.set(ids, forKey: Self.lastUsedGearKey)
    }

    private func restoreLastUsedGear() {
        guard let stored = UserDefaults.standard.stringArray(forKey: Self.lastUsedGearKey) else { return }
        let activeIds = Set(activeGear.map(\.id))
        let restoredIds = stored.compactMap(UUID.init).filter { activeIds.contains($0) }
        if !restoredIds.isEmpty {
            selectedGearIds = Set(restoredIds)
        }
    }

    func onRunSaved() {
        Task {
            await recalculateEstimateIfNeeded()
        }
    }

    private func recalculateEstimateIfNeeded() async {
        do {
            let races = try await raceRepository.getRaces()
            guard let aRace = races.first(where: { $0.priority == .aRace }) else { return }
            guard let athlete = try await athleteRepository.getAthlete() else { return }
            let runs = try await runRepository.getRuns(for: athlete.id)
            guard !runs.isEmpty else { return }

            let estimate = try await finishTimeEstimator.execute(
                athlete: athlete,
                race: aRace,
                recentRuns: runs,
                currentFitness: nil
            )
            try await finishEstimateRepository.saveEstimate(estimate)
        } catch {
            Logger.training.debug("Auto-recalculation skipped: \(error)")
        }
    }

    private func loadCheckpointSplits(raceId: UUID) async {
        do {
            let estimate = try await finishEstimateRepository.getEstimate(for: raceId)
            raceCheckpointSplits = estimate?.checkpointSplits
        } catch {
            Logger.tracking.debug("Could not load checkpoint splits: \(error)")
        }
    }

    private func extractTodaysSessions(from plan: TrainingPlan) -> [TrainingSession] {
        let calendar = Calendar.current
        let today = Date.now

        for week in plan.weeks {
            let sessions = week.sessions.filter { session in
                calendar.isDate(session.date, inSameDayAs: today)
                    && !session.isCompleted
                    && session.type != .rest
            }
            if !sessions.isEmpty { return sessions }
        }
        return []
    }

    // MARK: - Pre-Run Briefing

    private func loadPreRunBriefing() async {
        guard let healthKitService else { return }
        do {
            let runs = try await runRepository.getRecentRuns(limit: 30)

            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date.now) ?? Date.now
            let sleepEntries = try await healthKitService.fetchSleepData(from: yesterday, to: .now)
            let lastNight = sleepEntries.last

            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date.now) ?? Date.now
            let sleepHistory = try await healthKitService.fetchSleepData(from: sevenDaysAgo, to: .now)

            let currentHR = try await healthKitService.fetchRestingHeartRate()
            let baselineHR = athlete?.restingHeartRate

            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date.now) ?? Date.now
            let hrvReadings = try await healthKitService.fetchHRVData(from: thirtyDaysAgo, to: .now)
            let hrvTrend = HRVAnalyzer.analyze(readings: hrvReadings)
            let hrvScore: Int? = hrvTrend.map { HRVAnalyzer.hrvScore(trend: $0) }

            let recoveryScore = RecoveryScoreCalculator.calculate(
                lastNightSleep: lastNight,
                sleepHistory: sleepHistory,
                currentRestingHR: currentHR,
                baselineRestingHR: baselineHR,
                fitnessSnapshot: nil,
                hrvScore: hrvScore
            )

            var readinessScore: ReadinessScore?
            if let trend = hrvTrend {
                readinessScore = ReadinessCalculator.calculate(
                    recoveryScore: recoveryScore,
                    hrvTrend: trend,
                    fitnessSnapshot: nil
                )
            }

            let fatigueInput = FatiguePatternDetector.Input(
                recentRuns: runs,
                sleepHistory: sleepHistory,
                recoveryScores: [recoveryScore]
            )
            let fatiguePatterns = FatiguePatternDetector.detect(input: fatigueInput)

            preRunBriefing = PreRunBriefingBuilder.build(
                session: selectedSession,
                readinessScore: readinessScore,
                recoveryScore: recoveryScore,
                weather: preRunWeather,
                fatiguePatterns: fatiguePatterns,
                recentRuns: runs,
                athlete: athlete
            )
        } catch {
            Logger.tracking.debug("Pre-run briefing unavailable: \(error)")
        }
    }
}
