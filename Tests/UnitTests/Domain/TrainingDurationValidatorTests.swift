import Testing
import Foundation
@testable import UltraTrain

@Suite("TrainingDurationValidator Tests")
struct TrainingDurationValidatorTests {

    @Test("Sufficient time for beginner 50K")
    func sufficientTimeForBeginner50K() {
        let raceDate = Calendar.current.date(byAdding: .weekOfYear, value: 14, to: .now)!
        let result = TrainingDurationValidator.validate(
            distanceKm: 50,
            elevationGainM: 2000,
            raceDate: raceDate,
            experienceLevel: .beginner
        )
        // 50 + 20 = 70 eff km → fiftyK category → beginner needs 12 weeks, has 14
        #expect(result.isSufficient)
        #expect(result.warningMessage == nil)
        #expect(result.raceCategory == .fiftyK)
    }

    @Test("Insufficient time for beginner 50K")
    func insufficientTimeForBeginner50K() {
        let raceDate = Calendar.current.date(byAdding: .weekOfYear, value: 8, to: .now)!
        let result = TrainingDurationValidator.validate(
            distanceKm: 50,
            elevationGainM: 2000,
            raceDate: raceDate,
            experienceLevel: .beginner
        )
        #expect(!result.isSufficient)
        #expect(result.warningMessage != nil)
        #expect(result.minimumWeeks == 12)
    }

    @Test("Elite needs less time")
    func eliteNeedsLessTime() {
        let raceDate = Calendar.current.date(byAdding: .weekOfYear, value: 5, to: .now)!
        let result = TrainingDurationValidator.validate(
            distanceKm: 50,
            elevationGainM: 2000,
            raceDate: raceDate,
            experienceLevel: .elite
        )
        // Elite needs only 4 weeks for 50K
        #expect(result.isSufficient)
    }

    @Test("UTMB requires many weeks for beginner")
    func utmbBeginnerNeedsLongPrep() {
        let raceDate = Calendar.current.date(byAdding: .weekOfYear, value: 20, to: .now)!
        let result = TrainingDurationValidator.validate(
            distanceKm: 171,
            elevationGainM: 10000,
            raceDate: raceDate,
            experienceLevel: .beginner
        )
        // 171 + 100 = 271 eff km → ultraLong → beginner needs 36 weeks
        #expect(!result.isSufficient)
        #expect(result.minimumWeeks == 36)
        #expect(result.raceCategory == .ultraLong)
    }

    @Test("Trail race always sufficient with 4+ weeks")
    func trailAlwaysSufficientWithFourWeeks() {
        let raceDate = Calendar.current.date(byAdding: .weekOfYear, value: 5, to: .now)!
        let result = TrainingDurationValidator.validate(
            distanceKm: 30,
            elevationGainM: 1000,
            raceDate: raceDate,
            experienceLevel: .beginner
        )
        #expect(result.isSufficient)
        #expect(result.minimumWeeks == 4)
    }

    @Test("Advanced runner 100 miles")
    func advanced100Miles() {
        let raceDate = Calendar.current.date(byAdding: .weekOfYear, value: 18, to: .now)!
        let result = TrainingDurationValidator.validate(
            distanceKm: 161,
            elevationGainM: 0,
            raceDate: raceDate,
            experienceLevel: .advanced
        )
        // 161 + 0 = 161 eff km → hundredMiles → advanced needs 16 weeks
        #expect(result.isSufficient)
        #expect(result.raceCategory == .hundredMiles)
    }

    @Test("Warning message includes relevant info")
    func warningMessageContent() {
        let raceDate = Calendar.current.date(byAdding: .weekOfYear, value: 6, to: .now)!
        let result = TrainingDurationValidator.validate(
            distanceKm: 100,
            elevationGainM: 5000,
            raceDate: raceDate,
            experienceLevel: .intermediate
        )
        // 100 + 50 = 150 eff km → hundredK (below the 161 km 100-Miles
        // boundary) → intermediate needs 16 weeks
        #expect(result.raceCategory == .hundredK)
        #expect(!result.isSufficient)
        guard let message = result.warningMessage else {
            Issue.record("Expected warning message")
            return
        }
        #expect(message.contains("16"))
        #expect(message.contains("intermediate"))
    }

    @Test("A hilly 100K isn't blocked by the 100 Miles category's higher minimum")
    func hillyHundredKUsesHundredKMinimum() {
        // Reported bug: 100 km + 5000 m D+ (150 eff km) used to be
        // classified `.hundredMiles` and require 16 weeks for an advanced
        // runner (needlessly higher than the real 100K minimum of 12) —
        // blocking athletes who actually had enough time for their race's
        // real category.
        let raceDate = Calendar.current.date(byAdding: .weekOfYear, value: 14, to: .now)!
        let result = TrainingDurationValidator.validate(
            distanceKm: 100,
            elevationGainM: 5000,
            raceDate: raceDate,
            experienceLevel: .advanced
        )
        #expect(result.raceCategory == .hundredK)
        #expect(result.minimumWeeks == 12)
        #expect(result.isSufficient)
    }
}
