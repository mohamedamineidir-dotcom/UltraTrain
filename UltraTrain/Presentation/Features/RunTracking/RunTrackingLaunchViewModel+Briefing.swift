import Foundation
import os

// MARK: - Weather, Briefing & Estimate Recalculation

extension RunTrackingLaunchViewModel {

    // MARK: - Weather

    func loadWeather() async {
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

    // MARK: - Estimate Recalculation

    func recalculateEstimateIfNeeded() async {
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

    func loadCheckpointSplits(raceId: UUID) async {
        do {
            let estimate = try await finishEstimateRepository.getEstimate(for: raceId)
            raceCheckpointSplits = estimate?.checkpointSplits
        } catch {
            Logger.tracking.debug("Could not load checkpoint splits: \(error)")
        }
    }

    // MARK: - Pre-Run Briefing

    func loadPreRunBriefing() async {
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
