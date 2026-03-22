import Foundation
import Testing
@testable import UltraTrain

@Suite("WorkoutProgressionEngine - Progressive Interval & VG Tests")
struct WorkoutProgressionEngineProgressionTests {

    // MARK: - Helpers

    private func ctx(
        effectiveKm: Double = 100,
        elevationM: Double = 5000,
        totalWeeks: Int = 24,
        weekIndex: Int = 0,
        experience: ExperienceLevel = .intermediate,
        philosophy: TrainingPhilosophy = .balanced
    ) -> WorkoutProgressionEngine.ProgressionContext {
        .init(
            raceEffectiveKm: effectiveKm,
            raceElevationGainM: elevationM,
            totalWeeks: totalWeeks,
            weekIndexInPlan: weekIndex,
            experience: experience,
            philosophy: philosophy
        )
    }

    private func workPhaseDuration(_ workout: IntervalWorkout) -> TimeInterval {
        workout.phases
            .filter { $0.phaseType == .work }
            .first
            .map { phase in
                guard case .duration(let sec) = phase.trigger else { return 0.0 }
                return sec
            } ?? 0
    }

    // MARK: - 1. Interval Progressive Overload

    @Test("interval total work increases from week 1 to last key week")
    func intervalProgressiveOverload() {
        let early = WorkoutProgressionEngine.workout(
            type: .intervals, phase: .base, weekInPhase: 0, intensity: .hard,
            totalDuration: 3600, phaseFocus: .threshold30,
            progressionContext: ctx(weekIndex: 0)
        )
        let late = WorkoutProgressionEngine.workout(
            type: .intervals, phase: .peak, weekInPhase: 5, intensity: .moderate,
            totalDuration: 4500, phaseFocus: .threshold60,
            progressionContext: ctx(weekIndex: 20)
        )
        #expect(late.totalWorkDuration > early.totalWorkDuration)
    }

    // MARK: - 2. Bloc Awareness: threshold30 shorter sets than threshold60

    @Test("threshold30 produces shorter set durations than threshold60")
    func threshold30ShorterThanThreshold60() {
        let t30 = WorkoutProgressionEngine.workout(
            type: .intervals, phase: .base, weekInPhase: 2, intensity: .hard,
            totalDuration: 3600, phaseFocus: .threshold30,
            progressionContext: ctx(weekIndex: 6)
        )
        let t60 = WorkoutProgressionEngine.workout(
            type: .intervals, phase: .peak, weekInPhase: 2, intensity: .moderate,
            totalDuration: 3600, phaseFocus: .threshold60,
            progressionContext: ctx(weekIndex: 6)
        )
        let t30SetDur = workPhaseDuration(t30)
        let t60SetDur = workPhaseDuration(t60)
        #expect(t30SetDur < t60SetDur)
    }

    // MARK: - 3. VO2max Short Reps

    @Test("vo2max produces short high-intensity reps")
    func vo2maxShortReps() {
        let vo2 = WorkoutProgressionEngine.workout(
            type: .intervals, phase: .build, weekInPhase: 0, intensity: .hard,
            totalDuration: 3600, phaseFocus: .vo2max,
            progressionContext: ctx(weekIndex: 8)
        )
        let setDur = workPhaseDuration(vo2)
        // VO2max: set duration should be short (<=150s at mid-plan)
        #expect(setDur <= 150)
        #expect(setDur > 0)
    }

    // MARK: - 4. Race Scale: Longer Race = More Work

    @Test("longer race produces more total interval work at same plan progress")
    func longerRaceMoreWork() {
        let short = WorkoutProgressionEngine.workout(
            type: .intervals, phase: .build, weekInPhase: 3, intensity: .hard,
            totalDuration: 3600, phaseFocus: .vo2max,
            progressionContext: ctx(effectiveKm: 50, weekIndex: 12)
        )
        let long = WorkoutProgressionEngine.workout(
            type: .intervals, phase: .build, weekInPhase: 3, intensity: .hard,
            totalDuration: 3600, phaseFocus: .vo2max,
            progressionContext: ctx(effectiveKm: 200, weekIndex: 12)
        )
        #expect(long.totalWorkDuration > short.totalWorkDuration)
    }

    // MARK: - 5. Experience Scale: Beginner < Advanced

    @Test("beginner gets less total interval work than advanced")
    func beginnerLessWorkThanAdvanced() {
        let beginner = WorkoutProgressionEngine.workout(
            type: .intervals, phase: .base, weekInPhase: 0, intensity: .hard,
            totalDuration: 3600, phaseFocus: .threshold30,
            progressionContext: ctx(weekIndex: 5, experience: .beginner)
        )
        let advanced = WorkoutProgressionEngine.workout(
            type: .intervals, phase: .base, weekInPhase: 0, intensity: .hard,
            totalDuration: 3600, phaseFocus: .threshold30,
            progressionContext: ctx(weekIndex: 5, experience: .advanced)
        )
        #expect(advanced.totalWorkDuration > beginner.totalWorkDuration)
    }

    // MARK: - 6. Philosophy Scale: Performance > Enjoyment

    @Test("performance philosophy produces more total work than enjoyment")
    func performanceMoreThanEnjoyment() {
        let enjoy = WorkoutProgressionEngine.workout(
            type: .intervals, phase: .build, weekInPhase: 2, intensity: .hard,
            totalDuration: 3600, phaseFocus: .vo2max,
            progressionContext: ctx(weekIndex: 10, philosophy: .enjoyment)
        )
        let perf = WorkoutProgressionEngine.workout(
            type: .intervals, phase: .build, weekInPhase: 2, intensity: .hard,
            totalDuration: 3600, phaseFocus: .vo2max,
            progressionContext: ctx(weekIndex: 10, philosophy: .performance)
        )
        #expect(perf.totalWorkDuration > enjoy.totalWorkDuration)
    }

    // MARK: - 7. VG with threshold30 = Aerobic Climbing

    @Test("VG with threshold30 focus produces moderate aerobic climbing")
    func vgThreshold30AerobicClimbing() {
        let workout = WorkoutProgressionEngine.workout(
            type: .verticalGain, phase: .base, weekInPhase: 0, intensity: .moderate,
            totalDuration: 3600, phaseFocus: .threshold30,
            progressionContext: ctx(weekIndex: 2)
        )
        let setDur = workPhaseDuration(workout)
        // Threshold30 VG: longer moderate climbs (>=5min at even early progress)
        #expect(setDur >= 300)
        let workPhase = workout.phases.first { $0.phaseType == .work }
        #expect(workPhase?.targetIntensity == .moderate)
    }

    // MARK: - 8. VG with vo2max = Short Steep Reps

    @Test("VG with vo2max focus produces short steep hill repeats")
    func vgVo2maxSteepRepeats() {
        let workout = WorkoutProgressionEngine.workout(
            type: .verticalGain, phase: .build, weekInPhase: 0, intensity: .hard,
            totalDuration: 3600, phaseFocus: .vo2max,
            progressionContext: ctx(weekIndex: 10)
        )
        let setDur = workPhaseDuration(workout)
        // VO2max VG: short steep reps (<=180s)
        #expect(setDur <= 180)
        let workPhase = workout.phases.first { $0.phaseType == .work }
        #expect(workPhase?.targetIntensity == .hard)
    }

    // MARK: - 9. VG Progressive Overload

    @Test("VG total work increases from early to late plan")
    func vgProgressiveOverload() {
        let early = WorkoutProgressionEngine.workout(
            type: .verticalGain, phase: .base, weekInPhase: 0, intensity: .moderate,
            totalDuration: 3600, phaseFocus: .threshold30,
            progressionContext: ctx(weekIndex: 1)
        )
        let late = WorkoutProgressionEngine.workout(
            type: .verticalGain, phase: .peak, weekInPhase: 4, intensity: .moderate,
            totalDuration: 4500, phaseFocus: .threshold60,
            progressionContext: ctx(weekIndex: 20)
        )
        #expect(late.totalWorkDuration > early.totalWorkDuration)
    }

    // MARK: - 10. VG Elevation Density Scaling

    @Test("higher elevation density race produces more VG work")
    func vgElevationDensityScaling() {
        let flat = WorkoutProgressionEngine.workout(
            type: .verticalGain, phase: .build, weekInPhase: 2, intensity: .hard,
            totalDuration: 3600, phaseFocus: .vo2max,
            progressionContext: ctx(effectiveKm: 100, elevationM: 2000, weekIndex: 12)
        )
        let mountainous = WorkoutProgressionEngine.workout(
            type: .verticalGain, phase: .build, weekInPhase: 2, intensity: .hard,
            totalDuration: 3600, phaseFocus: .vo2max,
            progressionContext: ctx(effectiveKm: 100, elevationM: 8000, weekIndex: 12)
        )
        #expect(mountainous.totalWorkDuration > flat.totalWorkDuration)
    }

    // MARK: - 11. Sharpening Fixed

    @Test("sharpening intervals produce fixed workout regardless of plan progress")
    func sharpeningFixedWorkout() {
        let early = WorkoutProgressionEngine.workout(
            type: .intervals, phase: .taper, weekInPhase: 0, intensity: .moderate,
            totalDuration: 3600, phaseFocus: .sharpening,
            progressionContext: ctx(weekIndex: 0)
        )
        let late = WorkoutProgressionEngine.workout(
            type: .intervals, phase: .taper, weekInPhase: 0, intensity: .moderate,
            totalDuration: 3600, phaseFocus: .sharpening,
            progressionContext: ctx(weekIndex: 22)
        )
        #expect(early.totalWorkDuration == late.totalWorkDuration)
    }

    // MARK: - 12. Legacy Fallback

    @Test("nil progressionContext falls back to legacy behavior")
    func nilContextLegacyFallback() {
        let workout = WorkoutProgressionEngine.workout(
            type: .intervals, phase: .build, weekInPhase: 0, intensity: .hard,
            totalDuration: 3600, phaseFocus: .vo2max,
            progressionContext: nil
        )
        #expect(!workout.phases.isEmpty)
        let hasWork = workout.phases.contains { $0.phaseType == .work }
        #expect(hasWork)
    }
}
