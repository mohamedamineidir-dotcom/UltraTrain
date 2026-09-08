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
        let hardFloorWeeks = self.hardFloorWeeks(from: minimumWeeks)
        let isSufficient = availableWeeks >= minimumWeeks
        let canGeneratePlan = availableWeeks >= hardFloorWeeks

        let warningMessage: String? = {
            guard !isSufficient else { return nil }
            let base = "We recommend at least \(minimumWeeks) weeks to prepare for a \(category.displayName) race as a \(experienceLevel.rawValue) runner. You have \(availableWeeks) weeks."
            if canGeneratePlan {
                return base + " We can still build you a plan, just more compressed than usual."
            }
            return base + " That's below our \(hardFloorWeeks)-week minimum for this distance. Try a later date or a shorter race."
        }()

        return TrainingDurationValidation(
            isSufficient: isSufficient,
            availableWeeks: availableWeeks,
            minimumWeeks: minimumWeeks,
            hardFloorWeeks: hardFloorWeeks,
            canGeneratePlan: canGeneratePlan,
            raceCategory: category,
            warningMessage: warningMessage
        )
    }

    /// RR-40: the new hard gate is half the advised minimum (rounded up),
    /// floored at 2 weeks so even elite/short categories keep a real floor.
    static func hardFloorWeeks(from minimumWeeks: Int) -> Int {
        max(2, Int((Double(minimumWeeks) / 2.0).rounded(.up)))
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
