import Foundation

enum MissedSessionRedistributor {

    struct RedistributionResult: Equatable, Sendable {
        let recommendations: [PlanAdjustmentRecommendation]
        let unrecoverableDistanceKm: Double
        let unrecoverableElevationM: Double
    }

    // MARK: - Main Entry Point

    static func analyzeRedistribution(
        plan: TrainingPlan,
        now: Date,
        currentWeekIndex: Int?
    ) -> RedistributionResult {
        guard let cwi = currentWeekIndex else {
            return RedistributionResult(recommendations: [], unrecoverableDistanceKm: 0, unrecoverableElevationM: 0)
        }

        let nowDay = Calendar.current.startOfDay(for: now)
        let volumeSplittable: Set<SessionType> = [.longRun, .verticalGain, .backToBack]
        let qualityTypes: Set<SessionType> = [.intervals, .tempo]
        let keyTypes = volumeSplittable.union(qualityTypes)

        let weeksToCheck = cwi > 0 ? [cwi - 1, cwi] : [cwi]
        let missedSessions = weeksToCheck.flatMap { plan.weeks[$0].sessions }.filter {
            Calendar.current.startOfDay(for: $0.date) < nowDay
                && !$0.isCompleted && !$0.isSkipped && keyTypes.contains($0.type)
        }

        let restSlotWeeks = cwi + 1 < plan.weeks.count ? [cwi, cwi + 1] : [cwi]
        let restSlotCount = restSlotWeeks.flatMap { plan.weeks[$0].sessions }.filter {
            Calendar.current.startOfDay(for: $0.date) >= nowDay && $0.type == .rest && !$0.isCompleted
        }.count
        let unhandled = Array(missedSessions.dropFirst(restSlotCount))
        guard !unhandled.isEmpty else {
            return RedistributionResult(recommendations: [], unrecoverableDistanceKm: 0, unrecoverableElevationM: 0)
        }

        let futureWeeks = cwi + 1 < plan.weeks.count ? [cwi, cwi + 1] : [cwi]
        let futureSessions = futureWeeks.flatMap { plan.weeks[$0].sessions }.filter {
            Calendar.current.startOfDay(for: $0.date) >= nowDay
                && !$0.isCompleted && !$0.isSkipped && $0.type != .rest
        }

        var recommendations: [PlanAdjustmentRecommendation] = []
        var unrecoverableDist = 0.0
        var unrecoverableElev = 0.0
        var usedIds: Set<UUID> = []

        for missed in unhandled {
            if volumeSplittable.contains(missed.type) {
                let r = redistributeVolume(missed: missed, futureSessions: futureSessions, usedIds: &usedIds)
                recommendations.append(contentsOf: r.recommendations)
                unrecoverableDist += r.unrecoverableDistanceKm
                unrecoverableElev += r.unrecoverableElevationM
            } else if qualityTypes.contains(missed.type) {
                let r = convertRecoveryToQuality(missed: missed, futureSessions: futureSessions, usedIds: &usedIds)
                recommendations.append(contentsOf: r.recommendations)
                if r.recommendations.isEmpty {
                    unrecoverableDist += missed.plannedDistanceKm
                    unrecoverableElev += missed.plannedElevationGainM
                }
            }
        }

        return RedistributionResult(
            recommendations: recommendations,
            unrecoverableDistanceKm: unrecoverableDist,
            unrecoverableElevationM: unrecoverableElev
        )
    }

    // MARK: - Accumulated Missed Volume

    static func calculateAccumulatedMissedVolume(
        plan: TrainingPlan,
        now: Date,
        lookbackWeeks: Int = AppConfiguration.Training.redistributionLookbackWeeks
    ) -> (totalMissedDistanceKm: Double, totalMissedElevationM: Double) {
        let nowDay = Calendar.current.startOfDay(for: now)
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .weekOfYear, value: -lookbackWeeks, to: nowDay) else {
            return (0, 0)
        }
        var dist = 0.0
        var elev = 0.0
        for session in plan.weeks.flatMap(\.sessions) where session.type != .rest {
            let day = calendar.startOfDay(for: session.date)
            if day >= cutoff && day < nowDay && !session.isCompleted && !session.isSkipped {
                dist += session.plannedDistanceKm
                elev += session.plannedElevationGainM
            }
        }
        return (dist, elev)
    }

    // MARK: - Volume Redistribution

    private static func redistributeVolume(
        missed: TrainingSession,
        futureSessions: [TrainingSession],
        usedIds: inout Set<UUID>
    ) -> (recommendations: [PlanAdjustmentRecommendation], unrecoverableDistanceKm: Double, unrecoverableElevationM: Double) {
        let maxPct = AppConfiguration.Training.maxSessionVolumeIncreasePercent / 100.0
        let ratios: [Double] = [0.40, 0.35, 0.25]
        let targets = Array(futureSessions.filter { !usedIds.contains($0.id) }.prefix(3))
        guard !targets.isEmpty else {
            return ([], missed.plannedDistanceKm, missed.plannedElevationGainM)
        }

        var adjustments: [VolumeAdjustment] = []
        var distribDist = 0.0
        var distribElev = 0.0

        for (i, target) in targets.enumerated() {
            let ratio = i < ratios.count ? ratios[i] : ratios[ratios.count - 1]
            let addDist = min(missed.plannedDistanceKm * ratio, target.plannedDistanceKm * maxPct)
            let addElev = min(missed.plannedElevationGainM * ratio, target.plannedElevationGainM * maxPct)
            adjustments.append(VolumeAdjustment(
                sessionId: target.id, addedDistanceKm: addDist,
                addedElevationGainM: addElev, newType: nil
            ))
            distribDist += addDist
            distribElev += addElev
            usedIds.insert(target.id)
        }

        let rec = PlanAdjustmentRecommendation(
            id: UUID(),
            type: .redistributeMissedVolume,
            severity: .recommended,
            title: "Redistribute Missed Volume",
            message: "Your missed \(missed.type.rawValue) session's volume will be spread across \(adjustments.count) upcoming sessions.",
            actionLabel: "Redistribute",
            affectedSessionIds: [missed.id] + adjustments.map(\.sessionId),
            volumeAdjustments: adjustments
        )
        return (
            [rec],
            max(missed.plannedDistanceKm - distribDist, 0),
            max(missed.plannedElevationGainM - distribElev, 0)
        )
    }

    // MARK: - Quality Conversion

    private static func convertRecoveryToQuality(
        missed: TrainingSession,
        futureSessions: [TrainingSession],
        usedIds: inout Set<UUID>
    ) -> (recommendations: [PlanAdjustmentRecommendation], unrecoverableDistanceKm: Double, unrecoverableElevationM: Double) {
        guard let target = futureSessions.first(where: {
            $0.type == .recovery && !usedIds.contains($0.id)
        }) else {
            return ([], missed.plannedDistanceKm, missed.plannedElevationGainM)
        }
        usedIds.insert(target.id)

        let adjustment = VolumeAdjustment(
            sessionId: target.id, addedDistanceKm: 0,
            addedElevationGainM: 0, newType: missed.type
        )
        let rec = PlanAdjustmentRecommendation(
            id: UUID(),
            type: .convertEasyToQuality,
            severity: .suggestion,
            title: "Convert Recovery to \(missed.type.rawValue.capitalized)",
            message: "Convert an upcoming recovery run to replace your missed \(missed.type.rawValue) session.",
            actionLabel: "Convert",
            affectedSessionIds: [missed.id, target.id],
            volumeAdjustments: [adjustment]
        )
        return ([rec], 0, 0)
    }
}
