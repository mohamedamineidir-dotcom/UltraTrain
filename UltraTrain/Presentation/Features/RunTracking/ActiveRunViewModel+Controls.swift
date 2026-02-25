import Foundation
import os

// MARK: - Controls & Save

extension ActiveRunViewModel {

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
        Task { await safetyHandler?.start() }
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
        safetyHandler?.stop()
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
            weatherAtStart: weatherAtStart, rpe: rpe, perceivedFeeling: feeling, terrainType: terrain,
            intervalSplits: intervalHandler.intervalSplits
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
}
