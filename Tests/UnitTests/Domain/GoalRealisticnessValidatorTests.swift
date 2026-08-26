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
        // 100km + 5000m D+ = 150 effective km => .hundredK category
        // (80..<161 — below the 161 km 100-Miles boundary), elite
        // threshold 4.0 min/eff km.
        // 9h target = 540min / 150km = 3.6 min/eff km → faster than elite
        let result = GoalRealisticnessValidator.validateTime(
            targetTimeSeconds: 9 * 3600,
            distanceKm: 100,
            elevationGainM: 5000,
            experienceLevel: .elite
        )
        #expect(!result.isRealistic)
        #expect(result.warningMessage?.contains("professional") == true)
    }

    @Test("elite with elite pace is realistic")
    func eliteWithElitePace() {
        // 100km + 5000m D+ = 150 effective km => .hundredK category,
        // elite threshold 4.0 min/eff km => ~10h.
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
        // km => .hundredK category (below the 161 km 100-Miles boundary).
        // A 14h05 target is 5.52 min/eff km — above the hundredK advanced
        // threshold (5.5), so this doesn't even reach "requires advanced,"
        // let alone "world-class professional."
        let result = GoalRealisticnessValidator.validateTime(
            targetTimeSeconds: 14 * 3600 + 5 * 60,
            distanceKm: 103,
            elevationGainM: 5000,
            experienceLevel: .intermediate
        )
        #expect(result.warningMessage?.contains("professional") != true)
    }
}
