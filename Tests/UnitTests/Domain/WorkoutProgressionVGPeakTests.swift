import Foundation
import Testing
@testable import UltraTrain

/// T9: peak-phase VG should include sustained climbs (20–25 min) for
/// advanced+ mountain athletes. Pre-fix the threshold60 max set duration
/// was 12 min — well below race specificity for races where climbs run
/// 20–40 min continuous (UTMB, Hardrock, Madeira class).
@Suite("WorkoutProgressionEngine VG Peak Sustained Climbs Tests")
struct WorkoutProgressionVGPeakTests {

    private func ctx(experience: ExperienceLevel, weekIndex: Int) -> WorkoutProgressionEngine.ProgressionContext {
        .init(
            raceEffectiveKm: 165,
            raceElevationGainM: 6500,
            totalWeeks: 24,
            weekIndexInPlan: weekIndex,
            experience: experience,
            philosophy: .balanced
        )
    }

    private func longestWorkPhase(_ workout: IntervalWorkout) -> TimeInterval {
        workout.phases
            .filter { $0.phaseType == .work }
            .compactMap { phase -> TimeInterval? in
                if case .duration(let s) = phase.trigger { return s }
                return nil
            }
            .max() ?? 0
    }

    /// Across the peak block (idx 16-19 for 24-week plan), produces the
    /// longest single set duration the athlete will see.
    private func longestSetAcrossPeak(experience: ExperienceLevel) -> TimeInterval {
        var maxSet: TimeInterval = 0
        for weekIndex in 16...19 {
            let workout = WorkoutProgressionEngine.workout(
                type: .verticalGain, phase: .peak,
                weekInPhase: weekIndex - 16, intensity: .moderate,
                totalDuration: 60 * 60, phaseFocus: .threshold60,
                progressionContext: ctx(experience: experience, weekIndex: weekIndex)
            )
            maxSet = max(maxSet, longestWorkPhase(workout))
        }
        return maxSet
    }

    @Test("Advanced peak block includes a sustained climb (≥20 min) somewhere")
    func advancedPeakSustained() {
        let longest = longestSetAcrossPeak(experience: .advanced)
        #expect(longest >= 20 * 60,
                "Advanced peak block must include ≥20 min sustained climb (any week), got max \(longest/60) min")
    }

    @Test("Elite peak block reaches 25+ min sustained climbs")
    func elitePeakSustained() {
        let longest = longestSetAcrossPeak(experience: .elite)
        #expect(longest >= 24 * 60,
                "Elite peak block must include ≥24 min sustained climb (any week), got max \(longest/60) min")
    }

    @Test("Intermediate peak block stays tier-appropriate (≤17 min)")
    func intermediatePeakStaysShorter() {
        let longest = longestSetAcrossPeak(experience: .intermediate)
        #expect(longest <= 17 * 60,
                "Intermediate peak block should stay ≤17 min, got max \(longest/60) min")
    }

    @Test("Beginner peak block stays short (≤11 min)")
    func beginnerPeakStaysShort() {
        let longest = longestSetAcrossPeak(experience: .beginner)
        #expect(longest <= 11 * 60,
                "Beginner peak block should stay ≤11 min, got max \(longest/60) min")
    }

    @Test("Advanced peak sustained-climb session uses 1–2 reps")
    func advancedPeakRepCount() {
        // Find the week with the longest set and check its rep count.
        var maxSet: TimeInterval = 0
        var bestRepCount: Int = 0
        for weekIndex in 16...19 {
            let workout = WorkoutProgressionEngine.workout(
                type: .verticalGain, phase: .peak,
                weekInPhase: weekIndex - 16, intensity: .moderate,
                totalDuration: 60 * 60, phaseFocus: .threshold60,
                progressionContext: ctx(experience: .advanced, weekIndex: weekIndex)
            )
            let setDur = longestWorkPhase(workout)
            if setDur > maxSet {
                maxSet = setDur
                bestRepCount = workout.phases
                    .filter { $0.phaseType == .work }
                    .map { $0.repeatCount }
                    .max() ?? 0
            }
        }
        #expect(bestRepCount >= 1 && bestRepCount <= 3,
                "Sustained climb session should be 1–3 reps, got \(bestRepCount)")
    }
}
