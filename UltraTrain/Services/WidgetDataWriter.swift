import Foundation
import os
import WidgetKit

final class WidgetDataWriter: @unchecked Sendable {

    private let planRepository: any TrainingPlanRepository
    private let runRepository: any RunRepository
    private let raceRepository: any RaceRepository
    private let fitnessRepository: (any FitnessRepository)?
    private let connectivityService: PhoneConnectivityService?
    private let defaults: UserDefaults?

    init(
        planRepository: any TrainingPlanRepository,
        runRepository: any RunRepository,
        raceRepository: any RaceRepository,
        fitnessRepository: (any FitnessRepository)? = nil,
        connectivityService: PhoneConnectivityService? = nil,
        defaults: UserDefaults? = UserDefaults(suiteName: WidgetDataKeys.suiteName)
    ) {
        self.planRepository = planRepository
        self.runRepository = runRepository
        self.raceRepository = raceRepository
        self.fitnessRepository = fitnessRepository
        self.connectivityService = connectivityService
        self.defaults = defaults
    }

    func writeAll() async {
        await writeNextSession()
        await writeRaceCountdown()
        await writeWeeklyProgress()
        await writeLastRun()
        await writeFitnessData()
        await sendComplicationDataToWatch()
        reloadWidgets()
    }

    func writeNextSession() async {
        do {
            guard let plan = try await planRepository.getActivePlan() else {
                clear(key: WidgetDataKeys.nextSession)
                return
            }

            let today = Calendar.current.startOfDay(for: .now)
            let session = plan.weeks
                .flatMap(\.sessions)
                .filter { !$0.isCompleted && !$0.isSkipped && $0.type != .rest }
                .filter { $0.date >= today }
                .sorted { $0.date < $1.date }
                .first

            guard let session else {
                clear(key: WidgetDataKeys.nextSession)
                return
            }

            let data = WidgetSessionData(
                sessionId: session.id,
                sessionType: session.type.rawValue,
                sessionIcon: iconName(for: session.type),
                displayName: displayName(for: session.type),
                description: session.description,
                plannedDistanceKm: session.plannedDistanceKm,
                plannedElevationGainM: session.plannedElevationGainM,
                plannedDuration: session.plannedDuration,
                intensity: session.intensity.rawValue,
                date: session.date
            )
            write(data, key: WidgetDataKeys.nextSession)
        } catch {
            Logger.widget.error("Failed to write next session: \(error)")
        }
    }

    func writeRaceCountdown() async {
        do {
            let races = try await raceRepository.getRaces()
            let now = Date.now
            let aRace = races
                .filter { $0.priority == .aRace && $0.date > now }
                .sorted { $0.date < $1.date }
                .first

            guard let aRace else {
                clear(key: WidgetDataKeys.raceCountdown)
                return
            }

            var planCompletion = 0.0
            if let plan = try await planRepository.getActivePlan() {
                let allSessions = plan.weeks.flatMap(\.sessions)
                    .filter { $0.type != .rest }
                let completed = allSessions.filter(\.isCompleted).count
                if !allSessions.isEmpty {
                    planCompletion = Double(completed) / Double(allSessions.count)
                }
            }

            let data = WidgetRaceData(
                name: aRace.name,
                date: aRace.date,
                distanceKm: aRace.distanceKm,
                elevationGainM: aRace.elevationGainM,
                planCompletionPercent: planCompletion
            )
            write(data, key: WidgetDataKeys.raceCountdown)
        } catch {
            Logger.widget.error("Failed to write race countdown: \(error)")
        }
    }

    func writeWeeklyProgress() async {
        do {
            guard let plan = try await planRepository.getActivePlan(),
                  let weekIndex = plan.currentWeekIndex else {
                clear(key: WidgetDataKeys.weeklyProgress)
                return
            }

            let week = plan.weeks[weekIndex]
            let completedSessions = week.sessions.filter(\.isCompleted)

            let actualDistance = completedSessions.reduce(0.0) { $0 + $1.plannedDistanceKm }
            let actualElevation = completedSessions.reduce(0.0) { $0 + $1.plannedElevationGainM }

            let data = WidgetWeeklyProgressData(
                actualDistanceKm: actualDistance,
                targetDistanceKm: week.targetVolumeKm,
                actualElevationGainM: actualElevation,
                targetElevationGainM: week.targetElevationGainM,
                phase: week.phase.rawValue,
                weekNumber: week.weekNumber
            )
            write(data, key: WidgetDataKeys.weeklyProgress)
        } catch {
            Logger.widget.error("Failed to write weekly progress: \(error)")
        }
    }

    func writeLastRun() async {
        do {
            let runs = try await runRepository.getRecentRuns(limit: 1)
            guard let lastRun = runs.first else {
                clear(key: WidgetDataKeys.lastRun)
                return
            }

            let data = WidgetLastRunData(
                date: lastRun.date,
                distanceKm: lastRun.distanceKm,
                elevationGainM: lastRun.elevationGainM,
                duration: lastRun.duration,
                averagePaceSecondsPerKm: lastRun.averagePaceSecondsPerKm,
                averageHeartRate: lastRun.averageHeartRate
            )
            write(data, key: WidgetDataKeys.lastRun)
        } catch {
            Logger.widget.error("Failed to write last run: \(error)")
        }
    }

    func writeFitnessData() async {
        guard let fitnessRepository else {
            clear(key: WidgetDataKeys.fitnessData)
            return
        }

        do {
            guard let snapshot = try await fitnessRepository.getLatestSnapshot() else {
                clear(key: WidgetDataKeys.fitnessData)
                return
            }

            let to = Date.now
            let from = Calendar.current.date(byAdding: .day, value: -14, to: to) ?? to
            let history = try await fitnessRepository.getSnapshots(from: from, to: to)
            let trendPoints = history
                .sorted { $0.date < $1.date }
                .map { WidgetFitnessPoint(date: $0.date, form: $0.form) }

            let data = WidgetFitnessData(
                form: snapshot.form,
                fitness: snapshot.fitness,
                fatigue: snapshot.fatigue,
                trend: trendPoints
            )
            write(data, key: WidgetDataKeys.fitnessData)
        } catch {
            Logger.widget.error("Failed to write fitness data: \(error)")
        }
    }

    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Watch Complication

    func sendComplicationDataToWatch() async {
        guard connectivityService != nil else { return }

        do {
            var data = WatchComplicationData()

            if let plan = try await planRepository.getActivePlan() {
                let today = Calendar.current.startOfDay(for: .now)
                let session = plan.weeks
                    .flatMap(\.sessions)
                    .filter { !$0.isCompleted && !$0.isSkipped && $0.type != .rest }
                    .filter { $0.date >= today }
                    .sorted { $0.date < $1.date }
                    .first

                if let session {
                    data.nextSessionType = displayName(for: session.type)
                    data.nextSessionIcon = iconName(for: session.type)
                    data.nextSessionDistanceKm = session.plannedDistanceKm
                    data.nextSessionDate = session.date
                }
            }

            let races = try await raceRepository.getRaces()
            let now = Date.now
            if let aRace = races
                .filter({ $0.priority == .aRace && $0.date > now })
                .sorted(by: { $0.date < $1.date })
                .first {
                data.raceCountdownDays = Calendar.current.dateComponents(
                    [.day], from: now, to: aRace.date
                ).day
                data.raceName = aRace.name
            }

            await connectivityService?.sendComplicationData(data)
        } catch {
            Logger.widget.error("Failed to send complication data to watch: \(error)")
        }
    }

    // MARK: - Private

    private func write<T: Encodable>(_ value: T, key: String) {
        guard let encoded = try? JSONEncoder().encode(value) else {
            Logger.widget.error("Failed to encode widget data for key: \(key)")
            return
        }
        defaults?.set(encoded, forKey: key)
    }

    private func clear(key: String) {
        defaults?.removeObject(forKey: key)
    }

    private func iconName(for sessionType: SessionType) -> String {
        switch sessionType {
        case .longRun:       "figure.run"
        case .tempo:         "speedometer"
        case .intervals:     "timer"
        case .verticalGain:  "mountain.2.fill"
        case .backToBack:    "arrow.triangle.2.circlepath"
        case .recovery:      "heart.fill"
        case .crossTraining: "figure.mixed.cardio"
        case .rest:          "bed.double.fill"
        }
    }

    private func displayName(for sessionType: SessionType) -> String {
        switch sessionType {
        case .longRun:       "Long Run"
        case .tempo:         "Tempo"
        case .intervals:     "Intervals"
        case .verticalGain:  "Vertical Gain"
        case .backToBack:    "Back-to-Back"
        case .recovery:      "Recovery"
        case .crossTraining: "Cross-Training"
        case .rest:          "Rest"
        }
    }
}
