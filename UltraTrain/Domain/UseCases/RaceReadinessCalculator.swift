import Foundation

enum RaceReadinessCalculator {

    static func forecast(
        currentFitness: Double,
        currentFatigue: Double,
        plannedWeeks: [TrainingWeek],
        race: Race
    ) -> RaceReadinessForecast? {
        let now = Date.now
        guard race.date > now else { return nil }

        let daysUntilRace = Calendar.current.dateComponents([.day], from: now, to: race.date).day ?? 0
        guard daysUntilRace > 0 else { return nil }

        let projectionPoints = projectFitness(
            currentFitness: currentFitness,
            currentFatigue: currentFatigue,
            plannedWeeks: plannedWeeks,
            from: now,
            to: race.date
        )

        let projected = projectionPoints.last ?? FitnessProjectionPoint(
            id: UUID(),
            date: race.date,
            projectedFitness: currentFitness,
            projectedFatigue: currentFatigue,
            projectedForm: currentFitness - currentFatigue
        )

        let formStatus = classifyForm(projected.projectedForm)

        return RaceReadinessForecast(
            raceName: race.name,
            raceDate: race.date,
            daysUntilRace: daysUntilRace,
            currentFitness: currentFitness,
            projectedFitnessAtRace: projected.projectedFitness,
            projectedFormAtRace: projected.projectedForm,
            projectedFormStatus: formStatus,
            fitnessProjectionPoints: projectionPoints
        )
    }

    // MARK: - Private

    private static func projectFitness(
        currentFitness: Double,
        currentFatigue: Double,
        plannedWeeks: [TrainingWeek],
        from startDate: Date,
        to endDate: Date
    ) -> [FitnessProjectionPoint] {
        var ctl = currentFitness
        var atl = currentFatigue
        var points: [FitnessProjectionPoint] = []

        let calendar = Calendar.current
        var date = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        while date <= end {
            let dailyLoad = estimateDailyLoad(for: date, from: plannedWeeks)

            ctl += (dailyLoad - ctl) / 42.0
            atl += (dailyLoad - atl) / 7.0
            let form = ctl - atl

            points.append(FitnessProjectionPoint(
                id: UUID(),
                date: date,
                projectedFitness: ctl,
                projectedFatigue: atl,
                projectedForm: form
            ))

            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(86400)
        }

        return points
    }

    private static func estimateDailyLoad(for date: Date, from weeks: [TrainingWeek]) -> Double {
        guard let week = weeks.first(where: { $0.contains(date: date) }) else {
            return 0
        }

        let sessionsInWeek = week.sessions.filter { $0.type != .rest }
        guard !sessionsInWeek.isEmpty else { return 0 }

        let weeklyLoad = week.targetVolumeKm + (week.targetElevationGainM / 100.0)
        return weeklyLoad / 7.0
    }

    private static func classifyForm(_ form: Double) -> FormStatus {
        if form > 15 { return .raceReady }
        if form > 0 { return .fresh }
        if form > -15 { return .building }
        return .fatigued
    }
}
