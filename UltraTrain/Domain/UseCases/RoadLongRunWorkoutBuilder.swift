import Foundation

/// Builds structured `IntervalWorkout` objects for road long-run variants.
///
/// Until RR-2 the long-run variant (`.marathonPaceBlocks`, `.progressive`,
/// `.fastFinish`, `.twoPart`, `.raceSimulation`) was rendered only as a
/// description string. The session itself had `intensity = .easy` and
/// `intervalWorkoutId = nil`, so the athlete saw no phase guidance, no
/// pace targets, and no auto-advance in ActiveRunView. This builder
/// produces real multi-phase workouts — a Pfitzinger "17 mi w/ 12 at MP"
/// or Canova "alternating 4 km easy / 3 km MP × 4" becomes an executable
/// structured workout that `IntervalGuidanceHandler` can drive.
///
/// Research basis:
/// - **Pfitzinger**: MP segments in long runs grow progressively across
///   peak (8 → 10 → 12 → 14 mi at MP).
/// - **Canova**: alternating easy/MP blocks in the "specific long run"
///   mesocycle; block length extends weekly.
/// - **Daniels**: "2E + 14M + 1E" — explicit pace segments, never just
///   "long run with MP somewhere inside."
enum RoadLongRunWorkoutBuilder {

    /// Build an IntervalWorkout for the given long-run variant. Returns
    /// `nil` for `.easy` (a plain easy long run doesn't need phase
    /// structure).
    static func build(
        variant: RoadLongRunCalculator.LongRunVariant,
        totalDuration: TimeInterval,
        paceProfile: RoadPaceProfile?,
        weekInPhase: Int
    ) -> IntervalWorkout? {
        switch variant {
        case .easy:
            return nil
        case .progressive:
            return buildProgressive(totalDuration: totalDuration, paceProfile: paceProfile)
        case .fastFinish:
            return buildFastFinish(totalDuration: totalDuration, paceProfile: paceProfile)
        case .marathonPaceBlocks:
            return buildMarathonPaceBlocks(totalDuration: totalDuration, paceProfile: paceProfile, weekInPhase: weekInPhase)
        case .twoPart:
            return buildTwoPart(totalDuration: totalDuration, paceProfile: paceProfile)
        case .raceSimulation:
            return buildRaceSimulation(totalDuration: totalDuration, paceProfile: paceProfile, weekInPhase: weekInPhase)
        }
    }

    // MARK: - Variants

    /// Progressive: ease in, steady middle, finish harder.
    /// 60% easy → 25% at half-marathon pace → 15% at marathon pace.
    private static func buildProgressive(totalDuration: TimeInterval, paceProfile: RoadPaceProfile?) -> IntervalWorkout {
        let easyPart = totalDuration * 0.60
        let hmpPart  = totalDuration * 0.25
        let mpPart   = totalDuration * 0.15

        let phases = [
            IntervalPhase(
                id: UUID(), phaseType: .warmUp,
                trigger: .duration(seconds: easyPart),
                targetIntensity: .easy, repeatCount: 1,
                notes: paceNote("Easy pace", easyPace(paceProfile))
            ),
            IntervalPhase(
                id: UUID(), phaseType: .work,
                trigger: .duration(seconds: hmpPart),
                targetIntensity: .moderate, repeatCount: 1,
                notes: paceNote("Half-marathon effort", paceProfile?.thresholdPacePerKm)
            ),
            IntervalPhase(
                id: UUID(), phaseType: .work,
                trigger: .duration(seconds: mpPart),
                targetIntensity: .moderate, repeatCount: 1,
                notes: paceNote("Marathon pace", paceProfile?.marathonPacePerKm)
            ),
        ]
        return workout(
            name: "Progressive long run",
            description: "Ease in, build to half-marathon effort, finish at marathon pace.",
            phases: phases,
            totalDuration: totalDuration,
            paceProfile: paceProfile
        )
    }

    /// Fast-finish: last 25% at race pace.
    private static func buildFastFinish(totalDuration: TimeInterval, paceProfile: RoadPaceProfile?) -> IntervalWorkout {
        let easyPart = totalDuration * 0.75
        let racePart = totalDuration * 0.25

        let phases = [
            IntervalPhase(
                id: UUID(), phaseType: .warmUp,
                trigger: .duration(seconds: easyPart),
                targetIntensity: .easy, repeatCount: 1,
                notes: paceNote("Easy pace", easyPace(paceProfile))
            ),
            IntervalPhase(
                id: UUID(), phaseType: .work,
                trigger: .duration(seconds: racePart),
                targetIntensity: .hard, repeatCount: 1,
                notes: paceNote("Race pace finish", paceProfile?.racePacePerKm)
            ),
        ]
        return workout(
            name: "Fast-finish long run",
            description: "Easy pace, then the last quarter at race pace.",
            phases: phases,
            totalDuration: totalDuration,
            paceProfile: paceProfile
        )
    }

    /// Canova-style alternating blocks (marathon prep).
    /// Warm-up (15 min easy) → N × [MP block + 5 min easy] → cool-down (10 min).
    /// Block duration grows across peak weeks: 12 min (W0) → 16 (W1) → 20 (W2) → 24 (W3)...
    private static func buildMarathonPaceBlocks(totalDuration: TimeInterval, paceProfile: RoadPaceProfile?, weekInPhase: Int) -> IntervalWorkout {
        let warmUp: TimeInterval = 15 * 60
        let coolDown: TimeInterval = 10 * 60
        let restBetween: TimeInterval = 5 * 60
        let numBlocks = 3

        // Block duration grows each peak week, capped by available time.
        var blockDuration = TimeInterval(12 + weekInPhase * 4) * 60  // 12 / 16 / 20 / 24 / 28 min
        let totalBlocksAndRest = Double(numBlocks) * blockDuration + Double(numBlocks - 1) * restBetween
        let availableWork = totalDuration - warmUp - coolDown
        if totalBlocksAndRest > availableWork {
            // Shrink block duration to fit.
            let adjusted = max(6 * 60, (availableWork - Double(numBlocks - 1) * restBetween) / Double(numBlocks))
            blockDuration = adjusted
        }

        let phases = [
            IntervalPhase(
                id: UUID(), phaseType: .warmUp,
                trigger: .duration(seconds: warmUp),
                targetIntensity: .easy, repeatCount: 1,
                notes: paceNote("Easy warm-up", easyPace(paceProfile))
            ),
            IntervalPhase(
                id: UUID(), phaseType: .work,
                trigger: .duration(seconds: blockDuration),
                targetIntensity: .moderate, repeatCount: numBlocks,
                notes: paceNote("Marathon pace", paceProfile?.marathonPacePerKm)
            ),
            IntervalPhase(
                id: UUID(), phaseType: .recovery,
                trigger: .duration(seconds: restBetween),
                targetIntensity: .easy, repeatCount: max(numBlocks - 1, 1),
                notes: paceNote("Easy jog recovery", easyPace(paceProfile))
            ),
            IntervalPhase(
                id: UUID(), phaseType: .coolDown,
                trigger: .duration(seconds: coolDown),
                targetIntensity: .easy, repeatCount: 1,
                notes: paceNote("Cool-down", easyPace(paceProfile))
            ),
        ]

        let blockMins = Int(blockDuration / 60)
        return workout(
            name: "\(numBlocks)×\(blockMins) min MP long run",
            description: "Canova-style alternating blocks. Lock in marathon-pace effort \(numBlocks) times with easy recovery between.",
            phases: phases,
            totalDuration: totalDuration,
            paceProfile: paceProfile
        )
    }

    /// Half-and-half: 50% easy → 50% at race pace.
    private static func buildTwoPart(totalDuration: TimeInterval, paceProfile: RoadPaceProfile?) -> IntervalWorkout {
        let half = totalDuration / 2

        let phases = [
            IntervalPhase(
                id: UUID(), phaseType: .warmUp,
                trigger: .duration(seconds: half),
                targetIntensity: .easy, repeatCount: 1,
                notes: paceNote("Easy first half", easyPace(paceProfile))
            ),
            IntervalPhase(
                id: UUID(), phaseType: .work,
                trigger: .duration(seconds: half),
                targetIntensity: .hard, repeatCount: 1,
                notes: paceNote("Race pace second half", paceProfile?.racePacePerKm)
            ),
        ]
        return workout(
            name: "Two-part long run",
            description: "Easy first half, race pace second half.",
            phases: phases,
            totalDuration: totalDuration,
            paceProfile: paceProfile
        )
    }

    /// Race simulation: 5 min easy → long race-pace block (60-75%) → easy remainder.
    /// Block length grows with weekInPhase.
    private static func buildRaceSimulation(totalDuration: TimeInterval, paceProfile: RoadPaceProfile?, weekInPhase: Int) -> IntervalWorkout {
        let warmUp: TimeInterval = 5 * 60
        let coolMin: TimeInterval = 10 * 60

        // Race-pace block starts at 60% of available time, grows with weekInPhase
        let availableWork = totalDuration - warmUp - coolMin
        let blockFraction = min(0.75, 0.60 + Double(weekInPhase) * 0.05)
        let blockDuration = availableWork * blockFraction
        let coolDown = max(coolMin, totalDuration - warmUp - blockDuration)

        let phases = [
            IntervalPhase(
                id: UUID(), phaseType: .warmUp,
                trigger: .duration(seconds: warmUp),
                targetIntensity: .easy, repeatCount: 1,
                notes: paceNote("Easy warm-up", easyPace(paceProfile))
            ),
            IntervalPhase(
                id: UUID(), phaseType: .work,
                trigger: .duration(seconds: blockDuration),
                targetIntensity: .hard, repeatCount: 1,
                notes: paceNote("Race simulation — lock in race pace", paceProfile?.racePacePerKm)
            ),
            IntervalPhase(
                id: UUID(), phaseType: .coolDown,
                trigger: .duration(seconds: coolDown),
                targetIntensity: .easy, repeatCount: 1,
                notes: paceNote("Easy cool-down", easyPace(paceProfile))
            ),
        ]
        let blockMins = Int(blockDuration / 60)
        return workout(
            name: "Race simulation (\(blockMins) min at race pace)",
            description: "Full rehearsal: warm up, sustained race-pace block, cool down.",
            phases: phases,
            totalDuration: totalDuration,
            paceProfile: paceProfile
        )
    }

    // MARK: - Helpers

    private static func workout(
        name: String,
        description: String,
        phases: [IntervalPhase],
        totalDuration: TimeInterval,
        paceProfile: RoadPaceProfile?
    ) -> IntervalWorkout {
        let avgPace = paceProfile?.easyPacePerKm.lowerBound ?? 330
        let estKm = totalDuration / avgPace
        return IntervalWorkout(
            id: UUID(),
            name: name,
            descriptionText: description,
            phases: phases,
            category: .roadSpecific,
            estimatedDurationSeconds: totalDuration,
            estimatedDistanceKm: round(estKm * 10) / 10,
            isUserCreated: false
        )
    }

    private static func easyPace(_ profile: RoadPaceProfile?) -> Double? {
        profile?.easyPacePerKm.lowerBound
    }

    private static func paceNote(_ label: String, _ paceSecPerKm: Double?) -> String {
        guard let pace = paceSecPerKm else { return label }
        return "\(label) @ \(RoadCoachAdviceGenerator.formatPace(pace))/km"
    }
}
