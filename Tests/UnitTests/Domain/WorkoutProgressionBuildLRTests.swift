import Foundation
import Testing
@testable import UltraTrain

/// T4: build-phase LR (≥90 min) must include a race-pace block in the
/// second half. Pre-fix, build LR fell through to the all-easy template
/// while the coach advice said "include race-pace blocks" — card and
/// detail disagreed.
@Suite("WorkoutProgressionEngine Build Long Run Tests")
struct WorkoutProgressionBuildLRTests {

    private func ctx(weekIndex: Int = 8) -> WorkoutProgressionEngine.ProgressionContext {
        .init(
            raceEffectiveKm: 165,
            raceElevationGainM: 6500,
            totalWeeks: 24,
            weekIndexInPlan: weekIndex,
            experience: .advanced,
            philosophy: .balanced
        )
    }

    private func buildLR(totalMin: Int) -> IntervalWorkout {
        WorkoutProgressionEngine.workout(
            type: .longRun, phase: .build, weekInPhase: 2, intensity: .easy,
            totalDuration: TimeInterval(totalMin * 60),
            expectedRaceDuration: 36000,
            progressionContext: ctx()
        )
    }

    private func baseLR(totalMin: Int) -> IntervalWorkout {
        WorkoutProgressionEngine.workout(
            type: .longRun, phase: .base, weekInPhase: 2, intensity: .easy,
            totalDuration: TimeInterval(totalMin * 60),
            progressionContext: ctx()
        )
    }

    private func phaseDurations(_ workout: IntervalWorkout) -> [(IntervalPhaseType, Intensity, TimeInterval)] {
        workout.phases.map { phase in
            let dur: TimeInterval
            if case .duration(let sec) = phase.trigger { dur = sec * Double(phase.repeatCount) }
            else { dur = 0 }
            return (phase.phaseType, phase.targetIntensity, dur)
        }
    }

    // MARK: - Build LR includes a moderate (race-pace) block

    @Test("3h build LR has a race-pace (.moderate) block, base 3h LR does not")
    func buildHasRacePaceBlockBaseDoesNot() {
        let build = buildLR(totalMin: 180)
        let base = baseLR(totalMin: 180)

        let buildHasModerate = build.phases.contains { $0.targetIntensity == .moderate && $0.phaseType == .work }
        let baseHasModerate = base.phases.contains { $0.targetIntensity == .moderate && $0.phaseType == .work }

        #expect(buildHasModerate, "Build 3h LR must include a race-pace (.moderate) block")
        #expect(!baseHasModerate, "Base 3h LR should remain all-easy (no .moderate work phase)")
    }

    @Test("Race-pace block is ~25% of total duration")
    func blockSizeIs25Percent() {
        let total: TimeInterval = 180 * 60
        let workout = buildLR(totalMin: 180)
        let blockSec = workout.phases
            .filter { $0.targetIntensity == .moderate && $0.phaseType == .work }
            .reduce(0.0) { acc, phase in
                if case .duration(let s) = phase.trigger { return acc + s * Double(phase.repeatCount) }
                return acc
            }
        let ratio = blockSec / total
        #expect(ratio >= 0.20 && ratio <= 0.30,
                "Race-pace block should be ~25% of total, got \(ratio * 100)%")
    }

    @Test("Race-pace block is in the SECOND half (Pfitzinger pattern)")
    func blockInSecondHalf() {
        let workout = buildLR(totalMin: 180)
        var elapsed: TimeInterval = 0
        var blockStart: TimeInterval = -1
        for (type, intensity, dur) in phaseDurations(workout) {
            if intensity == .moderate && type == .work && blockStart < 0 {
                blockStart = elapsed
            }
            elapsed += dur
        }
        #expect(blockStart > 0, "Block found and starts after warmup")
        #expect(blockStart >= elapsed * 0.50,
                "Block must start in the second half (≥50% mark), started at \(blockStart/60) min of \(elapsed/60) min")
    }

    @Test("LR ends with easy + cooldown, NOT on peak intensity")
    func endsEasy() {
        let workout = buildLR(totalMin: 180)
        let last = workout.phases.last
        #expect(last?.phaseType == .coolDown,
                "Last phase must be cooldown")
        #expect(last?.targetIntensity == .easy,
                "Cooldown must be easy intensity")
        // The phase right before cooldown is the "easy finish" — also easy.
        let beforeCooldown = workout.phases.dropLast().last
        #expect(beforeCooldown?.targetIntensity == .easy,
                "Phase before cooldown must be easy (not the race-pace block)")
    }

    // MARK: - Threshold (90-min)

    @Test("Build LR < 90 min falls through to base template (no block)")
    func underThresholdFallsThrough() {
        let workout = buildLR(totalMin: 75)
        let hasModerate = workout.phases.contains { $0.targetIntensity == .moderate && $0.phaseType == .work }
        #expect(!hasModerate,
                "Build LR < 90 min should NOT include a race-pace block")
    }

    @Test("Build LR == 90 min triggers the new template (boundary)")
    func boundary90MinTriggers() {
        let workout = buildLR(totalMin: 90)
        let hasModerate = workout.phases.contains { $0.targetIntensity == .moderate && $0.phaseType == .work }
        #expect(hasModerate,
                "Build LR ≥ 90 min should include a race-pace block")
    }

    // MARK: - Total duration is preserved

    @Test("Total workout duration is approximately the requested total")
    func totalDurationPreserved() {
        let total: TimeInterval = 180 * 60
        let workout = buildLR(totalMin: 180)
        let sum = workout.phases.reduce(0.0) { acc, phase in
            if case .duration(let s) = phase.trigger { return acc + s * Double(phase.repeatCount) }
            return acc
        }
        // Allow 60s slack for floor/ceiling integer math.
        #expect(abs(sum - total) <= 60,
                "Total phase duration should sum to ~\(total) sec, got \(sum)")
    }
}
