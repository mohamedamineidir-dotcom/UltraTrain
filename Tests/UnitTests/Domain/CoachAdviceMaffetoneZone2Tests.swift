import Foundation
import Testing
@testable import UltraTrain

/// T7: easy / recovery sessions should surface either a Karvonen Zone-2
/// HR range (when full HR data is available) or a Maffetone aerobic
/// ceiling (180−age, when only age is available). Pre-fix the cue was
/// purely qualitative ("conversational pace") with no number.
@Suite("Coach Advice Maffetone / Zone 2 Tests")
struct CoachAdviceMaffetoneZone2Tests {

    @Test("Easy run with full HR data labels the range as Zone 2")
    func zone2LabelWithFullHR() {
        let advice = CoachAdviceGenerator.advice(
            for: .recovery,
            intensity: .easy,
            phase: .base,
            plannedDurationSeconds: 60 * 60,  // 1h, not long
            restingHR: 50,
            maxHR: 190,
            athleteAge: 35
        )
        #expect(advice != nil)
        #expect(advice?.contains("Zone 2") == true,
                "Easy session with HR data must label range as Zone 2, got: \(advice ?? "nil")")
        #expect(advice?.contains("bpm") == true,
                "HR range should be in bpm")
    }

    @Test("Easy run without resting HR but with age surfaces Maffetone ceiling")
    func maffetoneFallbackWithAgeOnly() {
        let advice = CoachAdviceGenerator.advice(
            for: .recovery,
            intensity: .easy,
            phase: .base,
            plannedDurationSeconds: 60 * 60,
            restingHR: nil,
            maxHR: nil,
            athleteAge: 35
        )
        #expect(advice != nil)
        // 180 − 35 = 145
        #expect(advice?.contains("145") == true,
                "Maffetone ceiling for age 35 should be 145 bpm, got: \(advice ?? "nil")")
        #expect(advice?.contains("Maffetone") == true || advice?.contains("Zone 2") == true,
                "Should reference Maffetone or Zone 2 in the cue, got: \(advice ?? "nil")")
    }

    @Test("Maffetone ceiling has a sensible floor for old athletes")
    func maffetoneFloorForOlderAthletes() {
        let advice = CoachAdviceGenerator.advice(
            for: .recovery,
            intensity: .easy,
            phase: .base,
            plannedDurationSeconds: 60 * 60,
            athleteAge: 75 // 180−75 = 105 → floored to 120
        )
        #expect(advice != nil)
        #expect(advice?.contains("120") == true,
                "Maffetone for age 75 should floor at 120 bpm, got: \(advice ?? "nil")")
    }

    @Test("Quality session does NOT get Maffetone (intervals stay at Karvonen / RPE)")
    func qualitySessionsSkipMaffetone() {
        let advice = CoachAdviceGenerator.advice(
            for: .intervals,
            intensity: .hard,
            phase: .build,
            plannedDurationSeconds: 60 * 60,
            athleteAge: 35
        )
        #expect(advice != nil)
        #expect(advice?.contains("Maffetone") == false,
                "Hard intervals should not surface Maffetone cue, got: \(advice ?? "nil")")
    }

    @Test("Long session (≥2h) skips both Maffetone and Karvonen and uses RPE")
    func longSessionUsesRPE() {
        let advice = CoachAdviceGenerator.advice(
            for: .longRun,
            intensity: .easy,
            phase: .peak,
            plannedDurationSeconds: 3 * 3600,  // 3h, long
            restingHR: 50,
            maxHR: 190,
            athleteAge: 35
        )
        #expect(advice != nil)
        // Long sessions get RPE cue, not "Target HR" or "Maffetone"
        #expect(advice?.contains("Target HR") == false,
                "Long session should not show Target HR (cardiac drift), got: \(advice ?? "nil")")
        #expect(advice?.contains("Maffetone") == false,
                "Long session should not show Maffetone cue, got: \(advice ?? "nil")")
    }

    @Test("Easy run with no age and no HR data falls back to qualitative cue")
    func qualitativeCueFallback() {
        let advice = CoachAdviceGenerator.advice(
            for: .recovery,
            intensity: .easy,
            phase: .base,
            plannedDurationSeconds: 60 * 60,
            athleteAge: 0  // missing
        )
        #expect(advice != nil)
        #expect(advice?.contains("Maffetone") == false,
                "No age → no Maffetone cue, got: \(advice ?? "nil")")
        #expect(advice?.contains("conversational") == true || advice?.contains("Zone 2") == false,
                "Should retain qualitative cue when no HR data, got: \(advice ?? "nil")")
    }
}
