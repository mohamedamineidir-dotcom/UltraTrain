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

    // MARK: - Init

    init(
        athleteRepository: any AthleteRepository,
        planRepository: any TrainingPlanRepository,
        runRepository: any RunRepository,
        raceRepository: any RaceRepository,
        appSettingsRepository: any AppSettingsRepository,
        hapticService: any HapticServiceProtocol
    ) {
        self.athleteRepository = athleteRepository
        self.planRepository = planRepository
        self.runRepository = runRepository
        self.raceRepository = raceRepository
        self.appSettingsRepository = appSettingsRepository
        self.hapticService = hapticService
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            athlete = try await athleteRepository.getAthlete()
            if let plan = try await planRepository.getActivePlan() {
                todaysSessions = extractTodaysSessions(from: plan)
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
            }
        } catch {
            self.error = error.localizedDescription
            Logger.tracking.error("Failed to load run launch data: \(error)")
        }

        isLoading = false
    }

    // MARK: - Session Selection

    func selectSession(_ session: TrainingSession?) {
        selectedSession = session
    }

    func startRun() {
        hapticService.playButtonTap()
        showActiveRun = true
    }

    // MARK: - Private

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
