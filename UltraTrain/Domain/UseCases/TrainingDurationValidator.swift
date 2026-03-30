import Foundation

enum TrainingDurationValidator {

    static func validate(
        distanceKm: Double,
        elevationGainM: Double,
        raceDate: Date,
        experienceLevel: ExperienceLevel
    ) -> TrainingDurationValidation {
        let effectiveKm = distanceKm + elevationGainM / 100.0
        let category = RaceCategory.from(effectiveDistanceKm: effectiveKm)
        let availableWeeks = Date.now.weeksBetween(raceDate)
        let minimumWeeks = self.minimumWeeks(for: category, level: experienceLevel)
        let isSufficient = availableWeeks >= minimumWeeks

        let warningMessage: String? = isSufficient ? nil :
            "A \(category.displayName) race typically requires at least \(minimumWeeks) weeks of preparation for a \(experienceLevel.rawValue) runner. You only have \(availableWeeks) weeks."

        return TrainingDurationValidation(
            isSufficient: isSufficient,
            availableWeeks: availableWeeks,
            minimumWeeks: minimumWeeks,
            raceCategory: category,
            warningMessage: warningMessage
        )
    }

    // MARK: - Minimum Weeks Matrix

    private static func minimumWeeks(for category: RaceCategory, level: ExperienceLevel) -> Int {
        switch (category, level) {
        case (.trail, _):                        4
        case (.fiftyK, .beginner):              12
        case (.fiftyK, .intermediate):           8
        case (.fiftyK, .advanced):               6
        case (.fiftyK, .elite):                  4
        case (.hundredK, .beginner):            20
        case (.hundredK, .intermediate):        16
        case (.hundredK, .advanced):            12
        case (.hundredK, .elite):               12
        case (.hundredMiles, .beginner):        28
        case (.hundredMiles, .intermediate):    18
        case (.hundredMiles, .advanced):        18
        case (.hundredMiles, .elite):           12
        case (.ultraLong, .beginner):           36
        case (.ultraLong, .intermediate):       28
        case (.ultraLong, .advanced):           20
        case (.ultraLong, .elite):              12
        }
    }
}
