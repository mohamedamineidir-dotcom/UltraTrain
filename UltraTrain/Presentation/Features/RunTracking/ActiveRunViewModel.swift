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
    private let hapticService: any HapticServiceProtocol
    private let widgetDataWriter: WidgetDataWriter
    private let gearRepository: any GearRepository
    private let weatherService: (any WeatherServiceProtocol)?

    // MARK: - Handlers

    let nutritionHandler: NutritionReminderHandler
    let racePacingHandler: RacePacingHandler
    let connectivityHandler: ConnectivityHandler
    let voiceCoachingHandler: VoiceCoachingHandler

    // MARK: - Config

    let athlete: Athlete
    let linkedSession: TrainingSession?
    let autoPauseEnabled: Bool
    let raceId: UUID?
    let saveToHealthEnabled: Bool
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
    var autoMatchedSession: SessionMatcher.MatchResult?
    private(set) var weatherAtStart: WeatherSnapshot?

    // MARK: - HR Zone State

    var liveZoneState: LiveHRZoneTracker.LiveZoneState?
    var activeDriftAlert: ZoneDriftAlertCalculator.ZoneDriftAlert?
    private var lastDriftAlertDismissTime: Date?

    // MARK: - Private

    private var timerTask: Task<Void, Never>?
    private var locationTask: Task<Void, Never>?
    private var heartRateTask: Task<Void, Never>?
    private var autoPauseTimer: TimeInterval = 0
    private var pauseStartTime: Date?
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
        finishEstimateRepository: any FinishEstimateRepository,
        weatherService: (any WeatherServiceProtocol)? = nil,
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
        saveToHealthEnabled: Bool = false,
        pacingAlertsEnabled: Bool = true,
        raceId: UUID?,
        selectedGearIds: [UUID] = [],
        voiceCoachingService: (any VoiceCoachingServiceProtocol)? = nil,
        voiceCoachingConfig: VoiceCoachingConfig = VoiceCoachingConfig()
    ) {
        self.locationService = locationService
        self.healthKitService = healthKitService
        self.runRepository = runRepository
        self.planRepository = planRepository
        self.raceRepository = raceRepository
        self.hapticService = hapticService
        self.widgetDataWriter = widgetDataWriter ?? WidgetDataWriter(
            planRepository: planRepository,
            runRepository: runRepository,
            raceRepository: raceRepository
        )
        self.gearRepository = gearRepository
        self.weatherService = weatherService
        self.athlete = athlete
        self.linkedSession = linkedSession
        self.autoPauseEnabled = autoPauseEnabled
        self.raceId = raceId
        self.saveToHealthEnabled = saveToHealthEnabled
        self.selectedGearIds = selectedGearIds

        self.nutritionHandler = NutritionReminderHandler(
            nutritionRepository: nutritionRepository,
            hapticService: hapticService,
            isEnabled: nutritionRemindersEnabled,
            alertSoundEnabled: nutritionAlertSoundEnabled,
            hydrationInterval: hydrationIntervalSeconds,
            fuelInterval: fuelIntervalSeconds,
            electrolyteInterval: electrolyteIntervalSeconds,
            smartRemindersEnabled: smartRemindersEnabled
        )

        self.racePacingHandler = RacePacingHandler(
            raceRepository: raceRepository,
            runRepository: runRepository,
            finishEstimateRepository: finishEstimateRepository,
            hapticService: hapticService,
            athlete: athlete,
            pacingAlertsEnabled: pacingAlertsEnabled
        )

        self.connectivityHandler = ConnectivityHandler(
            connectivityService: connectivityService,
            liveActivityService: liveActivityService,
            stravaUploadQueueService: stravaUploadQueueService,
            stravaAutoUploadEnabled: stravaAutoUploadEnabled
        )

        self.voiceCoachingHandler = VoiceCoachingHandler(
            voiceService: voiceCoachingService ?? VoiceCoachingService(speechRate: voiceCoachingConfig.speechRate),
            config: voiceCoachingConfig
        )
    }

    // MARK: - Controls

    func startRun() {
        runState = .running
        nutritionHandler.loadReminders(raceId: raceId, linkedSessionId: linkedSession?.id)
        nutritionHandler.loadFavoriteProducts()
        if let raceId { racePacingHandler.loadRace(raceId: raceId) }
        connectivityHandler.setupCommandHandler(
            onPause: { [weak self] in self?.pauseRun() },
            onResume: { [weak self] in self?.resumeRun() },
            onStop: { [weak self] in self?.stopRun() },
            onDismissReminder: { [weak self] in self?.nutritionHandler.dismiss(elapsedTime: self?.elapsedTime ?? 0) }
        )
        captureWeatherAtStart()
        hapticService.prepareHaptics()
        startTimer()
        startLocationTracking()
        startHeartRateStreaming()
        connectivityHandler.sendWatchUpdate(snapshot: buildSnapshot())
        connectivityHandler.startLiveActivity(snapshot: buildSnapshot())
        voiceCoachingHandler.announceRunState(.runStarted)
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
        connectivityHandler.updateLiveActivityImmediately(snapshot: buildSnapshot())
        voiceCoachingHandler.announceRunState(auto ? .autoPaused : .runPaused)
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
        if wasManuallyPaused { locationService.resumeTracking() }
        hapticService.playSelection()
        connectivityHandler.updateLiveActivityImmediately(snapshot: buildSnapshot())
        voiceCoachingHandler.announceRunState(.runResumed)
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
        connectivityHandler.sendWatchUpdate(snapshot: buildSnapshot())
        connectivityHandler.endLiveActivity(snapshot: buildSnapshot())
        voiceCoachingHandler.stopSpeaking()
        showSummary = true
        Logger.tracking.info("Run stopped — \(self.distanceKm) km in \(self.elapsedTime)s")
    }

    // MARK: - Save

    func saveRun(notes: String?, rpe: Int? = nil, feeling: PerceivedFeeling? = nil, terrain: TerrainType? = nil) async {
        isSaving = true
        let splits = RunStatisticsCalculator.buildSplits(from: trackPoints)
        let heartRates = trackPoints.compactMap(\.heartRate)
        let avgHR = heartRates.isEmpty ? nil : heartRates.reduce(0, +) / heartRates.count
        let maxHR = heartRates.max()
        let pace = RunStatisticsCalculator.averagePace(distanceKm: distanceKm, duration: elapsedTime)

        var run = CompletedRun(
            id: UUID(), athleteId: athlete.id, date: Date.now,
            distanceKm: distanceKm, elevationGainM: elevationGainM, elevationLossM: elevationLossM,
            duration: elapsedTime, averageHeartRate: avgHR, maxHeartRate: maxHR,
            averagePaceSecondsPerKm: pace, gpsTrack: trackPoints, splits: splits,
            linkedSessionId: linkedSession?.id, linkedRaceId: raceId, notes: notes,
            pausedDuration: pausedDuration, gearIds: selectedGearIds,
            nutritionIntakeLog: nutritionHandler.nutritionIntakeLog,
            weatherAtStart: weatherAtStart, rpe: rpe, perceivedFeeling: feeling, terrainType: terrain
        )
        run.trainingStressScore = TrainingStressCalculator.calculate(
            run: run, maxHeartRate: athlete.maxHeartRate,
            restingHeartRate: athlete.restingHeartRate, customThresholds: athlete.customZoneThresholds
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
            if let raceId { try await linkRunToRace(run: run, raceId: raceId) }
            if !selectedGearIds.isEmpty {
                try await gearRepository.updateGearMileage(
                    gearIds: selectedGearIds, distanceKm: distanceKm, duration: elapsedTime
                )
            }
            lastSavedRun = run
            hapticService.playSuccess()
            Logger.tracking.info("Run saved: \(run.id)")
            await widgetDataWriter.writeAll()
            connectivityHandler.autoUploadToStrava(runId: run.id, hasTrack: !run.gpsTrack.isEmpty)
            await saveWorkoutToHealth(run)
        } catch {
            hapticService.playError()
            self.error = error.localizedDescription
            Logger.tracking.error("Failed to save run: \(error)")
        }
        isSaving = false
    }

    func uploadToStrava() async {
        guard let run = lastSavedRun else { return }
        await connectivityHandler.manualUploadToStrava(runId: run.id)
    }

    func discardRun() {
        Logger.tracking.info("Run discarded")
    }

    // MARK: - Computed

    var formattedTime: String { RunStatisticsCalculator.formatDuration(elapsedTime) }
    var formattedPace: String { currentPace }

    var formattedDistance: String {
        String(format: "%.2f", UnitFormatter.distanceValue(distanceKm, unit: athlete.preferredUnit))
    }

    var formattedElevation: String {
        let value = UnitFormatter.elevationValue(elevationGainM, unit: athlete.preferredUnit)
        return String(format: "+%.0f %@", value, UnitFormatter.elevationShortLabel(athlete.preferredUnit))
    }

    var formattedTotalTime: String { RunStatisticsCalculator.formatDuration(elapsedTime + pausedDuration) }

    var isRaceModeActive: Bool { raceId != nil && racePacingHandler.isActive }

    // MARK: - HR Zone Actions

    func dismissDriftAlert() {
        activeDriftAlert = nil
        lastDriftAlertDismissTime = Date.now
    }

    // MARK: - Private — HR Zone Updates

    private func updateLiveHRZone() {
        guard let hr = currentHeartRate, athlete.maxHeartRate > 0 else { return }
        let targetZone = linkedSession?.targetHeartRateZone
        liveZoneState = LiveHRZoneTracker.update(
            heartRate: hr,
            maxHeartRate: athlete.maxHeartRate,
            customThresholds: athlete.customZoneThresholds,
            targetZone: targetZone,
            previousState: liveZoneState,
            elapsed: elapsedTime
        )

        guard let state = liveZoneState else { return }
        let alert = ZoneDriftAlertCalculator.evaluate(state: state)
        guard let alert else {
            if activeDriftAlert != nil && state.isInTargetZone {
                activeDriftAlert = nil
            }
            return
        }

        let cooldown = AppConfiguration.HRZoneAlerts.alertCooldownSeconds
        if let lastDismiss = lastDriftAlertDismissTime,
           Date.now.timeIntervalSince(lastDismiss) < cooldown {
            return
        }

        if activeDriftAlert?.severity != alert.severity {
            activeDriftAlert = alert
        }
    }

    // MARK: - Private — Timer

    private func startTimer() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(AppConfiguration.RunTracking.timerInterval))
                guard !Task.isCancelled, let self else { break }
                self.elapsedTime += AppConfiguration.RunTracking.timerInterval
                self.updateLiveHRZone()
                let context = self.buildNutritionContext()
                self.nutritionHandler.tick(context: context)
                let pacingContext = self.buildPacingContext()
                self.racePacingHandler.checkPacingAlert(context: pacingContext, linkedSession: self.linkedSession)
                self.voiceCoachingHandler.tick(snapshot: self.buildVoiceSnapshot())
                self.connectivityHandler.sendWatchUpdate(snapshot: self.buildSnapshot())
                self.connectivityHandler.updateLiveActivityIfNeeded(snapshot: self.buildSnapshot())
            }
        }
    }

    // MARK: - Private — Location

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
            let pace = RunStatisticsCalculator.averagePace(distanceKm: distanceKm, duration: elapsedTime)
            currentPace = RunStatisticsCalculator.formatPace(pace, unit: athlete.preferredUnit)
            runningAveragePace = pace
        }

        racePacingHandler.processLocation(context: buildPacingContext())
        handleAutoPause(speed: location.speed)
    }

    // MARK: - Private — Heart Rate

    private func startHeartRateStreaming() {
        let stream = healthKitService.startHeartRateStream()
        heartRateTask = Task { [weak self] in
            for await reading in stream {
                guard !Task.isCancelled else { break }
                self?.currentHeartRate = reading.beatsPerMinute
            }
        }
    }

    // MARK: - Private — Auto Pause

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

    // MARK: - Private — Helpers

    private func autoMatchSession(run: CompletedRun) async {
        do {
            guard let plan = try await planRepository.getActivePlan() else { return }
            let allSessions = plan.weeks.flatMap(\.sessions)
            guard let match = SessionMatcher.findMatch(
                runDate: run.date, distanceKm: run.distanceKm,
                duration: run.duration, candidates: allSessions
            ) else { return }
            var updated = match.session
            updated.isCompleted = true
            updated.linkedRunId = run.id
            try await planRepository.updateSession(updated)
            try await runRepository.updateLinkedSession(runId: run.id, sessionId: match.session.id)
            autoMatchedSession = match
            Logger.tracking.info("Auto-matched run to session \(match.session.id)")
        } catch {
            Logger.tracking.debug("Auto-match failed: \(error)")
        }
    }

    private func linkRunToRace(run: CompletedRun, raceId: UUID) async throws {
        guard var race = try await raceRepository.getRace(id: raceId) else { return }
        race.actualFinishTime = run.duration
        race.linkedRunId = run.id
        try await raceRepository.updateRace(race)
        Logger.tracking.info("Linked run \(run.id) to race \(race.name)")
    }

    private func captureWeatherAtStart() {
        guard let weatherService else { return }
        Task { [weak self] in
            guard let location = self?.locationService.currentLocation else { return }
            do {
                let weather = try await weatherService.currentWeather(
                    latitude: location.coordinate.latitude, longitude: location.coordinate.longitude
                )
                self?.weatherAtStart = weather
                Logger.weather.info("Captured weather at run start: \(weather.condition.displayName) \(Int(weather.temperatureCelsius))°C")
            } catch {
                Logger.weather.debug("Could not capture weather at run start: \(error)")
            }
        }
    }

    private func saveWorkoutToHealth(_ run: CompletedRun) async {
        guard saveToHealthEnabled else { return }
        do {
            try await healthKitService.saveWorkout(run: run)
            Logger.healthKit.info("Workout saved to Apple Health for run \(run.id)")
        } catch {
            Logger.healthKit.error("Failed to save workout to Apple Health: \(error)")
        }
    }

    // MARK: - Context Builders

    private func buildNutritionContext() -> NutritionReminderHandler.RunContext {
        NutritionReminderHandler.RunContext(
            elapsedTime: elapsedTime, distanceKm: distanceKm,
            currentHeartRate: currentHeartRate, maxHeartRate: athlete.maxHeartRate,
            runningAveragePace: runningAveragePace
        )
    }

    private func buildPacingContext() -> RacePacingHandler.RunContext {
        RacePacingHandler.RunContext(
            distanceKm: distanceKm, elapsedTime: elapsedTime,
            runningAveragePace: runningAveragePace, trackPoints: trackPoints
        )
    }

    private func buildSnapshot() -> ConnectivityHandler.RunSnapshot {
        ConnectivityHandler.RunSnapshot(
            runState: runState, elapsedTime: elapsedTime, distanceKm: distanceKm,
            currentPace: currentPace, currentHeartRate: currentHeartRate,
            elevationGainM: elevationGainM, formattedTime: formattedTime,
            formattedDistance: formattedDistance, formattedElevation: formattedElevation,
            isAutoPaused: isAutoPaused,
            activeReminderMessage: nutritionHandler.activeReminder?.message,
            activeReminderType: nutritionHandler.activeReminder?.type.rawValue,
            linkedSessionName: linkedSession?.description
        )
    }

    private func buildVoiceSnapshot() -> VoiceCueBuilder.RunSnapshot {
        VoiceCueBuilder.RunSnapshot(
            distanceKm: distanceKm,
            elapsedTime: elapsedTime,
            currentPace: runningAveragePace > 0 ? runningAveragePace : nil,
            elevationGainM: elevationGainM,
            currentHeartRate: currentHeartRate,
            currentZoneName: liveZoneState?.currentZoneName,
            previousZoneName: nil,
            isMetric: athlete.preferredUnit == .metric
        )
    }
}
