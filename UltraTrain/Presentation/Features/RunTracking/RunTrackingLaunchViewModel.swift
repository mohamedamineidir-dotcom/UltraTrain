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
    var preRunWeather: WeatherSnapshot?

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
        locationService: LocationService? = nil
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
            }

            activeGear = try await gearRepository.getActiveGear(ofType: nil)
            restoreLastUsedGear()
        } catch {
            self.error = error.localizedDescription
            Logger.tracking.error("Failed to load run launch data: \(error)")
        }

        isLoading = false
        await loadWeather()
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
