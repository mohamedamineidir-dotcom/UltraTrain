import CoreLocation
import Foundation
import os

// MARK: - Context Builders, Timer, HR Zone Updates & Safety

extension ActiveRunViewModel {

    // MARK: - HR Zone Actions

    func dismissDriftAlert() {
        activeDriftAlert = nil
        lastDriftAlertDismissTime = Date.now
    }

    // MARK: - HR Zone Updates

    func updateLiveHRZone() {
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

    // MARK: - Widget Commands

    func processWidgetRunCommands() {
        guard let command = WidgetDataReader.readRunCommand() else { return }
        WidgetDataReader.clearRunCommand()
        switch command {
        case "pause":
            if runState == .running { pauseRun() }
        case "resume":
            if runState == .paused { resumeRun() }
        default:
            break
        }
    }

    // MARK: - Timer

    func startTimer() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(AppConfiguration.RunTracking.timerInterval))
                guard !Task.isCancelled, let self else { break }
                self.processWidgetRunCommands()
                self.elapsedTime += AppConfiguration.RunTracking.timerInterval
                self.updateLiveHRZone()
                let context = self.buildNutritionContext()
                self.nutritionHandler.tick(context: context)
                let pacingContext = self.buildPacingContext()
                self.racePacingHandler.checkPacingAlert(context: pacingContext, linkedSession: self.linkedSession)
                self.voiceCoachingHandler.tick(snapshot: self.buildVoiceSnapshot())
                self.intervalHandler.tick(context: self.buildIntervalContext())
                self.safetyHandler?.tick(context: self.buildSafetyContext())
                self.connectivityHandler.sendWatchUpdate(snapshot: self.buildSnapshot())
                self.connectivityHandler.updateLiveActivityIfNeeded(snapshot: self.buildSnapshot())
            }
        }
    }

    // MARK: - Helpers

    func autoMatchSession(run: CompletedRun) async {
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

    func linkRunToRace(run: CompletedRun, raceId: UUID) async throws {
        guard var race = try await raceRepository.getRace(id: raceId) else { return }
        race.actualFinishTime = run.duration
        race.linkedRunId = run.id
        try await raceRepository.updateRace(race)
        Logger.tracking.info("Linked run \(run.id) to race \(race.name)")
    }

    func captureWeatherAtStart() {
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

    func saveWorkoutToHealth(_ run: CompletedRun) async {
        guard saveToHealthEnabled else { return }
        do {
            try await healthKitService.saveWorkout(run: run)
            Logger.healthKit.info("Workout saved to Apple Health for run \(run.id)")
        } catch {
            Logger.healthKit.error("Failed to save workout to Apple Health: \(error)")
        }
    }

    // MARK: - Context Builders

    func buildNutritionContext() -> NutritionReminderHandler.RunContext {
        NutritionReminderHandler.RunContext(
            elapsedTime: elapsedTime, distanceKm: distanceKm,
            currentHeartRate: currentHeartRate, maxHeartRate: athlete.maxHeartRate,
            runningAveragePace: runningAveragePace
        )
    }

    func buildPacingContext() -> RacePacingHandler.RunContext {
        RacePacingHandler.RunContext(
            distanceKm: distanceKm, elapsedTime: elapsedTime,
            runningAveragePace: runningAveragePace, trackPoints: trackPoints
        )
    }

    func buildSnapshot() -> ConnectivityHandler.RunSnapshot {
        let raceModeData = buildRaceModeSnapshotData()

        return ConnectivityHandler.RunSnapshot(
            runState: runState, elapsedTime: elapsedTime, distanceKm: distanceKm,
            currentPace: currentPace, currentHeartRate: currentHeartRate,
            elevationGainM: elevationGainM, formattedTime: formattedTime,
            formattedDistance: formattedDistance, formattedElevation: formattedElevation,
            isAutoPaused: isAutoPaused,
            activeReminderMessage: nutritionHandler.activeReminder?.message,
            activeReminderType: nutritionHandler.activeReminder?.type.rawValue,
            linkedSessionName: linkedSession?.description,
            nextCheckpointName: raceModeData.nextCheckpointName,
            distanceToCheckpointKm: raceModeData.distanceToCheckpointKm,
            projectedFinishTime: raceModeData.projectedFinishTime,
            timeDeltaSeconds: raceModeData.timeDeltaSeconds,
            activeNutritionReminder: nutritionHandler.activeReminder?.message
        )
    }

    func buildRaceModeSnapshotData() -> (
        nextCheckpointName: String?,
        distanceToCheckpointKm: Double?,
        projectedFinishTime: String?,
        timeDeltaSeconds: Double?
    ) {
        guard isRaceModeActive else {
            return (nil, nil, nil, nil)
        }

        let checkpointName = racePacingHandler.nextCheckpoint?.checkpointName
        let distToCheckpoint = racePacingHandler.distanceToNextCheckpointKm(currentDistanceKm: distanceKm)

        var projectedFinishStr: String?
        var timeDelta: Double?

        if let guidance = racePacingHandler.racePacingGuidance {
            projectedFinishStr = RunStatisticsCalculator.formatDuration(guidance.projectedFinishTime)

            switch guidance.projectedFinishScenario {
            case .aheadOfPlan:
                let diff = guidance.segmentTimeBudgetRemaining
                timeDelta = diff > 0 ? diff : nil
            case .behindPlan:
                let diff = guidance.segmentTimeBudgetRemaining
                timeDelta = diff > 0 ? -diff : nil
            case .onPlan:
                timeDelta = 0
            }
        } else {
            let context = buildPacingContext()
            if let projected = racePacingHandler.projectedFinishTime(context: context) {
                projectedFinishStr = RunStatisticsCalculator.formatDuration(projected)
            }
        }

        return (checkpointName, distToCheckpoint, projectedFinishStr, timeDelta)
    }

    func buildIntervalContext() -> IntervalGuidanceHandler.RunContext {
        IntervalGuidanceHandler.RunContext(
            elapsedTime: elapsedTime,
            distanceKm: distanceKm,
            currentHeartRate: currentHeartRate,
            currentPace: runningAveragePace
        )
    }

    func buildVoiceSnapshot() -> VoiceCueBuilder.RunSnapshot {
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

    func buildSafetyContext() -> SafetyHandler.RunContext {
        SafetyHandler.RunContext(
            elapsedTime: elapsedTime,
            distanceKm: distanceKm,
            latitude: trackPoints.last?.latitude,
            longitude: trackPoints.last?.longitude,
            isRunPaused: runState == .paused,
            currentSpeed: lastKnownSpeed
        )
    }

    // MARK: - Safety Actions

    func triggerSOS() {
        safetyHandler?.triggerSOS(context: buildSafetyContext())
    }
}
