import Foundation

/// Builds structured `IntervalWorkout` objects for road long-run variants.
///
/// Until RR-2 the long-run variant (`.marathonPaceBlocks`, `.progressive`,
/// `.fastFinish`, `.twoPart`, `.raceSimulation`) was rendered only as a
/// description string. The session itself had `intensity = .easy` and
/// `intervalWorkoutId = nil`, so the athlete saw no phase guidance, no
/// pace targets, and no auto-advance in ActiveRunView. This builder
/// produces real multi-phase workouts, a Pfitzinger "17 mi w/ 12 at MP"
/// or Canova "alternating 4 km easy / 3 km MP × 4" becomes an executable
/// structured workout that `IntervalGuidanceHandler` can drive.
///
/// User-facing names / descriptions / phase notes are localized via
/// `String(localized:)`; the English text is the `defaultValue`.
///
/// Research basis:
/// - **Pfitzinger**: MP segments in long runs grow progressively across
///   peak (8 → 10 → 12 → 14 mi at MP).
/// - **Canova**: alternating easy/MP blocks in the "specific long run"
///   mesocycle; block length extends weekly.
/// - **Daniels**: "2E + 14M + 1E", explicit pace segments, never just
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
            return buildProgressive(totalDuration: totalDuration, paceProfile: paceProfile, weekInPhase: weekInPhase)
        case .fastFinish:
            return buildFastFinish(totalDuration: totalDuration, paceProfile: paceProfile)
        case .marathonPaceIntro:
            return buildMarathonPaceIntro(totalDuration: totalDuration, paceProfile: paceProfile)
        case .marathonPaceBlocks:
            return buildMarathonPaceBlocks(totalDuration: totalDuration, paceProfile: paceProfile, weekInPhase: weekInPhase)
        case .twoPart:
            return buildTwoPart(totalDuration: totalDuration, paceProfile: paceProfile)
        case .raceSimulation:
            return buildRaceSimulation(totalDuration: totalDuration, paceProfile: paceProfile, weekInPhase: weekInPhase)
        }
    }

    /// Late-build MP intro: warm easy → single 15-20 min MP block near
    /// the end → easy cool-down. Half the dose of `.marathonPaceBlocks`
    /// so the athlete sees marathon pace once before peak ramps to
    /// 3 × 12-20 min blocks.
    private static func buildMarathonPaceIntro(totalDuration: TimeInterval, paceProfile: RoadPaceProfile?) -> IntervalWorkout {
        let blockDuration: TimeInterval = min(20 * 60, max(15 * 60, totalDuration * 0.20))
        let coolDown: TimeInterval = 10 * 60
        let warmUp: TimeInterval = max(0, totalDuration - blockDuration - coolDown)

        let phases = [
            IntervalPhase(
                id: UUID(), phaseType: .warmUp,
                trigger: .duration(seconds: warmUp),
                targetIntensity: .easy, repeatCount: 1,
                notes: paceNote(String(localized: "roadLR.note.easyBuildup", defaultValue: "Easy build-up"), easyPace(paceProfile))
            ),
            IntervalPhase(
                id: UUID(), phaseType: .work,
                trigger: .duration(seconds: blockDuration),
                targetIntensity: .moderate, repeatCount: 1,
                notes: paceNote(String(localized: "roadLR.note.mpBlock", defaultValue: "Marathon pace block, controlled, not surge"), paceProfile?.marathonPacePerKm)
            ),
            IntervalPhase(
                id: UUID(), phaseType: .coolDown,
                trigger: .duration(seconds: coolDown),
                targetIntensity: .easy, repeatCount: 1,
                notes: paceNote(String(localized: "roadLR.note.easyCooldown", defaultValue: "Easy cool-down"), easyPace(paceProfile))
            ),
        ]
        let blockMins = Int(blockDuration / 60)
        return workout(
            name: String(localized: "roadLR.name.mpIntro", defaultValue: "MP intro long run (\(blockMins) min @ MP)"),
            description: String(localized: "roadLR.desc.mpIntro", defaultValue: "Easy throughout, then a single \(blockMins)-minute marathon-pace block near the end. Locks in MP feel before peak."),
            phases: phases,
            totalDuration: totalDuration,
            paceProfile: paceProfile
        )
    }

    // MARK: - Variants

    /// Progressive: a true continuous build — ease in, settle into marathon
    /// pace, lift to the harder half-marathon (threshold) effort, then flush
    /// out easy. The pace *rises* the whole way and finishes on the hardest
    /// block, which is the SHORTEST (the faster the pace, the less time held);
    /// MP gets roughly 1.8× the threshold duration. A long run never ends on
    /// intensity, so a 5 min easy cool-down is reserved.
    ///
    /// The quality dose scales with `weekInPhase` so an early base week stays
    /// mostly aerobic (~25% quality) and a mature block reaches ~38%.
    private static func buildProgressive(totalDuration: TimeInterval, paceProfile: RoadPaceProfile?, weekInPhase: Int) -> IntervalWorkout {
        let coolDown: TimeInterval = 5 * 60

        // Total quality share grows as the block matures, capped. Split ~64% MP
        // / ~36% threshold, so MP (more sustainable) gets the larger share and
        // the harder threshold block is the short, hard finish.
        let maturity = Double(min(max(weekInPhase, 0), 6))
        let qualityFraction = min(0.38, 0.25 + maturity * 0.025)   // 0.25 → 0.38
        let mpPart  = totalDuration * qualityFraction * 0.64
        let thrPart = totalDuration * qualityFraction * 0.36
        let easyPart = max(0, totalDuration - mpPart - thrPart - coolDown)

        let phases = [
            IntervalPhase(
                id: UUID(), phaseType: .warmUp,
                trigger: .duration(seconds: easyPart),
                targetIntensity: .easy, repeatCount: 1,
                notes: paceNote(String(localized: "roadLR.note.easyPace", defaultValue: "Easy pace"), easyPace(paceProfile))
            ),
            IntervalPhase(
                id: UUID(), phaseType: .work,
                trigger: .duration(seconds: mpPart),
                targetIntensity: .moderate, repeatCount: 1,
                notes: paceNote(String(localized: "roadLR.note.mp", defaultValue: "Marathon pace"), paceProfile?.marathonPacePerKm)
            ),
            IntervalPhase(
                id: UUID(), phaseType: .work,
                trigger: .duration(seconds: thrPart),
                targetIntensity: .hard, repeatCount: 1,
                notes: paceNote(String(localized: "roadLR.note.hmEffort", defaultValue: "Half-marathon effort"), paceProfile?.thresholdPacePerKm)
            ),
            IntervalPhase(
                id: UUID(), phaseType: .coolDown,
                trigger: .duration(seconds: coolDown),
                targetIntensity: .easy, repeatCount: 1,
                notes: paceNote(String(localized: "roadLR.note.easyCooldown", defaultValue: "Easy cool-down"), easyPace(paceProfile))
            ),
        ]
        return workout(
            name: String(localized: "roadLR.name.progressive", defaultValue: "Progressive long run"),
            description: String(localized: "roadLR.desc.progressive", defaultValue: "Ease in, settle into marathon pace, lift to half-marathon effort, then flush out easy."),
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
                notes: paceNote(String(localized: "roadLR.note.easyPace", defaultValue: "Easy pace"), easyPace(paceProfile))
            ),
            IntervalPhase(
                id: UUID(), phaseType: .work,
                trigger: .duration(seconds: racePart),
                targetIntensity: .hard, repeatCount: 1,
                notes: paceNote(String(localized: "roadLR.note.racePaceFinish", defaultValue: "Race pace finish"), paceProfile?.racePacePerKm)
            ),
        ]
        return workout(
            name: String(localized: "roadLR.name.fastFinish", defaultValue: "Fast-finish long run"),
            description: String(localized: "roadLR.desc.fastFinish", defaultValue: "Easy pace, then the last quarter at race pace."),
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
                notes: paceNote(String(localized: "roadLR.note.easyWarmup", defaultValue: "Easy warm-up"), easyPace(paceProfile))
            ),
            IntervalPhase(
                id: UUID(), phaseType: .work,
                trigger: .duration(seconds: blockDuration),
                targetIntensity: .moderate, repeatCount: numBlocks,
                notes: paceNote(String(localized: "roadLR.note.mp", defaultValue: "Marathon pace"), paceProfile?.marathonPacePerKm)
            ),
            IntervalPhase(
                id: UUID(), phaseType: .recovery,
                trigger: .duration(seconds: restBetween),
                targetIntensity: .easy, repeatCount: max(numBlocks - 1, 1),
                notes: paceNote(String(localized: "roadLR.note.easyJogRecovery", defaultValue: "Easy jog recovery"), easyPace(paceProfile))
            ),
            IntervalPhase(
                id: UUID(), phaseType: .coolDown,
                trigger: .duration(seconds: coolDown),
                targetIntensity: .easy, repeatCount: 1,
                notes: paceNote(String(localized: "roadLR.note.cooldown", defaultValue: "Cool-down"), easyPace(paceProfile))
            ),
        ]

        let blockMins = Int(blockDuration / 60)
        return workout(
            name: String(localized: "roadLR.name.mpBlocks", defaultValue: "\(numBlocks)×\(blockMins) min MP long run"),
            description: String(localized: "roadLR.desc.mpBlocks", defaultValue: "Alternating blocks of marathon-pace effort. Lock in race pace \(numBlocks) times with easy recovery between."),
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
                notes: paceNote(String(localized: "roadLR.note.easyFirstHalf", defaultValue: "Easy first half"), easyPace(paceProfile))
            ),
            IntervalPhase(
                id: UUID(), phaseType: .work,
                trigger: .duration(seconds: half),
                targetIntensity: .hard, repeatCount: 1,
                notes: paceNote(String(localized: "roadLR.note.racePaceSecondHalf", defaultValue: "Race pace second half"), paceProfile?.racePacePerKm)
            ),
        ]
        return workout(
            name: String(localized: "roadLR.name.twoPart", defaultValue: "Two-part long run"),
            description: String(localized: "roadLR.desc.twoPart", defaultValue: "Easy first half, race pace second half."),
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
                notes: paceNote(String(localized: "roadLR.note.easyWarmup", defaultValue: "Easy warm-up"), easyPace(paceProfile))
            ),
            IntervalPhase(
                id: UUID(), phaseType: .work,
                trigger: .duration(seconds: blockDuration),
                targetIntensity: .hard, repeatCount: 1,
                notes: paceNote(String(localized: "roadLR.note.raceSim", defaultValue: "Race simulation, lock in race pace"), paceProfile?.racePacePerKm)
            ),
            IntervalPhase(
                id: UUID(), phaseType: .coolDown,
                trigger: .duration(seconds: coolDown),
                targetIntensity: .easy, repeatCount: 1,
                notes: paceNote(String(localized: "roadLR.note.easyCooldown", defaultValue: "Easy cool-down"), easyPace(paceProfile))
            ),
        ]
        let blockMins = Int(blockDuration / 60)
        return workout(
            name: String(localized: "roadLR.name.raceSim", defaultValue: "Race simulation (\(blockMins) min at race pace)"),
            description: String(localized: "roadLR.desc.raceSim", defaultValue: "Full rehearsal: warm up, sustained race-pace block, cool down."),
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
            phases: tidyPhaseDurations(phases, totalDuration: totalDuration),
            category: .roadSpecific,
            estimatedDurationSeconds: totalDuration,
            estimatedDistanceKm: round(estKm * 10) / 10,
            isUserCreated: false
        )
    }

    /// Snap every timed phase to a whole minute so a long run never reads as
    /// "18min18s" — no coach writes odd seconds. The tiny rounding remainder is
    /// pushed back into the longest easy phase (warm-up/cool-down), which is
    /// minutes-or-hours long so the shift is invisible, keeping the total
    /// session time exact while the quality blocks stay clean whole minutes.
    private static func tidyPhaseDurations(_ phases: [IntervalPhase], totalDuration: TimeInterval) -> [IntervalPhase] {
        func seconds(_ phase: IntervalPhase) -> Double? {
            if case .duration(let s) = phase.trigger { return s }
            return nil
        }

        var result = phases
        for i in result.indices {
            guard let s = seconds(result[i]) else { continue }
            result[i].trigger = .duration(seconds: max(60, (s / 60).rounded() * 60))
        }

        // Absorb the rounding drift into the longest easy phase so the labelled
        // total duration is preserved to the second.
        let roundedTotal = result.reduce(0.0) { $0 + $1.totalDuration }
        let drift = totalDuration - roundedTotal
        if abs(drift) >= 1,
           let idx = result.indices
               .filter({ result[$0].targetIntensity == .easy && seconds(result[$0]) != nil })
               .max(by: { result[$0].totalDuration < result[$1].totalDuration }),
           case .duration(let s) = result[idx].trigger,
           result[idx].repeatCount > 0 {
            result[idx].trigger = .duration(seconds: max(60, s + drift / Double(result[idx].repeatCount)))
        }
        return result
    }

    private static func easyPace(_ profile: RoadPaceProfile?) -> Double? {
        profile?.easyPacePerKm.lowerBound
    }

    private static func paceNote(_ label: String, _ paceSecPerKm: Double?) -> String {
        guard let pace = paceSecPerKm else { return label }
        return "\(label) @ \(RoadCoachAdviceGenerator.formatPace(pace))/km"
    }
}
