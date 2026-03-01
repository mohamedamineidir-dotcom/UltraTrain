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
        experienceLevel: ExperienceLevel
    ) -> GoalValidation {
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
