import ActivityKit
import CoreLocation
import Foundation
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
    private let raceRepository: any RaceRepository
    private let nutritionRepository: any NutritionRepository
    private let hapticService: any HapticServiceProtocol
    private let connectivityService: PhoneConnectivityService?
    private let liveActivityService: any LiveActivityServiceProtocol
    private let widgetDataWriter: WidgetDataWriter
    private let stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)?
    private let gearRepository: any GearRepository

    // MARK: - Config

    let athlete: Athlete
    let linkedSession: TrainingSession?
    let autoPauseEnabled: Bool
    let nutritionRemindersEnabled: Bool
    let nutritionAlertSoundEnabled: Bool
    let hydrationIntervalSeconds: TimeInterval
    let fuelIntervalSeconds: TimeInterval
    let electrolyteIntervalSeconds: TimeInterval
    let smartRemindersEnabled: Bool
    let raceId: UUID?
    let stravaAutoUploadEnabled: Bool
    let selectedGearIds: [UUID]

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
    var lastSavedRun: CompletedRun?
    var isAutoPaused = false
    var nutritionReminders: [NutritionReminder] = []
    var activeReminder: NutritionReminder?
    var resolvedCheckpointLocations: [(checkpoint: Checkpoint, coordinate: CLLocationCoordinate2D)] = []
    var stravaUploadStatus: StravaUploadStatus = .idle
    var nutritionIntakeLog: [NutritionIntakeEntry] = []
    var autoMatchedSession: SessionMatcher.MatchResult?

    // MARK: - Private

    private var timerTask: Task<Void, Never>?
    private var locationTask: Task<Void, Never>?
    private var heartRateTask: Task<Void, Never>?
    private var raceCheckpoints: [Checkpoint] = []
    private var lastCheckpointResolveKm: Int = 0
    private var autoPauseTimer: TimeInterval = 0
    private var pauseStartTime: Date?
    private var lastLiveActivityUpdate: TimeInterval = 0
    private var lastReminderShownTime: [NutritionReminderType: TimeInterval] = [:]
    private var runningAveragePace: Double = 0

    // MARK: - Init

    init(
        locationService: LocationService,
        healthKitService: any HealthKitServiceProtocol,
        runRepository: any RunRepository,
        planRepository: any TrainingPlanRepository,
        raceRepository: any RaceRepository,
        nutritionRepository: any NutritionRepository,
        hapticService: any HapticServiceProtocol,
        connectivityService: PhoneConnectivityService? = nil,
        liveActivityService: any LiveActivityServiceProtocol = LiveActivityService(),
        widgetDataWriter: WidgetDataWriter? = nil,
        stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)? = nil,
        gearRepository: any GearRepository,
        athlete: Athlete,
        linkedSession: TrainingSession?,
        autoPauseEnabled: Bool,
        nutritionRemindersEnabled: Bool,
        nutritionAlertSoundEnabled: Bool,
        hydrationIntervalSeconds: TimeInterval = 1200,
        fuelIntervalSeconds: TimeInterval = 2700,
        electrolyteIntervalSeconds: TimeInterval = 0,
        smartRemindersEnabled: Bool = false,
        stravaAutoUploadEnabled: Bool = false,
        raceId: UUID?,
        selectedGearIds: [UUID] = []
    ) {
        self.locationService = locationService
        self.healthKitService = healthKitService
        self.runRepository = runRepository
        self.planRepository = planRepository
        self.raceRepository = raceRepository
        self.nutritionRepository = nutritionRepository
        self.hapticService = hapticService
        self.connectivityService = connectivityService
        self.liveActivityService = liveActivityService
        self.widgetDataWriter = widgetDataWriter ?? WidgetDataWriter(
            planRepository: planRepository,
            runRepository: runRepository,
            raceRepository: raceRepository
        )
        self.stravaUploadQueueService = stravaUploadQueueService
        self.gearRepository = gearRepository
        self.athlete = athlete
        self.linkedSession = linkedSession
        self.autoPauseEnabled = autoPauseEnabled
        self.nutritionRemindersEnabled = nutritionRemindersEnabled
        self.nutritionAlertSoundEnabled = nutritionAlertSoundEnabled
        self.hydrationIntervalSeconds = hydrationIntervalSeconds
        self.fuelIntervalSeconds = fuelIntervalSeconds
        self.electrolyteIntervalSeconds = electrolyteIntervalSeconds
        self.smartRemindersEnabled = smartRemindersEnabled
        self.stravaAutoUploadEnabled = stravaAutoUploadEnabled
        self.raceId = raceId
        self.selectedGearIds = selectedGearIds
    }

    // MARK: - Controls

    func startRun() {
        runState = .running
        loadNutritionReminders()
        loadRaceCheckpoints()
        setupWatchCommandHandler()
        if nutritionAlertSoundEnabled { hapticService.prepareHaptics() }
        startTimer()
        startLocationTracking()
        startHeartRateStreaming()
        sendWatchUpdate()
        startLiveActivity()
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
            hapticService.playSelection()
        }
        updateLiveActivityImmediately()
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
        hapticService.playSelection()
        updateLiveActivityImmediately()
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
        sendWatchUpdate()
        endLiveActivity()
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
            linkedRaceId: raceId,
            notes: notes,
            pausedDuration: pausedDuration,
            gearIds: selectedGearIds,
            nutritionIntakeLog: nutritionIntakeLog
        )

        do {
            try await runRepository.saveRun(run)
            if let session = linkedSession {
                var updated = session
                updated.isCompleted = true
                updated.linkedRunId = run.id
                try await planRepository.updateSession(updated)
            } else {
                await autoMatchSession(run: run)
            }
            if let raceId {
                try await linkRunToRace(run: run, raceId: raceId)
            }
            if !selectedGearIds.isEmpty {
                try await gearRepository.updateGearMileage(
                    gearIds: selectedGearIds,
                    distanceKm: distanceKm,
                    duration: elapsedTime
                )
            }
            lastSavedRun = run
            hapticService.playSuccess()
            Logger.tracking.info("Run saved: \(run.id)")
            await widgetDataWriter.writeAll()
            autoUploadToStrava(run)
        } catch {
            hapticService.playError()
            self.error = error.localizedDescription
            Logger.tracking.error("Failed to save run: \(error)")
        }
        isSaving = false
    }

    func uploadToStrava() {
        guard let run = lastSavedRun, let queueService = stravaUploadQueueService else { return }
        stravaUploadStatus = .uploading
        Task { [weak self] in
            do {
                try await queueService.enqueueUpload(runId: run.id)
                await queueService.processQueue()
                if let status = await queueService.getQueueStatus(forRunId: run.id),
                   status == .completed {
                    self?.stravaUploadStatus = .success(activityId: 0)
                } else {
                    self?.stravaUploadStatus = .idle
                }
            } catch {
                self?.stravaUploadStatus = .failed(reason: error.localizedDescription)
                Logger.strava.error("Strava upload failed: \(error)")
            }
        }
    }

    func discardRun() {
        Logger.tracking.info("Run discarded")
    }

    // MARK: - Auto-Match Session

    private func autoMatchSession(run: CompletedRun) async {
        do {
            guard let plan = try await planRepository.getActivePlan() else { return }
            let allSessions = plan.weeks.flatMap(\.sessions)
            guard let match = SessionMatcher.findMatch(
                runDate: run.date,
                distanceKm: run.distanceKm,
                duration: run.duration,
                candidates: allSessions
            ) else { return }

            var updated = match.session
            updated.isCompleted = true
            updated.linkedRunId = run.id
            try await planRepository.updateSession(updated)
            try await runRepository.updateLinkedSession(runId: run.id, sessionId: match.session.id)
            autoMatchedSession = match
            Logger.tracking.info("Auto-matched run to session \(match.session.id) (confidence: \(match.confidence))")
        } catch {
            Logger.tracking.debug("Auto-match failed: \(error)")
        }
    }

    // MARK: - Strava Auto-Upload

    private func autoUploadToStrava(_ run: CompletedRun) {
        guard stravaAutoUploadEnabled,
              let queueService = stravaUploadQueueService,
              !run.gpsTrack.isEmpty else { return }
        stravaUploadStatus = .uploading
        Task { [weak self] in
            do {
                try await queueService.enqueueUpload(runId: run.id)
                await queueService.processQueue()
                if let status = await queueService.getQueueStatus(forRunId: run.id),
                   status == .completed {
                    self?.stravaUploadStatus = .success(activityId: 0)
                } else {
                    self?.stravaUploadStatus = .idle
                }
                Logger.strava.info("Auto-upload queued for run \(run.id)")
            } catch {
                self?.stravaUploadStatus = .failed(reason: error.localizedDescription)
                Logger.strava.error("Auto-upload to Strava failed: \(error)")
            }
        }
    }

    // MARK: - Computed

    var formattedTime: String {
        RunStatisticsCalculator.formatDuration(elapsedTime)
    }

    var formattedPace: String {
        currentPace
    }

    var formattedDistance: String {
        String(format: "%.2f", UnitFormatter.distanceValue(distanceKm, unit: athlete.preferredUnit))
    }

    var formattedElevation: String {
        let value = UnitFormatter.elevationValue(elevationGainM, unit: athlete.preferredUnit)
        return String(format: "+%.0f %@", value, UnitFormatter.elevationShortLabel(athlete.preferredUnit))
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
                self?.sendWatchUpdate()
                self?.updateLiveActivityIfNeeded()
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
        let elevation = ElevationCalculator.elevationChanges(trackPoints)
        elevationGainM = elevation.gainM
        elevationLossM = elevation.lossM

        if distanceKm > 0 {
            let pace = RunStatisticsCalculator.averagePace(
                distanceKm: distanceKm, duration: elapsedTime
            )
            currentPace = RunStatisticsCalculator.formatPace(pace, unit: athlete.preferredUnit)
            runningAveragePace = pace
        }

        updateCheckpointLocations()
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
        guard let current = activeReminder else { return }
        logIntakeEntry(for: current, status: .pending)
        markReminderDismissed(current)
    }

    func markReminderTaken() {
        guard let current = activeReminder else { return }
        logIntakeEntry(for: current, status: .taken)
        markReminderDismissed(current)
    }

    func markReminderSkipped() {
        guard let current = activeReminder else { return }
        logIntakeEntry(for: current, status: .skipped)
        markReminderDismissed(current)
    }

    var nutritionSummary: NutritionIntakeSummary {
        NutritionIntakeSummary(entries: nutritionIntakeLog)
    }

    private func logIntakeEntry(for reminder: NutritionReminder, status: NutritionIntakeStatus) {
        let entry = NutritionIntakeEntry(
            reminderType: reminder.type,
            status: status,
            elapsedTimeSeconds: elapsedTime,
            message: reminder.message
        )
        nutritionIntakeLog.append(entry)
    }

    private func markReminderDismissed(_ reminder: NutritionReminder) {
        if let index = nutritionReminders.firstIndex(where: { $0.id == reminder.id }) {
            nutritionReminders[index].isDismissed = true
        }
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
                    self.nutritionReminders = NutritionReminderScheduler.buildDefaultSchedule(
                        hydrationIntervalSeconds: self.hydrationIntervalSeconds,
                        fuelIntervalSeconds: self.fuelIntervalSeconds,
                        electrolyteIntervalSeconds: self.electrolyteIntervalSeconds
                    )
                }
                Logger.nutrition.info("Loaded \(self.nutritionReminders.count) nutrition reminders")
            } catch {
                self.nutritionReminders = NutritionReminderScheduler.buildDefaultSchedule(
                    hydrationIntervalSeconds: self.hydrationIntervalSeconds,
                    fuelIntervalSeconds: self.fuelIntervalSeconds,
                    electrolyteIntervalSeconds: self.electrolyteIntervalSeconds
                )
                Logger.nutrition.error("Failed to load nutrition plan, using defaults: \(error)")
            }
        }
    }

    private func checkNutritionReminders() {
        guard activeReminder == nil, !nutritionReminders.isEmpty else { return }
        if let next = NutritionReminderScheduler.nextDueReminder(
            in: nutritionReminders, at: elapsedTime
        ) {
            if smartRemindersEnabled {
                let adjustedTime = adjustedTriggerTime(for: next)
                guard elapsedTime >= adjustedTime else { return }
            }
            activeReminder = next
            lastReminderShownTime[next.type] = elapsedTime
            if nutritionAlertSoundEnabled {
                hapticService.playNutritionAlert()
            }
        }
    }

    private func adjustedTriggerTime(for reminder: NutritionReminder) -> TimeInterval {
        let conditions = AdaptiveReminderAdjuster.RunConditions(
            currentHeartRate: currentHeartRate,
            maxHeartRate: athlete.maxHeartRate,
            elapsedDistanceKm: distanceKm,
            currentPaceSecondsPerKm: currentPaceValue(),
            averagePaceSecondsPerKm: runningAveragePace > 0 ? runningAveragePace : nil
        )
        let multiplier = AdaptiveReminderAdjuster.intervalMultiplier(
            for: reminder.type, conditions: conditions
        )
        let baseInterval = reminder.triggerTimeSeconds - (lastReminderShownTime[reminder.type] ?? 0)
        let adjustedInterval = baseInterval * multiplier
        return (lastReminderShownTime[reminder.type] ?? 0) + adjustedInterval
    }

    private func currentPaceValue() -> Double? {
        guard distanceKm > 0 else { return nil }
        return elapsedTime / distanceKm
    }

    // MARK: - Race Checkpoints

    private func loadRaceCheckpoints() {
        guard let raceId else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                if let race = try await self.raceRepository.getRace(id: raceId) {
                    self.raceCheckpoints = race.checkpoints
                    Logger.tracking.info("Loaded \(race.checkpoints.count) checkpoints for race \(race.name)")
                }
            } catch {
                Logger.tracking.error("Failed to load race checkpoints: \(error)")
            }
        }
    }

    private func updateCheckpointLocations() {
        guard !raceCheckpoints.isEmpty else { return }
        let currentKm = Int(distanceKm)
        guard currentKm > lastCheckpointResolveKm else { return }
        lastCheckpointResolveKm = currentKm
        resolvedCheckpointLocations = CheckpointLocationResolver.resolveLocations(
            checkpoints: raceCheckpoints,
            along: trackPoints
        )
    }

    // MARK: - Race Linking

    private func linkRunToRace(run: CompletedRun, raceId: UUID) async throws {
        guard var race = try await raceRepository.getRace(id: raceId) else { return }
        race.actualFinishTime = run.duration
        race.linkedRunId = run.id
        try await raceRepository.updateRace(race)
        Logger.tracking.info("Linked run \(run.id) to race \(race.name)")
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

    // MARK: - Watch Connectivity

    private func setupWatchCommandHandler() {
        connectivityService?.commandHandler = { [weak self] command in
            guard let self else { return }
            switch command {
            case .pause: self.pauseRun()
            case .resume: self.resumeRun()
            case .stop: self.stopRun()
            case .dismissReminder: self.dismissReminder()
            }
        }
    }

    private func sendWatchUpdate() {
        connectivityService?.sendRunUpdate(buildWatchRunData())
    }

    // MARK: - Live Activity

    private func startLiveActivity() {
        let attributes = RunActivityAttributes(
            startTime: Date.now,
            linkedSessionName: linkedSession?.description
        )
        liveActivityService.startActivity(
            attributes: attributes,
            state: buildLiveActivityState()
        )
    }

    private func updateLiveActivityIfNeeded() {
        let now = elapsedTime
        guard now - lastLiveActivityUpdate >= AppConfiguration.LiveActivity.updateIntervalSeconds else { return }
        lastLiveActivityUpdate = now
        liveActivityService.updateActivity(state: buildLiveActivityState())
    }

    private func updateLiveActivityImmediately() {
        lastLiveActivityUpdate = elapsedTime
        liveActivityService.updateActivity(state: buildLiveActivityState())
    }

    private func endLiveActivity() {
        liveActivityService.endActivity(state: buildLiveActivityState())
    }

    private func buildLiveActivityState() -> RunActivityAttributes.ContentState {
        let stateString: String = switch runState {
        case .notStarted: "notStarted"
        case .running: "running"
        case .paused: isAutoPaused ? "autoPaused" : "paused"
        case .finished: "finished"
        }

        let isPaused = runState == .paused || runState == .finished
        let timerStartDate = isPaused ? Date.now : Date.now.addingTimeInterval(-elapsedTime)

        return RunActivityAttributes.ContentState(
            elapsedTime: elapsedTime,
            distanceKm: distanceKm,
            currentHeartRate: currentHeartRate,
            elevationGainM: elevationGainM,
            runState: stateString,
            isAutoPaused: isAutoPaused,
            formattedDistance: formattedDistance,
            formattedElevation: formattedElevation,
            formattedPace: currentPace,
            timerStartDate: timerStartDate,
            isPaused: isPaused
        )
    }

    private func buildWatchRunData() -> WatchRunData {
        let stateString: String = switch runState {
        case .notStarted: "notStarted"
        case .running: "running"
        case .paused: isAutoPaused ? "autoPaused" : "paused"
        case .finished: "finished"
        }

        return WatchRunData(
            runState: stateString,
            elapsedTime: elapsedTime,
            distanceKm: distanceKm,
            currentPace: currentPace,
            currentHeartRate: currentHeartRate,
            elevationGainM: elevationGainM,
            formattedTime: formattedTime,
            formattedDistance: formattedDistance,
            formattedElevation: formattedElevation,
            isAutoPaused: isAutoPaused,
            activeReminderMessage: activeReminder?.message,
            activeReminderType: activeReminder?.type.rawValue
        )
    }
}
