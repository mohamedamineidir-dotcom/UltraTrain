import Foundation
import os

// MARK: - Weather, Recovery, Challenges, Goals

extension DashboardViewModel {

    // MARK: - Weather

    func loadWeather() async {
        guard let weatherService, let locationService else { return }
        guard let location = locationService.currentLocation else { return }
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        do {
            currentWeather = try await weatherService.currentWeather(latitude: lat, longitude: lon)
        } catch {
            Logger.weather.debug("Dashboard: could not load current weather: \(error)")
        }

        guard let session = nextSession,
              abs(session.date.timeIntervalSinceNow) < Double(AppConfiguration.Weather.sessionForecastHoursAhead) * 3600 else {
            return
        }

        do {
            let hours = max(1, Int(session.date.timeIntervalSinceNow / 3600) + 1)
            let forecast = try await weatherService.hourlyForecast(latitude: lat, longitude: lon, hours: hours)
            sessionForecast = forecast.last
        } catch {
            Logger.weather.debug("Dashboard: could not load session forecast: \(error)")
        }
    }

    // MARK: - Recovery

    func loadRecovery() async {
        do {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date.now) ?? Date.now
            let sleepEntries = try await healthKitService.fetchSleepData(from: yesterday, to: .now)
            let lastNight = sleepEntries.last

            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date.now) ?? Date.now
            let history = try await healthKitService.fetchSleepData(from: sevenDaysAgo, to: .now)
            sleepHistory = history

            let currentHR = try await healthKitService.fetchRestingHeartRate()
            let athlete = try await athleteRepository.getAthlete()
            let baselineHR = athlete?.restingHeartRate

            // Fetch HRV data
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date.now) ?? Date.now
            let hrvReadings = try await healthKitService.fetchHRVData(from: thirtyDaysAgo, to: .now)
            let computedHRVTrend = HRVAnalyzer.analyze(readings: hrvReadings)
            hrvTrend = computedHRVTrend

            let computedHRVScore: Int?
            if let trend = computedHRVTrend {
                computedHRVScore = HRVAnalyzer.hrvScore(trend: trend)
            } else {
                computedHRVScore = nil
            }

            let score = RecoveryScoreCalculator.calculate(
                lastNightSleep: lastNight,
                sleepHistory: history,
                currentRestingHR: currentHR,
                baselineRestingHR: baselineHR,
                fitnessSnapshot: fitnessSnapshot,
                hrvScore: computedHRVScore
            )
            recoveryScore = score

            // Compute readiness score
            if let trend = computedHRVTrend {
                readinessScore = ReadinessCalculator.calculate(
                    recoveryScore: score,
                    hrvTrend: trend,
                    fitnessSnapshot: fitnessSnapshot
                )
            }

            let latestHRV = hrvReadings.sorted(by: { $0.date > $1.date }).first
            let snapshot = RecoverySnapshot(
                id: UUID(),
                date: .now,
                recoveryScore: score,
                sleepEntry: lastNight,
                restingHeartRate: currentHR,
                hrvReading: latestHRV,
                readinessScore: readinessScore
            )
            try await recoveryRepository.saveSnapshot(snapshot)
        } catch {
            Logger.recovery.debug("Dashboard: could not load recovery data: \(error)")
            let score = RecoveryScoreCalculator.calculate(
                lastNightSleep: nil,
                sleepHistory: [],
                currentRestingHR: nil,
                baselineRestingHR: nil,
                fitnessSnapshot: fitnessSnapshot
            )
            recoveryScore = score
        }
    }

    // MARK: - Challenges

    func loadChallenges() async {
        guard let challengeRepository else { return }
        do {
            let athlete = try await athleteRepository.getAthlete()
            guard let athlete else { return }
            let runs = try await runRepository.getRuns(for: athlete.id)
            currentStreak = ChallengeProgressCalculator.computeCurrentStreak(from: runs)

            let enrollments = try await challengeRepository.getActiveEnrollments()
            var nearest: ChallengeProgressCalculator.ChallengeProgress?
            for enrollment in enrollments {
                guard let definition = ChallengeLibrary.definition(for: enrollment.challengeDefinitionId) else {
                    continue
                }
                let progress = ChallengeProgressCalculator.computeProgress(
                    enrollment: enrollment, definition: definition, runs: runs
                )
                if !progress.isComplete {
                    if nearest == nil || progress.progressFraction > nearest!.progressFraction {
                        nearest = progress
                    }
                }
            }
            nearestChallengeProgress = nearest
        } catch {
            Logger.challenges.debug("Dashboard: could not load challenges: \(error)")
        }
    }

    // MARK: - Goals

    func loadGoals() async {
        guard let goalRepository else { return }
        do {
            let athlete = try await athleteRepository.getAthlete()
            guard let athlete else { return }
            let runs = try await runRepository.getRuns(for: athlete.id)

            if let weeklyGoal = try await goalRepository.getActiveGoal(period: .weekly) {
                weeklyGoalProgress = GoalProgressCalculator.calculate(goal: weeklyGoal, runs: runs)
            }

            if let monthlyGoal = try await goalRepository.getActiveGoal(period: .monthly) {
                monthlyGoalProgress = GoalProgressCalculator.calculate(goal: monthlyGoal, runs: runs)
            }
        } catch {
            Logger.training.debug("Dashboard: could not load goals: \(error)")
        }
    }
}
