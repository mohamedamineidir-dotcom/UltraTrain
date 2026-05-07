import Foundation
import Testing
@testable import UltraTrain

/// T3: peak race-sim long runs must be capped at 75% of expected race
/// duration so a 24h-target 100-miler athlete doesn't get an 18h race
/// sim. Koop / Roche / Jurek consensus: peak sims max 50–70 km / ≤75%
/// of race duration; the rest of the specificity comes in taper.
@Suite("Peak Race-Sim Cap Tests")
struct WorkoutProgressionPeakRaceSimCapTests {

    private func ctx(effectiveKm: Double = 165) -> WorkoutProgressionEngine.ProgressionContext {
        .init(
            raceEffectiveKm: effectiveKm,
            raceElevationGainM: 6500,
            totalWeeks: 24,
            weekIndexInPlan: 14,
            experience: .advanced,
            philosophy: .performance
        )
    }

    /// Sums ALL phase durations (work + recovery + warmup + cooldown).
    private func totalDuration(_ workout: IntervalWorkout) -> TimeInterval {
        workout.phases.reduce(0) { acc, phase in
            switch phase.trigger {
            case .duration(let sec):
                return acc + sec * Double(phase.repeatCount)
            case .distance:
                return acc
            }
        }
    }

    @Test("Race-sim is capped at 75% of expected race duration")
    func capKicksIn() {
        // 24h race target (100-miler), but the LR curve hands us a 12h
        // totalDuration. Without the cap, the race-sim would run 12h.
        // With the cap: min(12h, 24h × 0.75) = 18h... wait, that doesn't
        // help. The cap reduces only when totalDuration > expectedRace ×
        // 0.75. So request 20h totalDuration — should be clipped to 18h.
        let workout = WorkoutProgressionEngine.workout(
            type: .longRun, phase: .peak, weekInPhase: 2, intensity: .moderate,
            totalDuration: 20 * 3600,
            expectedRaceDuration: 24 * 3600,
            progressionContext: ctx(effectiveKm: 250)
        )
        let total = totalDuration(workout)
        // Cap = 24 × 0.75 = 18h. Workout total should be ≤ 18h (some
        // slack for warmup/cooldown rounding).
        #expect(total <= 18 * 3600 + 60,
                "Capped peak race-sim should be ≤ 18h for 24h target, got \(total/3600)h")
    }

    @Test("Race-sim under the cap is left unchanged")
    func underCapPassthrough() {
        // 10h race target, request a 5h LR. Cap = 7.5h. Should pass
        // through unchanged.
        let workout = WorkoutProgressionEngine.workout(
            type: .longRun, phase: .peak, weekInPhase: 2, intensity: .moderate,
            totalDuration: 5 * 3600,
            expectedRaceDuration: 10 * 3600,
            progressionContext: ctx(effectiveKm: 165)
        )
        let total = totalDuration(workout)
        #expect(abs(total - 5 * 3600) <= 60,
                "5h LR with 10h target (cap=7.5h) should remain ~5h, got \(total/3600)h")
    }

    @Test("Zero expectedRaceDuration disables the cap (legacy callers)")
    func zeroExpectedDoesNotCap() {
        // Some legacy paths pass expectedRaceDuration = 0. The cap should
        // be skipped so behavior matches pre-T3 for those callers.
        let workout = WorkoutProgressionEngine.workout(
            type: .longRun, phase: .peak, weekInPhase: 2, intensity: .moderate,
            totalDuration: 6 * 3600,
            expectedRaceDuration: 0,
            progressionContext: ctx(effectiveKm: 100)
        )
        let total = totalDuration(workout)
        #expect(abs(total - 6 * 3600) <= 60,
                "expectedRaceDuration=0 should pass through without cap, got \(total/3600)h")
    }

    @Test("100K-target peak race-sim never exceeds ~7.5h")
    func hundredKConsensus() {
        // 10h 100K target. Even if upstream hands us 9h totalDuration,
        // the cap at 7.5h (75%) holds — Koop / Roche / Jurek consensus.
        let workout = WorkoutProgressionEngine.workout(
            type: .longRun, phase: .peak, weekInPhase: 2, intensity: .moderate,
            totalDuration: 9 * 3600,
            expectedRaceDuration: 10 * 3600,
            progressionContext: ctx(effectiveKm: 165)
        )
        let total = totalDuration(workout)
        #expect(total <= 7.5 * 3600 + 60,
                "100K race-sim must be ≤ 7.5h, got \(total/3600)h")
    }
}
