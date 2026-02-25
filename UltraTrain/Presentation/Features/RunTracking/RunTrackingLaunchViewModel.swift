import Foundation
import os

@Observable
@MainActor
final class RunTrackingLaunchViewModel {

    // MARK: - Dependencies

    let athleteRepository: any AthleteRepository
    private let planRepository: any TrainingPlanRepository
    let runRepository: any RunRepository
    let raceRepository: any RaceRepository
    private let appSettingsRepository: any AppSettingsRepository
    private let hapticService: any HapticServiceProtocol
    private let gearRepository: any GearRepository
    let finishTimeEstimator: any EstimateFinishTimeUseCase
    let finishEstimateRepository: any FinishEstimateRepository
    let weatherService: (any WeatherServiceProtocol)?
    let locationService: LocationService?
    let healthKitService: (any HealthKitServiceProtocol)?
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

    // MARK: - Session Selection

    func selectSession(_ session: TrainingSession?) {
        selectedSession = session
    }

    func startRun() {
        hapticService.playButtonTap()
        saveLastUsedGear()
        showActiveRun = true
    }

    func onRunSaved() {
        Task {
            await recalculateEstimateIfNeeded()
        }
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
}
