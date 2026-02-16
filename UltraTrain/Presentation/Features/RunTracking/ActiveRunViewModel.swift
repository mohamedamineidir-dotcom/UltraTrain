import Foundation
import CoreLocation
import os

enum RunState: Equatable {
    case notStarted
    case running
    case paused
    case finished
}

@Observable
@MainActor
final class ActiveRunViewModel {

    // MARK: - Dependencies

    private let locationService: LocationService
    private let healthKitService: any HealthKitServiceProtocol
    private let runRepository: any RunRepository
    private let planRepository: any TrainingPlanRepository
    private let nutritionRepository: any NutritionRepository
    private let hapticService: any HapticServiceProtocol

    // MARK: - Config

    let athlete: Athlete
    let linkedSession: TrainingSession?
    let autoPauseEnabled: Bool
    let nutritionRemindersEnabled: Bool
    let nutritionAlertSoundEnabled: Bool
    let raceId: UUID?

    // MARK: - State

    var runState: RunState = .notStarted
    var elapsedTime: TimeInterval = 0
    var pausedDuration: TimeInterval = 0
    var distanceKm: Double = 0
    var elevationGainM: Double = 0
    var elevationLossM: Double = 0
    var currentPace: String = "--:--"
    var currentHeartRate: Int?
    var trackPoints: [TrackPoint] = []
    var routeCoordinates: [CLLocationCoordinate2D] = []
    var error: String?
    var showSummary = false
    var isSaving = false
    var isAutoPaused = false
    var nutritionReminders: [NutritionReminder] = []
    var activeReminder: NutritionReminder?

    // MARK: - Private

    private var timerTask: Task<Void, Never>?
    private var locationTask: Task<Void, Never>?
    private var heartRateTask: Task<Void, Never>?
    private var autoPauseTimer: TimeInterval = 0
    private var pauseStartTime: Date?

    // MARK: - Init

    init(
        locationService: LocationService,
        healthKitService: any HealthKitServiceProtocol,
        runRepository: any RunRepository,
        planRepository: any TrainingPlanRepository,
        nutritionRepository: any NutritionRepository,
        hapticService: any HapticServiceProtocol,
        athlete: Athlete,
        linkedSession: TrainingSession?,
        autoPauseEnabled: Bool,
        nutritionRemindersEnabled: Bool,
        nutritionAlertSoundEnabled: Bool,
        raceId: UUID?
    ) {
        self.locationService = locationService
        self.healthKitService = healthKitService
        self.runRepository = runRepository
        self.planRepository = planRepository
        self.nutritionRepository = nutritionRepository
        self.hapticService = hapticService
        self.athlete = athlete
        self.linkedSession = linkedSession
        self.autoPauseEnabled = autoPauseEnabled
        self.nutritionRemindersEnabled = nutritionRemindersEnabled
        self.nutritionAlertSoundEnabled = nutritionAlertSoundEnabled
        self.raceId = raceId
    }

    // MARK: - Controls

    func startRun() {
        runState = .running
        loadNutritionReminders()
        if nutritionAlertSoundEnabled { hapticService.prepareHaptics() }
        startTimer()
        startLocationTracking()
        startHeartRateStreaming()
        Logger.tracking.info("Run started")
    }

    func pauseRun(auto: Bool = false) {
        guard runState == .running else { return }
        runState = .paused
        isAutoPaused = auto
        pauseStartTime = Date.now
        timerTask?.cancel()
        if !auto {
            locationService.pauseTracking()
        }
        Logger.tracking.info("Run \(auto ? "auto-" : "")paused at \(self.elapsedTime)s")
    }

    func resumeRun() {
        guard runState == .paused else { return }
        if let start = pauseStartTime {
            pausedDuration += Date.now.timeIntervalSince(start)
        }
        let wasManuallyPaused = !isAutoPaused
        pauseStartTime = nil
        isAutoPaused = false
        autoPauseTimer = 0
        runState = .running
        startTimer()
        if wasManuallyPaused {
            locationService.resumeTracking()
        }
        Logger.tracking.info("Run resumed")
    }

    func stopRun() {
        if let start = pauseStartTime {
            pausedDuration += Date.now.timeIntervalSince(start)
            pauseStartTime = nil
        }
        runState = .finished
        timerTask?.cancel()
        locationTask?.cancel()
        heartRateTask?.cancel()
        locationService.stopTracking()
        healthKitService.stopHeartRateStream()
        showSummary = true
        Logger.tracking.info("Run stopped — \(self.distanceKm) km in \(self.elapsedTime)s")
    }

    // MARK: - Save

    func saveRun(notes: String?) async {
        isSaving = true
        let splits = RunStatisticsCalculator.buildSplits(from: trackPoints)
        let heartRates = trackPoints.compactMap(\.heartRate)
        let avgHR = heartRates.isEmpty ? nil : heartRates.reduce(0, +) / heartRates.count
        let maxHR = heartRates.max()
        let pace = RunStatisticsCalculator.averagePace(
            distanceKm: distanceKm, duration: elapsedTime
        )

        let run = CompletedRun(
            id: UUID(),
            athleteId: athlete.id,
            date: Date.now,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: elevationLossM,
            duration: elapsedTime,
            averageHeartRate: avgHR,
            maxHeartRate: maxHR,
            averagePaceSecondsPerKm: pace,
            gpsTrack: trackPoints,
            splits: splits,
            linkedSessionId: linkedSession?.id,
            notes: notes,
            pausedDuration: pausedDuration
        )

        do {
            try await runRepository.saveRun(run)
            if let session = linkedSession {
                var updated = session
                updated.isCompleted = true
                updated.linkedRunId = run.id
                try await planRepository.updateSession(updated)
            }
            Logger.tracking.info("Run saved: \(run.id)")
        } catch {
            self.error = error.localizedDescription
            Logger.tracking.error("Failed to save run: \(error)")
        }
        isSaving = false
    }

    func discardRun() {
        Logger.tracking.info("Run discarded")
    }

    // MARK: - Computed

    var formattedTime: String {
        RunStatisticsCalculator.formatDuration(elapsedTime)
    }

    var formattedPace: String {
        currentPace
    }

    var formattedDistance: String {
        String(format: "%.2f", distanceKm)
    }

    var formattedElevation: String {
        String(format: "+%.0f m", elevationGainM)
    }

    var formattedTotalTime: String {
        RunStatisticsCalculator.formatDuration(elapsedTime + pausedDuration)
    }

    // MARK: - Timer

    private func startTimer() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(AppConfiguration.RunTracking.timerInterval))
                guard !Task.isCancelled else { break }
                self?.elapsedTime += AppConfiguration.RunTracking.timerInterval
                self?.checkNutritionReminders()
            }
        }
    }

    // MARK: - Location

    private func startLocationTracking() {
        let stream = locationService.startTracking()
        locationTask = Task { [weak self] in
            for await location in stream {
                guard !Task.isCancelled else { break }
                self?.processLocation(location)
            }
        }
    }

    private func processLocation(_ location: CLLocation) {
        if runState == .paused && isAutoPaused {
            handleAutoResume(speed: location.speed)
            return
        }

        guard runState == .running else { return }

        let point = TrackPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitudeM: location.altitude,
            timestamp: location.timestamp,
            heartRate: currentHeartRate
        )

        trackPoints.append(point)
        routeCoordinates.append(location.coordinate)

        distanceKm = RunStatisticsCalculator.totalDistanceKm(trackPoints)
        let elevation = RunStatisticsCalculator.elevationChanges(trackPoints)
        elevationGainM = elevation.gainM
        elevationLossM = elevation.lossM

        if distanceKm > 0 {
            let pace = RunStatisticsCalculator.averagePace(
                distanceKm: distanceKm, duration: elapsedTime
            )
            currentPace = RunStatisticsCalculator.formatPace(pace)
        }

        handleAutoPause(speed: location.speed)
    }

    // MARK: - Heart Rate

    private func startHeartRateStreaming() {
        let stream = healthKitService.startHeartRateStream()
        heartRateTask = Task { [weak self] in
            for await reading in stream {
                guard !Task.isCancelled else { break }
                self?.currentHeartRate = reading.beatsPerMinute
            }
        }
    }

    // MARK: - Nutrition Reminders

    func dismissReminder() {
        guard let current = activeReminder,
              let index = nutritionReminders.firstIndex(where: { $0.id == current.id }) else {
            return
        }
        nutritionReminders[index].isDismissed = true
        activeReminder = nil
    }

    private func loadNutritionReminders() {
        guard nutritionRemindersEnabled else { return }

        Task { [weak self] in
            guard let self else { return }
            do {
                let plan = try await self.nutritionRepository.getNutritionPlan(for: self.raceId ?? UUID())
                let isGutTraining = plan?.gutTrainingSessionIds.contains(
                    self.linkedSession?.id ?? UUID()
                ) ?? false

                if isGutTraining, let plan {
                    self.nutritionReminders = NutritionReminderScheduler.buildGutTrainingSchedule(from: plan)
                } else {
                    self.nutritionReminders = NutritionReminderScheduler.buildDefaultSchedule()
                }
                Logger.nutrition.info("Loaded \(self.nutritionReminders.count) nutrition reminders")
            } catch {
                self.nutritionReminders = NutritionReminderScheduler.buildDefaultSchedule()
                Logger.nutrition.error("Failed to load nutrition plan, using defaults: \(error)")
            }
        }
    }

    private func checkNutritionReminders() {
        guard activeReminder == nil, !nutritionReminders.isEmpty else { return }
        if let next = NutritionReminderScheduler.nextDueReminder(
            in: nutritionReminders, at: elapsedTime
        ) {
            activeReminder = next
            if nutritionAlertSoundEnabled {
                hapticService.playNutritionAlert()
            }
        }
    }

    // MARK: - Auto Pause

    private func handleAutoPause(speed: CLLocationSpeed) {
        guard autoPauseEnabled, runState == .running else { return }

        if speed < AppConfiguration.RunTracking.autoPauseSpeedThreshold && speed >= 0 {
            autoPauseTimer += AppConfiguration.RunTracking.timerInterval
            if autoPauseTimer >= AppConfiguration.RunTracking.autoPauseDelay {
                pauseRun(auto: true)
                autoPauseTimer = 0
            }
        } else {
            autoPauseTimer = 0
        }
    }

    private func handleAutoResume(speed: CLLocationSpeed) {
        if speed >= AppConfiguration.RunTracking.autoResumeSpeedThreshold {
            resumeRun()
            Logger.tracking.info("Auto-resumed at speed \(speed) m/s")
        }
    }
}
