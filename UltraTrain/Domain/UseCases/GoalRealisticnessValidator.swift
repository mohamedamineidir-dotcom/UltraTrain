import Foundation

enum GoalRealisticnessValidator {

    // MARK: - Public

    static func validateRanking(
        targetRanking: Int,
        distanceKm: Double,
        elevationGainM: Double,
        experienceLevel: ExperienceLevel
    ) -> GoalValidation {
        let category = RaceCategory.from(
            effectiveDistanceKm: distanceKm + elevationGainM / 100.0
        )
        let fieldSize = typicalFieldSize(for: category)
        let minRealisticRank = minRealisticRanking(
            level: experienceLevel,
            fieldSize: fieldSize
        )

        if targetRanking <= minRealisticRank {
            let levelName = experienceLevel.rawValue
            return GoalValidation(
                isRealistic: false,
                warningMessage: "A top \(targetRanking) finish on a \(category.displayName) race is extremely ambitious for a \(levelName) runner. Top finishes require years of competitive ultra experience."
            )
        }
        return GoalValidation(isRealistic: true, warningMessage: nil)
    }

    static func validateTime(
        targetTimeSeconds: TimeInterval,
        distanceKm: Double,
        elevationGainM: Double,
        experienceLevel: ExperienceLevel,
        raceType: RaceType = .trail
    ) -> GoalValidation {
        // Road races use flat-ground pace thresholds (no elevation adjustment)
        if raceType == .road {
            return validateRoadTime(
                targetTimeSeconds: targetTimeSeconds,
                distanceKm: distanceKm,
                experienceLevel: experienceLevel
            )
        }

        let effectiveKm = distanceKm + elevationGainM / 100.0
        let category = RaceCategory.from(effectiveDistanceKm: effectiveKm)
        let targetPace = targetTimeSeconds / 60.0 / effectiveKm // min per effective km

        let thresholds = paceThresholds(for: category)
        let levelAbove = levelAbove(experienceLevel)

        if targetPace < thresholds.elite {
            return GoalValidation(
                isRealistic: false,
                warningMessage: "This pace would place you among the top professional athletes in the world. Consider a more realistic target time."
            )
        }

        if let above = levelAbove, targetPace < threshold(for: above, thresholds: thresholds) {
            let hours = Int(targetTimeSeconds) / 3600
            let mins = (Int(targetTimeSeconds) % 3600) / 60
            return GoalValidation(
                isRealistic: false,
                warningMessage: "A \(hours)h\(String(format: "%02d", mins)) finish requires a pace typically achieved by \(above.rawValue) or better runners. Consider adjusting your target."
            )
        }

        return GoalValidation(isRealistic: true, warningMessage: nil)
    }

    // MARK: - Road Race Time Validation

    /// Road race pace thresholds based on actual road running data.
    ///
    /// Sources: World Athletics statistics, RunRepeat global race data, Strava.
    /// Elite marathon: sub 2:10 (men) / sub 2:30 (women)
    /// Advanced marathon: 2:30-3:15
    /// Intermediate marathon: 3:15-4:15
    /// Beginner marathon: 4:15+
    ///
    /// Thresholds are in min/km for flat ground (no elevation adjustment).
    private static func validateRoadTime(
        targetTimeSeconds: TimeInterval,
        distanceKm: Double,
        experienceLevel: ExperienceLevel
    ) -> GoalValidation {
        let targetPaceMinPerKm = targetTimeSeconds / 60.0 / distanceKm
        let discipline = RoadRaceDiscipline.from(distanceKm: distanceKm)

        let roadThresholds = roadPaceThresholds(for: discipline)
        let levelAbove = levelAbove(experienceLevel)

        // Only flag truly world-class paces
        if targetPaceMinPerKm < roadThresholds.elite {
            return GoalValidation(
                isRealistic: false,
                warningMessage: "This pace is at the world-class professional level. Consider a more realistic target time."
            )
        }

        // Flag if pace is above current experience level
        if let above = levelAbove, targetPaceMinPerKm < roadThreshold(for: above, thresholds: roadThresholds) {
            let hours = Int(targetTimeSeconds) / 3600
            let mins = (Int(targetTimeSeconds) % 3600) / 60
            return GoalValidation(
                isRealistic: false,
                warningMessage: "A \(hours)h\(String(format: "%02d", mins)) finish is typically achieved by \(above.rawValue) or better runners. It's ambitious but possible with the right training."
            )
        }

        return GoalValidation(isRealistic: true, warningMessage: nil)
    }

    private struct RoadPaceThresholds {
        let elite: Double       // World-class
        let advanced: Double    // Competitive club runner
        let intermediate: Double // Experienced recreational
        let beginner: Double    // Newer runner
    }

    /// Road pace thresholds (min/km) by discipline.
    ///
    /// Marathon: Elite <3:07/km (sub 2:12), Advanced <3:45/km (sub 2:38),
    ///   Intermediate <4:45/km (sub 3:21), Beginner <6:00/km (sub 4:13)
    /// HM: Elite <3:00/km (sub 63:30), Advanced <3:35/km (sub 75:30),
    ///   Intermediate <4:30/km (sub 95:00), Beginner <5:40/km (sub 120:00)
    /// 10K: Elite <2:52/km (sub 28:40), Advanced <3:25/km (sub 34:10),
    ///   Intermediate <4:15/km (sub 42:30), Beginner <5:20/km (sub 53:20)
    private static func roadPaceThresholds(for discipline: RoadRaceDiscipline) -> RoadPaceThresholds {
        switch discipline {
        case .road10K:
            RoadPaceThresholds(elite: 2.87, advanced: 3.42, intermediate: 4.25, beginner: 5.33)
        case .roadHalf:
            RoadPaceThresholds(elite: 3.00, advanced: 3.58, intermediate: 4.50, beginner: 5.67)
        case .roadMarathon:
            RoadPaceThresholds(elite: 3.12, advanced: 3.75, intermediate: 4.75, beginner: 6.00)
        }
    }

    private static func roadThreshold(for level: ExperienceLevel, thresholds: RoadPaceThresholds) -> Double {
        switch level {
        case .beginner:     thresholds.beginner
        case .intermediate: thresholds.intermediate
        case .advanced:     thresholds.advanced
        case .elite:        thresholds.elite
        }
    }

    // MARK: - Ranking Thresholds

    private static func typicalFieldSize(for category: RaceCategory) -> Int {
        switch category {
        case .trail:        200
        case .fiftyK:       500
        case .hundredK:     300
        case .hundredMiles: 200
        case .ultraLong:    100
        }
    }

    private static func minRealisticRanking(level: ExperienceLevel, fieldSize: Int) -> Int {
        switch level {
        case .beginner:     max(1, fieldSize / 2)  // Top 50%
        case .intermediate: max(1, fieldSize / 4)  // Top 25%
        case .advanced:     10
        case .elite:        3
        }
    }

    // MARK: - Pace Thresholds (min per effective km)

    private struct PaceThresholds {
        let elite: Double
        let advanced: Double
        let intermediate: Double
        let beginner: Double
    }

    private static func paceThresholds(for category: RaceCategory) -> PaceThresholds {
        switch category {
        case .trail:        PaceThresholds(elite: 4.5, advanced: 5.5, intermediate: 6.5, beginner: 8.0)
        case .fiftyK:       PaceThresholds(elite: 5.0, advanced: 6.0, intermediate: 7.5, beginner: 9.0)
        case .hundredK:     PaceThresholds(elite: 5.5, advanced: 7.0, intermediate: 8.5, beginner: 10.5)
        case .hundredMiles: PaceThresholds(elite: 6.0, advanced: 8.0, intermediate: 10.0, beginner: 13.0)
        case .ultraLong:    PaceThresholds(elite: 7.0, advanced: 9.0, intermediate: 11.0, beginner: 14.0)
        }
    }

    private static func threshold(for level: ExperienceLevel, thresholds: PaceThresholds) -> Double {
        switch level {
        case .beginner:     thresholds.beginner
        case .intermediate: thresholds.intermediate
        case .advanced:     thresholds.advanced
        case .elite:        thresholds.elite
        }
    }

    private static func levelAbove(_ level: ExperienceLevel) -> ExperienceLevel? {
        switch level {
        case .beginner:     .intermediate
        case .intermediate: .advanced
        case .advanced:     .elite
        case .elite:        nil
        }
    }
}
