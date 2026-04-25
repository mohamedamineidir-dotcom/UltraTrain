import Foundation

enum WorkoutProgressionEngine {

    // MARK: - Public

    static func workout(
        type: SessionType,
        phase: TrainingPhase,
        weekInPhase: Int,
        intensity: Intensity,
        totalDuration: TimeInterval,
        expectedRaceDuration: TimeInterval = 0,
        isB2BDay1: Bool = false,
        phaseFocus: PhaseFocus? = nil,
        progressionContext: ProgressionContext? = nil,
        isSecondarySession: Bool = false
    ) -> IntervalWorkout {
        let phases: [IntervalPhase]
        let name: String
        let description: String

        switch type {
        case .intervals:
            let template = intervalTemplate(
                phase: phase, weekInPhase: weekInPhase, intensity: intensity,
                phaseFocus: phaseFocus, progressionContext: progressionContext,
                isSecondary: isSecondarySession
            )
            phases = template.phases
            name = template.name
            description = template.description
        case .verticalGain:
            let template = verticalTemplate(
                phase: phase, weekInPhase: weekInPhase, intensity: intensity,
                phaseFocus: phaseFocus, progressionContext: progressionContext,
                isSecondary: isSecondarySession
            )
            phases = template.phases
            name = template.name
            description = template.description
        case .tempo:
            let template = tempoTemplate(phase: phase, weekInPhase: weekInPhase, intensity: intensity)
            phases = template.phases
            name = template.name
            description = template.description
        case .longRun where isB2BDay1:
            let template = b2bDay1Template(
                totalDuration: totalDuration,
                phase: phase,
                expectedRaceDuration: expectedRaceDuration
            )
            phases = template.phases
            name = template.name
            description = template.description
        case .longRun where phase == .peak && totalDuration >= 2 * 3600:
            let template = longRunPeakTemplate(totalDuration: totalDuration, expectedRaceDuration: expectedRaceDuration)
            phases = template.phases
            name = template.name
            description = template.description
        case .longRun:
            let template = longRunTemplate(totalDuration: totalDuration)
            phases = template.phases
            name = template.name
            description = template.description
        case .backToBack:
            let template = b2bDay2Template(totalDuration: totalDuration)
            phases = template.phases
            name = template.name
            description = template.description
        case .recovery:
            let template = recoveryRunTemplate(totalDuration: totalDuration)
            phases = template.phases
            name = template.name
            description = template.description
        case .race:
            return makeGenericWorkout(type: type, duration: totalDuration, intensity: .maxEffort)
        case .crossTraining, .rest, .strengthConditioning:
            return makeGenericWorkout(type: type, duration: totalDuration, intensity: intensity)
        }

        let totalDur = phases.reduce(0.0) { $0 + $1.totalDuration }
        let category: WorkoutCategory = type == .verticalGain ? .hillTraining
            : type == .longRun || type == .backToBack ? .trailSpecific
            : type == .recovery ? .recovery
            : .speedWork

        return IntervalWorkout(
            id: UUID(),
            name: name,
            descriptionText: description,
            phases: phases,
            category: category,
            estimatedDurationSeconds: totalDur,
            estimatedDistanceKm: 0,
            isUserCreated: false
        )
    }

    // MARK: - Recovery Run Template

    private static func recoveryRunTemplate(totalDuration: TimeInterval) -> WorkoutTemplate {
        let totalMin = Int(totalDuration) / 60
        let main = phase(.work, duration: totalDuration, intensity: .easy, reps: 1,
                         notes: "Easy conversational pace (Zone 2). Focus on recovery and blood flow.")
        return WorkoutTemplate(
            name: "Base Endurance",
            description: "Base Endurance: \(totalMin)min at conversational pace",
            phases: [main]
        )
    }

    // MARK: - Long Run Template (non-peak)

    private static func longRunTemplate(totalDuration: TimeInterval) -> WorkoutTemplate {
        let warmUpDuration: TimeInterval = min(900, totalDuration * 0.15)  // 15min or 15%
        let coolDownDuration: TimeInterval = min(600, totalDuration * 0.10) // 10min or 10%
        let mainDuration = max(totalDuration - warmUpDuration - coolDownDuration, 600)

        let warmUp = phase(.warmUp, duration: warmUpDuration, intensity: .easy, reps: 1,
                           notes: "Progressive warmup — start walking, build to easy jog")

        // Split main effort into nutrition segments (~45min each)
        let segmentLength: TimeInterval = 2700 // 45min
        let segmentCount = max(Int(mainDuration / segmentLength), 1)
        let actualSegment = mainDuration / Double(segmentCount)

        let main = phase(.work, duration: actualSegment, intensity: .easy, reps: segmentCount,
                         notes: segmentCount > 1
                             ? "Easy pace. Eat/drink at each segment break."
                             : "Easy pace throughout.")

        let coolDown = phase(.coolDown, duration: coolDownDuration, intensity: .easy, reps: 1,
                             notes: "Walk to cool down. Stretch. Refuel within 30min.")

        let totalMin = Int(totalDuration) / 60
        return WorkoutTemplate(
            name: "Long run",
            description: "Long run \(totalMin)min: warmup → \(segmentCount)×\(Int(actualSegment)/60)min → cooldown",
            phases: [warmUp, main, coolDown]
        )
    }

    // MARK: - B2B Day 1 Template

    private static func b2bDay1Template(
        totalDuration: TimeInterval,
        phase: TrainingPhase = .build,
        expectedRaceDuration: TimeInterval = 0
    ) -> WorkoutTemplate {
        // Peak phase gets race simulation embedded in B2B Day 1: race-
        // effort blocks with explicit easy recovery between them, exactly
        // the dress-rehearsal pattern the athlete is asked for. Build /
        // base keep the original negative-split shape — it's a
        // progression builder, not a race rehearsal.
        if phase == .peak && totalDuration >= 2 * 3600 {
            return b2bDay1PeakRaceSimTemplate(
                totalDuration: totalDuration,
                expectedRaceDuration: expectedRaceDuration
            )
        }

        let warmUpDuration: TimeInterval = min(900, totalDuration * 0.12)
        let coolDownDuration: TimeInterval = min(600, totalDuration * 0.08)
        let remaining = max(totalDuration - warmUpDuration - coolDownDuration, 1200)
        let negativeSplitDuration = remaining / 3
        let steadyDuration = remaining - negativeSplitDuration

        let warmUp = self.phase(.warmUp, duration: warmUpDuration, intensity: .easy, reps: 1,
                                notes: "Progressive warmup")
        let steady = self.phase(.work, duration: steadyDuration, intensity: .easy, reps: 1,
                                notes: "Steady effort at easy pace. Fuel consistently.")
        let negativeSplit = self.phase(.work, duration: negativeSplitDuration, intensity: .moderate, reps: 1,
                                       notes: "Negative split — build effort in the last third")
        let coolDown = self.phase(.coolDown, duration: coolDownDuration, intensity: .easy, reps: 1,
                                  notes: "Cool down. Refuel well — tomorrow runs on today's fatigue.")

        return WorkoutTemplate(
            name: "B2B Day 1",
            description: "B2B Day 1: warmup → steady → negative split last third → cooldown",
            phases: [warmUp, steady, negativeSplit, coolDown]
        )
    }

    /// Peak-phase B2B Day 1 with race-simulation blocks. Same rehearsal
    /// pattern as the single peak long run: easy aerobic surrounding
    /// 2 × race-effort blocks (≤ 90 min each) with 15 min easy recovery
    /// between. Day 2 still runs as the easy "running tired" session,
    /// so the B2B as a whole simulates: race effort on fresh legs, then
    /// long aerobic on tired legs the next day.
    private static func b2bDay1PeakRaceSimTemplate(
        totalDuration: TimeInterval,
        expectedRaceDuration: TimeInterval
    ) -> WorkoutTemplate {
        let warmUpDur: TimeInterval = min(1200, totalDuration * 0.10)
        let coolDownDur: TimeInterval = min(900, totalDuration * 0.07)
        let recoveryBetween: TimeInterval = 900 // 15 min between blocks
        let blockCount = 2

        let availableTime = max(totalDuration - warmUpDur - coolDownDur, 1800)
        let rawWorkPerBlock = totalDuration * 0.20
        let workPerBlock = max(900, min(5400, rawWorkPerBlock))

        let blocksTotal = workPerBlock * Double(blockCount) + recoveryBetween * Double(blockCount - 1)
        let easyFillTotal = max(0, availableTime - blocksTotal)
        let easyAfterFraction: Double = expectedRaceDuration >= 6 * 3600 ? 0.65 : 0.55
        let easyAfter = easyFillTotal * easyAfterFraction
        let easyBefore = easyFillTotal - easyAfter

        var phases: [IntervalPhase] = []
        phases.append(self.phase(.warmUp, duration: warmUpDur, intensity: .easy, reps: 1,
                                 notes: "Progressive warmup. Race-day morning routine if you can."))
        if easyBefore > 60 {
            phases.append(self.phase(.work, duration: easyBefore, intensity: .easy, reps: 1,
                                     notes: "Easy aerobic preamble. Fuel as you will on race day."))
        }
        phases.append(self.phase(.work, duration: workPerBlock, intensity: .moderate, reps: blockCount,
                                 notes: "Race effort. Full race kit, full fueling — this is the dress rehearsal before tomorrow's tired-legs day."))
        phases.append(self.phase(.recovery, duration: recoveryBetween, intensity: .easy, reps: 1,
                                 notes: "Easy jog between race blocks. Eat, drink, reset."))
        if easyAfter > 60 {
            phases.append(self.phase(.work, duration: easyAfter, intensity: .easy, reps: 1,
                                     notes: "Easy aerobic finish. Don't bury yourself — Day 2 still runs on this fatigue."))
        }
        phases.append(self.phase(.coolDown, duration: coolDownDur, intensity: .easy, reps: 1,
                                 notes: "Cool down. Refuel well — Day 2 starts now."))

        let workMin = Int(workPerBlock) / 60
        let desc = "B2B Day 1 race simulation: \(blockCount)×\(workMin) min at race effort with 15 min easy between, embedded in a long aerobic run."

        return WorkoutTemplate(
            name: "B2B Day 1 (race sim)",
            description: desc,
            phases: phases
        )
    }

    // MARK: - B2B Day 2 Template

    private static func b2bDay2Template(totalDuration: TimeInterval) -> WorkoutTemplate {
        let warmUpDuration: TimeInterval = min(1200, totalDuration * 0.15) // 20min extra-long
        let coolDownDuration: TimeInterval = min(600, totalDuration * 0.08)
        let remaining = max(totalDuration - warmUpDuration - coolDownDuration, 1200)
        let pushDuration = remaining * 0.20
        let mainDuration = remaining - pushDuration

        let warmUp = phase(.warmUp, duration: warmUpDuration, intensity: .easy, reps: 1,
                           notes: "Extra-long warmup on tired legs. Walk → jog → easy run.")
        let main = phase(.work, duration: mainDuration, intensity: .easy, reps: 1,
                         notes: "Steady fatigued effort at easy pace. Embrace the discomfort.")
        let push = phase(.work, duration: pushDuration, intensity: .moderate, reps: 1,
                         notes: "Push section — build to race effort in the last 20%")
        let coolDown = phase(.coolDown, duration: coolDownDuration, intensity: .easy, reps: 1,
                             notes: "Walk to cool down. Refuel immediately.")

        return WorkoutTemplate(
            name: "B2B Day 2",
            description: "B2B Day 2: warmup → fatigued effort → push last 20% → cooldown",
            phases: [warmUp, main, push, coolDown]
        )
    }

    // MARK: - Interval Templates

    private struct WorkoutTemplate {
        let name: String
        let description: String
        let phases: [IntervalPhase]
    }

    private static func intervalTemplate(
        phase trainingPhase: TrainingPhase,
        weekInPhase: Int,
        intensity: Intensity,
        phaseFocus: PhaseFocus? = nil,
        progressionContext: ProgressionContext? = nil,
        isSecondary: Bool = false
    ) -> WorkoutTemplate {
        let effectiveFocus = phaseFocus ?? trainingPhase.defaultFocus

        guard let ctx = progressionContext else {
            return legacyIntervalTemplate(
                effectiveFocus: effectiveFocus, weekInPhase: weekInPhase, intensity: intensity
            )
        }

        let warmUp = phase(.warmUp, duration: 900, intensity: .easy, reps: 1, notes: "Easy jog, progressive pace")
        let coolDown = phase(.coolDown, duration: 600, intensity: .easy, reps: 1, notes: "Easy jog, stretching")

        if effectiveFocus == .sharpening {
            if isSecondary {
                // Secondary sharpening: short race-effort strides
                return fixedIntervalTemplate(
                    reps: 6, workSec: 60, restSec: 90, focus: .sharpening,
                    warmUp: warmUp, coolDown: coolDown
                )
            }
            return fixedIntervalTemplate(
                reps: 4, workSec: 120, restSec: 120, focus: .sharpening,
                warmUp: warmUp, coolDown: coolDown
            )
        }
        if effectiveFocus == .postRaceRecovery {
            return fixedIntervalTemplate(
                reps: 5, workSec: 180, restSec: 120, focus: .postRaceRecovery,
                warmUp: warmUp, coolDown: coolDown
            )
        }

        let planProgress = Double(ctx.weekIndexInPlan) / max(Double(ctx.totalWeeks - 1), 1.0)
        let multiplier = intervalRaceScale(ctx.raceEffectiveKm)
            * experienceFactor(ctx.experience)
            * philosophyFactor(ctx.philosophy)

        let starterWork = 10.0 * 60.0 * multiplier
        let peakWork = 40.0 * 60.0 * multiplier
        let rawTotalWork = starterWork + (peakWork - starterWork) * planProgress
        let totalWorkSec = min(rawTotalWork, maxTotalWorkSeconds(for: effectiveFocus))

        let params = intervalFocusParams(effectiveFocus, planProgress: planProgress, experience: ctx.experience)

        if isSecondary {
            return secondaryIntervalTemplate(
                focus: effectiveFocus, params: params, totalWorkSec: totalWorkSec,
                weekInPhase: weekInPhase, warmUp: warmUp, coolDown: coolDown
            )
        }

        // Primary session with week-over-week progression variety
        let progressionMode = weekInPhase % 4
        let reps: Int
        let actualSetSec: Double
        let restSec: Double
        var sessionName = "Interval session"
        var workNotes: String?

        switch progressionMode {
        case 0:
            // Mode A: standard reps at target duration
            let targetSet = params.setDurationSec
            reps = min(max(Int((totalWorkSec / targetSet).rounded()), 2), params.maxReps)
            actualSetSec = roundToNearest15(totalWorkSec / Double(reps))
            restSec = roundToNearest15(actualSetSec / params.workRestRatio)
        case 1:
            // Mode B: longer reps, fewer of them (same total volume)
            let longerSet = params.setDurationSec * 1.35
            reps = min(max(Int((totalWorkSec / longerSet).rounded()), 2), max(params.maxReps - 2, 2))
            actualSetSec = roundToNearest15(totalWorkSec / Double(reps))
            restSec = roundToNearest15(actualSetSec / params.workRestRatio)
            sessionName = "Long intervals"
            workNotes = "Fewer reps, longer efforts. Build sustained power at this intensity."
        case 2:
            // Mode C: standard reps, phase-aware reduced rest
            let targetSet = params.setDurationSec
            reps = min(max(Int((totalWorkSec / targetSet).rounded()), 2), params.maxReps)
            actualSetSec = roundToNearest15(totalWorkSec / Double(reps))
            let restReduction = progressionRestReduction(for: effectiveFocus)
            restSec = roundToNearest15(actualSetSec / (params.workRestRatio * restReduction))
            sessionName = "Dense intervals"
            workNotes = "Reduced rest between reps. The accumulated fatigue is the point."
        default:
            // Mode D: alternating short/long reps (replaces fake pyramid)
            // Use shorter reps with slightly more of them for a different feel
            let shorterSet = params.setDurationSec * 0.75
            reps = min(max(Int((totalWorkSec / shorterSet).rounded()), 3), params.maxReps + 2)
            actualSetSec = roundToNearest15(totalWorkSec / Double(reps))
            restSec = roundToNearest15(actualSetSec / params.workRestRatio)
            sessionName = "Short & sharp intervals"
            workNotes = "More reps, shorter efforts. Focus on crisp execution each rep."
        }

        let desc = formatIntervalDescription(
            reps: reps, workSec: actualSetSec, restSec: restSec, focus: effectiveFocus
        )

        let work = self.phase(.work, duration: actualSetSec, intensity: params.intensity, reps: reps, notes: workNotes)
        let recovery = self.phase(.recovery, duration: restSec, intensity: .easy, reps: reps, notes: nil)

        return WorkoutTemplate(name: sessionName, description: desc, phases: [warmUp, work, recovery, coolDown])
    }

    /// Secondary interval session: different mechanical stimulus, same energy system.
    private static func secondaryIntervalTemplate(
        focus: PhaseFocus,
        params: FocusParams,
        totalWorkSec: Double,
        weekInPhase: Int,
        warmUp: IntervalPhase,
        coolDown: IntervalPhase
    ) -> WorkoutTemplate {
        let secondaryWork = totalWorkSec * 0.85 // slightly less total volume

        switch focus {
        case .threshold30:
            // Shorter reps, denser structure, same threshold zone
            let repSec: Double = 45
            let reps = min(max(Int((secondaryWork / repSec).rounded()), 4), 16)
            let actualRep = roundToNearest15(secondaryWork / Double(reps))
            let rest = roundToNearest15(actualRep * 0.75) // shorter rest than primary
            let desc = "\(reps)x\(Int(actualRep))s threshold (Z3-4) / \(Int(rest))s jog"
            let work = phase(.work, duration: actualRep, intensity: .hard, reps: reps,
                            notes: "Short and sharp. Stay in threshold zone but keep the tempo high.")
            let recovery = phase(.recovery, duration: rest, intensity: .easy, reps: reps, notes: nil)
            return WorkoutTemplate(name: "Threshold repeats", description: desc, phases: [warmUp, work, recovery, coolDown])

        case .vo2max:
            // Shorter bursts at higher intensity (VMA zone, 30-90s)
            let repSec: Double = 30 + Double(weekInPhase % 3) * 30 // 30s, 60s, or 90s
            let reps = min(max(Int((secondaryWork / repSec).rounded()), 4), 14)
            let actualRep = roundToNearest15(secondaryWork / Double(reps))
            let rest = roundToNearest15(actualRep * 1.5) // longer rest for higher intensity
            let desc = "\(reps)x\(Int(actualRep))s at VMA (Z5) / \(Int(rest))s jog"
            let work = phase(.work, duration: actualRep, intensity: .maxEffort, reps: reps,
                            notes: "Max effort bursts. These are short for a reason. Go hard.")
            let recovery = phase(.recovery, duration: rest, intensity: .easy, reps: reps, notes: nil)
            return WorkoutTemplate(name: "VMA bursts", description: desc, phases: [warmUp, work, recovery, coolDown])

        case .threshold60:
            // Fragmented into shorter blocks with reduced rest
            let repSec: Double = 180 // 3min blocks instead of 6-8min
            let reps = min(max(Int((secondaryWork / repSec).rounded()), 3), 10)
            let actualRep = roundToNearest15(secondaryWork / Double(reps))
            let rest: Double = 60 // short rest to keep intensity high
            let desc = "\(reps)x\(Int(actualRep/60))min threshold / 1min jog"
            let work = phase(.work, duration: actualRep, intensity: .moderate, reps: reps,
                            notes: "Shorter blocks, less rest. The accumulated fatigue builds threshold endurance differently than long reps.")
            let recovery = phase(.recovery, duration: rest, intensity: .easy, reps: reps, notes: nil)
            return WorkoutTemplate(name: "Tempo fragments", description: desc, phases: [warmUp, work, recovery, coolDown])

        case .sharpening:
            let desc = "6x1min race effort / 1:30 jog"
            let work = phase(.work, duration: 60, intensity: .hard, reps: 6, notes: "Race effort strides. Stay smooth.")
            let recovery = phase(.recovery, duration: 90, intensity: .easy, reps: 6, notes: nil)
            return WorkoutTemplate(name: "Race strides", description: desc, phases: [warmUp, work, recovery, coolDown])

        case .postRaceRecovery:
            let desc = "4x2min easy tempo / 2min jog"
            let work = phase(.work, duration: 120, intensity: .easy, reps: 4, notes: "Gentle tempo. Just waking the legs up.")
            let recovery = phase(.recovery, duration: 120, intensity: .easy, reps: 4, notes: nil)
            return WorkoutTemplate(name: "Recovery tempo", description: desc, phases: [warmUp, work, recovery, coolDown])
        }
    }

    private static func fixedIntervalTemplate(
        reps: Int, workSec: Double, restSec: Double, focus: PhaseFocus,
        warmUp: IntervalPhase, coolDown: IntervalPhase
    ) -> WorkoutTemplate {
        let params = intervalFocusParams(focus, planProgress: 0)
        let desc = formatIntervalDescription(reps: reps, workSec: workSec, restSec: restSec, focus: focus)
        let work = phase(.work, duration: workSec, intensity: params.intensity, reps: reps, notes: nil)
        let recovery = phase(.recovery, duration: restSec, intensity: .easy, reps: reps, notes: nil)
        return WorkoutTemplate(name: "Interval session", description: desc, phases: [warmUp, work, recovery, coolDown])
    }

    // MARK: - Legacy Interval Template (backward compat when no ProgressionContext)

    private static func legacyIntervalTemplate(
        effectiveFocus: PhaseFocus,
        weekInPhase: Int,
        intensity: Intensity
    ) -> WorkoutTemplate {
        let warmUp = phase(.warmUp, duration: 900, intensity: .easy, reps: 1, notes: "Easy jog, progressive pace")
        let coolDown = phase(.coolDown, duration: 600, intensity: .easy, reps: 1, notes: "Easy jog, stretching")

        let workPhases: (reps: Int, workSec: Double, restSec: Double, desc: String)

        switch effectiveFocus {
        case .threshold30:
            let variants: [(Int, Double, Double, String)] = [
                (8,  30,  30, "8×30s hard uphill (Z4) / 30s jog down"),
                (6,  60,  90, "6×1min uphill at threshold (Z3-4) / 1:30 jog"),
                (6, 120, 150, "6×2min uphill at threshold (Z3-4) / 2:30 jog"),
                (8,  90, 120, "8×1:30 uphill at threshold (Z3-4) / 2min jog"),
                (10, 60,  60, "10×1min hard uphill (Z4) / 1min jog down"),
                (7, 150, 150, "7×2:30 uphill at threshold (Z3-4) / 2:30 jog"),
            ]
            workPhases = variants[min(weekInPhase, variants.count - 1)]
        case .vo2max:
            let variants: [(Int, Double, Double, String)] = [
                (6, 180, 120, "6×3min at VO2max (Z4) / 2min jog"),
                (7, 180, 90,  "7×3min at VO2max (Z4) / 90s jog"),
                (5, 240, 120, "5×4min at VO2max (Z4) / 2min jog"),
                (8, 150, 90,  "8×2min30 at VO2max (Z4) / 90s jog"),
                (6, 240, 120, "6×4min at VO2max (Z4) / 2min jog"),
                (10, 120, 60, "10×2min at VO2max (Z4) / 1min jog"),
            ]
            workPhases = variants[weekInPhase % variants.count]
        case .threshold60:
            let variants: [(Int, Double, Double, String)] = [
                (5, 180,  90, "5×3min at threshold (Z3-4) / 1:30 jog"),
                (6, 240, 120, "6×4min at threshold (Z3-4) / 2min jog"),
                (4, 360, 120, "4×6min at threshold (Z3-4) / 2min jog"),
                (8, 240, 120, "8×4min at threshold (Z3-4) / 2min jog"),
                (5, 480, 150, "5×8min at threshold (Z3-4) / 2:30 jog"),
                (3, 600, 180, "3×10min at threshold (Z3-4) / 3min jog"),
            ]
            workPhases = variants[weekInPhase % variants.count]
        case .sharpening:
            workPhases = (4, 120, 120, "4×2min at threshold (Z3) / 2min jog")
        case .postRaceRecovery:
            workPhases = (5, 180, 120, "5×3min at threshold (Z3) / 2min jog")
        }

        let work = self.phase(.work, duration: workPhases.workSec, intensity: intensity, reps: workPhases.reps, notes: nil)
        let recovery = self.phase(.recovery, duration: workPhases.restSec, intensity: .easy, reps: workPhases.reps, notes: nil)

        return WorkoutTemplate(
            name: "Interval session",
            description: workPhases.desc,
            phases: [warmUp, work, recovery, coolDown]
        )
    }

    // MARK: - Vertical Gain Templates

    private static func verticalTemplate(
        phase trainingPhase: TrainingPhase,
        weekInPhase: Int,
        intensity: Intensity,
        phaseFocus: PhaseFocus? = nil,
        progressionContext: ProgressionContext? = nil,
        isSecondary: Bool = false
    ) -> WorkoutTemplate {
        let effectiveFocus = phaseFocus ?? trainingPhase.defaultFocus

        guard let ctx = progressionContext else {
            return legacyVerticalTemplate(
                trainingPhase: trainingPhase, weekInPhase: weekInPhase, intensity: intensity
            )
        }

        let warmUp = phase(.warmUp, duration: 900, intensity: .easy, reps: 1, notes: "Easy jog to the climb")
        let coolDown = phase(.coolDown, duration: 600, intensity: .easy, reps: 1, notes: "Easy jog back, stretching")

        // Fixed templates for sharpening / recovery
        if effectiveFocus == .sharpening {
            return fixedVGTemplate(
                reps: 3, workSec: 180, restSec: 180, focus: .sharpening,
                warmUp: warmUp, coolDown: coolDown
            )
        }
        if effectiveFocus == .postRaceRecovery {
            return fixedVGTemplate(
                reps: 2, workSec: 240, restSec: 240, focus: .postRaceRecovery,
                warmUp: warmUp, coolDown: coolDown
            )
        }

        let planProgress = Double(ctx.weekIndexInPlan) / max(Double(ctx.totalWeeks - 1), 1.0)
        let elevDensity = vgElevDensityFactor(elevationGainM: ctx.raceElevationGainM, effectiveKm: ctx.raceEffectiveKm)
        let vgMultiplier = intervalRaceScale(ctx.raceEffectiveKm)
            * experienceFactor(ctx.experience)
            * philosophyFactor(ctx.philosophy)
            * elevDensity

        let starterWork = 12.0 * 60.0 * vgMultiplier
        let peakWork = 36.0 * 60.0 * vgMultiplier
        let rawTotalWork = starterWork + (peakWork - starterWork) * planProgress
        let totalWorkSec = min(rawTotalWork, maxTotalWorkSeconds(for: effectiveFocus))

        let params = vgFocusParams(effectiveFocus, planProgress: planProgress, experience: ctx.experience)

        if isSecondary {
            // Secondary VG: shorter, steeper reps with higher density
            let secondaryWork = totalWorkSec * 0.85
            let shortRepSec = max(params.setDurationSec * 0.6, 60)
            let reps = min(max(Int((secondaryWork / shortRepSec).rounded()), 3), params.maxReps + 2)
            let actualSetSec = roundToNearest15(secondaryWork / Double(reps))
            let restSec = roundToNearest15(actualSetSec * 0.8)
            let desc = formatVGDescription(reps: reps, workSec: actualSetSec, restSec: restSec, focus: effectiveFocus)
            let work = self.phase(.work, duration: actualSetSec, intensity: params.intensity, reps: reps,
                                 notes: "Shorter, punchier climbs. Higher cadence than your primary session.")
            let recovery = self.phase(.recovery, duration: restSec, intensity: .easy, reps: reps, notes: "Quick descent")
            return WorkoutTemplate(name: "Hill repeats (short)", description: desc, phases: [warmUp, work, recovery, coolDown])
        }

        // Primary VG session with week-over-week progression variety
        let progressionMode = ctx.weekIndexInPlan % 4
        let reps: Int
        let actualSetSec: Double
        let restSec: Double
        var vgName = vgWorkoutName(for: effectiveFocus)
        var climbNotes = "Climb at steady effort"
        var descentNotes = "Jog/walk descent"
        var includesDownhill = false

        switch progressionMode {
        case 0:
            // Mode A: standard climb reps
            let targetSet = params.setDurationSec
            reps = min(max(Int((totalWorkSec / targetSet).rounded()), 2), params.maxReps)
            actualSetSec = roundToNearest15(totalWorkSec / Double(reps))
            restSec = roundToNearest15(actualSetSec / params.workRestRatio)
        case 1:
            // Mode B: longer sustained climbs, fewer reps
            let longerSet = params.setDurationSec * 1.3
            reps = min(max(Int((totalWorkSec / longerSet).rounded()), 2), max(params.maxReps - 1, 2))
            actualSetSec = roundToNearest15(totalWorkSec / Double(reps))
            restSec = roundToNearest15(actualSetSec / params.workRestRatio)
            vgName = "Long hill repeats"
            climbNotes = "Sustained climbing. Longer reps build endurance for race-day climbs."
        case 2:
            // Mode C: reduced rest (phase-aware)
            let targetSet = params.setDurationSec
            reps = min(max(Int((totalWorkSec / targetSet).rounded()), 2), params.maxReps)
            actualSetSec = roundToNearest15(totalWorkSec / Double(reps))
            let restReduction = progressionRestReduction(for: effectiveFocus)
            restSec = roundToNearest15(actualSetSec / (params.workRestRatio * restReduction))
            climbNotes = "Shorter rest between climbs. Accumulated fatigue builds climbing endurance."
        default:
            // Mode D: Up+Down combo (build/peak) or short reps (base)
            // For build/peak: integrated downhill training
            if (trainingPhase == .build || trainingPhase == .peak)
                && ctx.experience != .beginner {
                // Up+Down reps: climb hard, descend fast
                let targetSet = params.setDurationSec * 0.85
                reps = min(max(Int((totalWorkSec / targetSet).rounded()), 2), params.maxReps)
                actualSetSec = roundToNearest15(totalWorkSec / Double(reps))
                let downhillSec = roundToNearest15(actualSetSec * 0.7)
                restSec = roundToNearest15(max(downhillSec * 0.5, 60))
                includesDownhill = true
                vgName = "Up + Down hill repeats"
                climbNotes = "Hard climb, then fast controlled descent. This builds the eccentric quad strength you need for race-day descents."
                descentNotes = "Run the descent with purpose. Controlled speed, light feet. Then jog \(Int(restSec/60))min recovery."
            } else {
                // Base phase: shorter punchier climbs
                let shorterSet = params.setDurationSec * 0.75
                reps = min(max(Int((totalWorkSec / shorterSet).rounded()), 3), params.maxReps + 2)
                actualSetSec = roundToNearest15(totalWorkSec / Double(reps))
                restSec = roundToNearest15(actualSetSec / params.workRestRatio)
                vgName = "Short hill repeats"
                climbNotes = "More reps, shorter climbs. Focus on quick powerful steps."
            }
        }

        let desc = formatVGDescription(reps: reps, workSec: actualSetSec, restSec: restSec, focus: effectiveFocus)
        let work = self.phase(.work, duration: actualSetSec, intensity: params.intensity, reps: reps, notes: climbNotes)
        let recovery = self.phase(.recovery, duration: restSec, intensity: .easy, reps: reps, notes: descentNotes)

        return WorkoutTemplate(name: vgName, description: desc, phases: [warmUp, work, recovery, coolDown])
    }

    private static func fixedVGTemplate(
        reps: Int, workSec: Double, restSec: Double, focus: PhaseFocus,
        warmUp: IntervalPhase, coolDown: IntervalPhase
    ) -> WorkoutTemplate {
        let params = vgFocusParams(focus, planProgress: 0)
        let desc = formatVGDescription(reps: reps, workSec: workSec, restSec: restSec, focus: focus)
        let work = phase(.work, duration: workSec, intensity: params.intensity, reps: reps, notes: "Climb at steady effort")
        let recovery = phase(.recovery, duration: restSec, intensity: .easy, reps: reps, notes: "Jog/walk descent")
        return WorkoutTemplate(name: vgWorkoutName(for: focus), description: desc, phases: [warmUp, work, recovery, coolDown])
    }

    private static func vgWorkoutName(for focus: PhaseFocus) -> String {
        switch focus {
        case .threshold30:      "Aerobic climbing"
        case .vo2max:           "Hill repeats"
        case .threshold60:      "Endurance climbing"
        case .sharpening:       "Maintenance climbing"
        case .postRaceRecovery: "Easy climbing"
        }
    }

    // MARK: - Legacy Vertical Template (backward compat when no ProgressionContext)

    private static func legacyVerticalTemplate(
        trainingPhase: TrainingPhase, weekInPhase: Int, intensity: Intensity
    ) -> WorkoutTemplate {
        let warmUp = phase(.warmUp, duration: 900, intensity: .easy, reps: 1, notes: "Easy jog to the climb")
        let coolDown = phase(.coolDown, duration: 600, intensity: .easy, reps: 1, notes: "Easy jog back, stretching")

        let workPhases: (reps: Int, workSec: Double, restSec: Double, desc: String, name: String)

        switch trainingPhase {
        case .base:
            switch weekInPhase {
            case 0...1:
                workPhases = (3, 480, 300, "3×8min climb at threshold (Z3) / 5min jog down", "Aerobic climbing")
            case 2...3:
                workPhases = (4, 480, 300, "4×8min climb at threshold (Z3) / 5min jog down", "Aerobic climbing")
            case 4...5:
                workPhases = (4, 600, 360, "4×10min climb at threshold (Z3) / 6min jog down", "Endurance climbing")
            default:
                workPhases = (5, 600, 360, "5×10min climb at threshold (Z3) / 6min jog down", "Endurance climbing")
            }
        case .build:
            switch weekInPhase {
            case 0...1:
                workPhases = (4, 240, 180, "4×4min climb at VO2max (Z4) / 3min jog down", "Hill repeats")
            case 2...3:
                workPhases = (5, 240, 180, "5×4min climb at VO2max (Z4) / 3min jog down", "Hill repeats")
            case 4...5:
                workPhases = (6, 180, 120, "6×3min steep climb at VO2max (Z4) / 2min jog down", "Steep repeats")
            default:
                workPhases = (7, 180, 120, "7×3min steep climb at VO2max (Z4) / 2min jog down", "Steep repeats")
            }
        case .peak:
            switch weekInPhase {
            case 0...1:
                workPhases = (6, 180, 120, "6×3min climb at VO2max (Z4) / 2min jog down", "Power climbing")
            case 2...3:
                workPhases = (8, 120, 120, "8×2min max effort climb (Z5) / 2min jog down", "Max effort climbing")
            default:
                workPhases = (10, 90, 90, "10×90s max effort climb (Z5) / 90s jog down", "Sprint climbing")
            }
        case .taper:
            workPhases = (3, 180, 180, "3×3min climb at threshold (Z3) / 3min jog down", "Maintenance climbing")
        case .recovery, .race:
            workPhases = (2, 240, 240, "2×4min easy climb (Z2) / 4min jog down", "Easy climbing")
        }

        let workIntensity: Intensity = (trainingPhase == .base || trainingPhase == .recovery) ? .moderate : intensity
        let work = self.phase(.work, duration: workPhases.workSec, intensity: workIntensity, reps: workPhases.reps, notes: "Climb at steady effort")
        let recovery = self.phase(.recovery, duration: workPhases.restSec, intensity: .easy, reps: workPhases.reps, notes: "Jog/walk descent")

        return WorkoutTemplate(
            name: workPhases.name,
            description: workPhases.desc,
            phases: [warmUp, work, recovery, coolDown]
        )
    }

    // MARK: - Tempo Templates

    private static func tempoTemplate(phase trainingPhase: TrainingPhase, weekInPhase: Int, intensity: Intensity) -> WorkoutTemplate {
        let warmUp = phase(.warmUp, duration: 900, intensity: .easy, reps: 1, notes: "Easy jog, build gradually")
        let coolDown = phase(.coolDown, duration: 600, intensity: .easy, reps: 1, notes: "Easy jog, stretching")

        let workPhases: (reps: Int, workSec: Double, restSec: Double, desc: String, name: String)

        switch trainingPhase {
        case .base:
            let variants: [(Int, Double, Double, String, String)] = [
                (2, 600, 180, "2×10min at threshold (Z3) / 3min jog", "Threshold tempo"),
                (2, 720, 180, "2×12min at threshold (Z3) / 3min jog", "Threshold tempo"),
                (2, 900, 300, "2×15min at threshold (Z3) / 5min jog", "Sustained tempo"),
                (2, 900, 240, "2×15min at threshold (Z3) / 4min jog", "Sustained tempo"),
                (3, 600, 180, "3×10min at threshold (Z3) / 3min jog", "Sustained tempo"),
                (2, 1200, 300, "2×20min at threshold (Z3) / 5min jog", "Long tempo"),
            ]
            workPhases = variants[min(weekInPhase, variants.count - 1)]

        case .build:
            let variants: [(Int, Double, Double, String, String)] = [
                (2, 1200, 300, "2×20min at tempo (Z3-Z4) / 5min jog", "Tempo run"),
                (3, 900, 240, "3×15min at tempo (Z3-Z4) / 4min jog", "Tempo run"),
                (2, 1500, 300, "2×25min at tempo (Z3-Z4) / 5min jog", "Long tempo"),
                (3, 1200, 300, "3×20min at tempo (Z3-Z4) / 5min jog", "Long tempo"),
            ]
            workPhases = variants[weekInPhase % variants.count]

        case .peak:
            let variants: [(Int, Double, Double, String, String)] = [
                (3, 600, 180, "3×10min at race pace (Z4) / 3min jog", "Race-pace tempo"),
                (4, 480, 150, "4×8min at race pace (Z4) / 2min30 jog", "Race-pace tempo"),
                (3, 720, 180, "3×12min at race pace (Z4) / 3min jog", "Race-pace tempo"),
            ]
            workPhases = variants[weekInPhase % variants.count]

        case .taper:
            workPhases = (1, 900, 0, "1×15min at threshold (Z3)", "Maintenance tempo")

        default:
            workPhases = (2, 600, 180, "2×10min at threshold (Z3) / 3min jog", "Threshold tempo")
        }

        let work = self.phase(.work, duration: workPhases.workSec, intensity: intensity, reps: workPhases.reps, notes: nil)
        let recovery: IntervalPhase? = workPhases.restSec > 0
            ? self.phase(.recovery, duration: workPhases.restSec, intensity: .easy, reps: max(workPhases.reps - 1, 1), notes: nil)
            : nil

        var phases = [warmUp, work]
        if let recovery { phases.append(recovery) }
        phases.append(coolDown)

        return WorkoutTemplate(
            name: workPhases.name,
            description: workPhases.desc,
            phases: phases
        )
    }

    // MARK: - Long Run Peak Template

    private static func longRunPeakTemplate(totalDuration: TimeInterval, expectedRaceDuration: TimeInterval) -> WorkoutTemplate {
        // Race-simulation embedded blocks. Replaces the previous "2 ×
        // (most-of-available-time)" structure that produced absurd
        // 200-minute work blocks on long peak runs. New shape:
        // warmup → easy-aerobic-block → 2 race-effort blocks (≤ 90 min
        // each) with 15 min easy recovery between → easy-aerobic-block
        // → cooldown. Athlete spends most of the run in pure aerobic
        // territory and gets two clear race-pace efforts in the middle
        // — exactly the dress-rehearsal pattern (Krar / Roche).
        let warmUpDur: TimeInterval = 1800   // 30 min
        let coolDownDur: TimeInterval = 1200 // 20 min
        let recoveryBetween: TimeInterval = 900 // 15 min between blocks
        let blockCount = 2

        let availableTime = max(totalDuration - warmUpDur - coolDownDur, 1800)

        // Block duration: 20% of total run time, capped at 90 min, floor 15.
        // 8h run → 90 min/block; 4h run → 48 min/block; 2h run → 24 min/block.
        let rawWorkPerBlock = totalDuration * 0.20
        let workPerBlock = max(900, min(5400, rawWorkPerBlock))

        // Easy aerobic fill split before / after the race blocks. If race
        // duration is known and ≥ 6h, we keep the after-fill larger so the
        // athlete practises running tired.
        let blocksTotal = workPerBlock * Double(blockCount) + recoveryBetween * Double(blockCount - 1)
        let easyFillTotal = max(0, availableTime - blocksTotal)
        let practiseLongTail = expectedRaceDuration >= 6 * 3600
        let easyAfterFraction: Double = practiseLongTail ? 0.65 : 0.50
        let easyAfter = easyFillTotal * easyAfterFraction
        let easyBefore = easyFillTotal - easyAfter

        var phases: [IntervalPhase] = []
        phases.append(phase(.warmUp, duration: warmUpDur, intensity: .easy, reps: 1,
                            notes: "Easy warmup, settle in"))
        if easyBefore > 60 {
            phases.append(phase(.work, duration: easyBefore, intensity: .easy, reps: 1,
                                notes: "Long easy aerobic block before race blocks. Fuel as you would on race day."))
        }
        phases.append(phase(.work, duration: workPerBlock, intensity: .moderate, reps: blockCount,
                            notes: "Race effort — full kit, full fueling, hold steady. This is the dress rehearsal."))
        phases.append(phase(.recovery, duration: recoveryBetween, intensity: .easy, reps: 1,
                            notes: "Easy jog between race blocks, recover before the next one"))
        if easyAfter > 60 {
            phases.append(phase(.work, duration: easyAfter, intensity: .easy, reps: 1,
                                notes: "Easy running on tired legs — practice late-race execution."))
        }
        phases.append(phase(.coolDown, duration: coolDownDur, intensity: .easy, reps: 1,
                            notes: "Cool down. Note what worked: gear, fueling, pacing."))

        let workMin = Int(workPerBlock) / 60
        let desc = "Race simulation: \(blockCount)×\(workMin) min at race effort with 15 min easy between, embedded in a long aerobic run."

        return WorkoutTemplate(
            name: "Race simulation long run",
            description: desc,
            phases: phases
        )
    }

    // MARK: - Helpers

    private static func phase(
        _ type: IntervalPhaseType,
        duration: TimeInterval,
        intensity: Intensity,
        reps: Int,
        notes: String?
    ) -> IntervalPhase {
        IntervalPhase(
            id: UUID(),
            phaseType: type,
            trigger: .duration(seconds: duration),
            targetIntensity: intensity,
            repeatCount: reps,
            notes: notes
        )
    }

    private static func makeGenericWorkout(type: SessionType, duration: TimeInterval, intensity: Intensity) -> IntervalWorkout {
        let work = phase(.work, duration: duration, intensity: intensity, reps: 1, notes: nil)
        return IntervalWorkout(
            id: UUID(),
            name: type.displayName,
            descriptionText: "Steady \(intensity.displayName) effort",
            phases: [work],
            category: type == .recovery ? .recovery : .trailSpecific,
            estimatedDurationSeconds: duration,
            estimatedDistanceKm: 0,
            isUserCreated: false
        )
    }
}
