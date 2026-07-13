import Foundation
import Testing
@testable import UltraTrain

@Suite("GoalRealisticnessValidator Tests")
struct GoalRealisticnessValidatorTests {

    // MARK: - Ranking Validation

    @Test("beginner targeting top 10 on UTMB is unrealistic")
    func beginnerTop10Unrealistic() {
        let result = GoalRealisticnessValidator.validateRanking(
            targetRanking: 10,
            distanceKm: 171,
            elevationGainM: 10000,
            experienceLevel: .beginner
        )
        #expect(!result.isRealistic)
        #expect(result.warningMessage != nil)
    }

    @Test("elite targeting top 3 is realistic")
    func eliteTop3Realistic() {
        let result = GoalRealisticnessValidator.validateRanking(
            targetRanking: 5,
            distanceKm: 171,
            elevationGainM: 10000,
            experienceLevel: .elite
        )
        #expect(result.isRealistic)
    }

    @Test("intermediate targeting top 50% is realistic")
    func intermediateTopHalfRealistic() {
        let result = GoalRealisticnessValidator.validateRanking(
            targetRanking: 150,
            distanceKm: 50,
            elevationGainM: 2000,
            experienceLevel: .intermediate
        )
        #expect(result.isRealistic)
    }

    @Test("advanced targeting top 5 on trail race is unrealistic")
    func advancedTop5TrailUnrealistic() {
        let result = GoalRealisticnessValidator.validateRanking(
            targetRanking: 5,
            distanceKm: 42,
            elevationGainM: 2000,
            experienceLevel: .advanced
        )
        #expect(!result.isRealistic)
    }

    // MARK: - Time Validation

    @Test("beginner with elite pace is unrealistic")
    func beginnerElitePaceUnrealistic() {
        // UTMB 171km + 10000m D+ = 271 effective km
        // Elite pace ~ 7 min/eff km => ~31h
        // Setting 20h target => ~4.4 min/eff km (world record pace)
        let result = GoalRealisticnessValidator.validateTime(
            targetTimeSeconds: 20 * 3600,
            distanceKm: 171,
            elevationGainM: 10000,
            experienceLevel: .beginner
        )
        #expect(!result.isRealistic)
        #expect(result.warningMessage != nil)
    }

    @Test("intermediate with reasonable pace is realistic")
    func intermediateReasonablePace() {
        // 50K trail, 2500m D+ = 75 effective km
        // Intermediate pace for 50K: <7.5 min/eff km
        // 10h target = 600min / 75km = 8 min/eff km → realistic
        let result = GoalRealisticnessValidator.validateTime(
            targetTimeSeconds: 10 * 3600,
            distanceKm: 50,
            elevationGainM: 2500,
            experienceLevel: .intermediate
        )
        #expect(result.isRealistic)
    }

    @Test("pace faster than elite threshold warns about professional athletes")
    func fasterThanEliteWarns() {
        // 100km + 5000m D+ = 150 effective km => .hundredMiles category
        // (140..<220), elite threshold 4.5 min/eff km.
        // 10h target = 600min / 150km = 4.0 min/eff km → faster than elite
        let result = GoalRealisticnessValidator.validateTime(
            targetTimeSeconds: 10 * 3600,
            distanceKm: 100,
            elevationGainM: 5000,
            experienceLevel: .elite
        )
        #expect(!result.isRealistic)
        #expect(result.warningMessage?.contains("professional") == true)
    }

    @Test("elite with elite pace is realistic")
    func eliteWithElitePace() {
        // 100km + 5000m D+ = 150 effective km => .hundredMiles category,
        // elite threshold 4.5 min/eff km => ~11h15.
        // 15h target = 900min / 150km = 6.0 min/eff km → comfortably realistic for elite
        let result = GoalRealisticnessValidator.validateTime(
            targetTimeSeconds: 15 * 3600,
            distanceKm: 100,
            elevationGainM: 5000,
            experienceLevel: .elite
        )
        #expect(result.isRealistic)
    }

    @Test("intermediate ultra target near real elite pace no longer misflagged as world-class")
    func longUltraTargetNotMisflaggedAsElite() {
        // Oman by UTMB Jabal Classic 103K: 103km + 5000m D+ = 153 effective
        // km => .hundredMiles category. A 14h05 target is 5.52 min/eff km —
        // previously flagged "world-class professional" under the old
        // elite=6.0 threshold, even though real elite 100-mile pace on
        // mountain courses (Western States, UTMB, CCC course records) runs
        // ~4.0-4.4 min/eff km. With the corrected elite=4.5 threshold this
        // pace is merely "requires advanced-or-better," not elite.
        let result = GoalRealisticnessValidator.validateTime(
            targetTimeSeconds: 14 * 3600 + 5 * 60,
            distanceKm: 103,
            elevationGainM: 5000,
            experienceLevel: .intermediate
        )
        #expect(result.warningMessage?.contains("professional") != true)
    }
}
