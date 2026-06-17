import Foundation

/// Builds a training plan for an athlete who is NOT preparing for a race.
///
/// Unlike a race plan, there is no peak / taper / race / post-race recovery —
/// those only make sense with a goal event. Instead this is what coaches
/// prescribe for off-season / general fitness: a sustainable, repeating
/// aerobic structure.
///
///  - **Polarised ~80/20**: mostly easy aerobic running, one or two quality
///    sessions a week (by focus + experience + frequency).
///  - **One aerobic long run** (~28% of weekly volume, capped) — not race
///    distance.
///  - **Gentle progressive base**: volume anchored to the athlete's CURRENT
///    load, nudged up per 4-week block by the chosen `TrainingFocus`, with a
///    down week every 4th week (cut ~20%). Never ramps to race volume.
///  - **Discipline-aware**: road athletes get tempo / cruise intervals /
///    fartlek / strides; trail athletes get hill repeats / climbs / trail
///    fartlek.
///  - **Variety**: quality session types rotate week to week, salted per
///    athlete so two similar athletes don't get the same rotation.
enum GeneralFitnessPlanGenerator {

    static func generate(
        athlete: Athlete,
        targetRaceId: UUID,
        weeks: Int = 12,
        startDate: Date = .now
    ) -> (weeks: [TrainingWeek], workouts: [IntervalWorkout]) {
        let focus = athlete.trainingFocus
        let isTrail = athlete.runningTerrain == .trail
        let runs = max(3, min(athlete.preferredRunsPerWeek, 7))
        let cal = Calendar.current

        // Road paces from PRs/VMA (nil profile → effort labels).
        let paceProfile: RoadPaceProfile? = isTrail ? nil : RoadPaceCalculator.paceProfile(
            goalTime: nil, raceDistanceKm: 10,
            personalBests: athlete.personalBests, vmaKmh: athlete.vmaKmh,
            experience: athlete.experienceLevel
        )
        let dataDerived = paceProfile?.isDataDerived ?? false
        let easyPaceSec = paceProfile?.easyPacePerKm.lowerBound ?? 360 // ~6:00/km default

        // Floor very-low / new-runner volume to a sensible starter.
        let baseVolume = max(athlete.weeklyVolumeKm > 0 ? athlete.weeklyVolumeKm : 0,
                             starterVolume(athlete.experienceLevel))
        let seed = stableSeed(athlete.id)

        var result: [TrainingWeek] = []
        var allWorkouts: [IntervalWorkout] = []
        for i in 0..<weeks {
            let weekStart = cal.date(byAdding: .weekOfYear, value: i, to: cal.startOfDay(for: startDate)) ?? startDate
            let weekEnd = cal.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let isDown = (i % 4) == 3
            let block = i / 4
            let withinBlock: Double = [1.00, 1.05, 1.10, 0.80][i % 4]
            let trend = pow(focus.blockGrowth, Double(block))
            let volume = (baseVolume * withinBlock * trend).rounded()

            let (sessions, weekWorkouts) = buildWeek(
                weekIndex: i, weekStart: weekStart, isDown: isDown,
                volume: volume, runs: runs, focus: focus, isTrail: isTrail,
                experience: athlete.experienceLevel, paceProfile: paceProfile,
                dataDerived: dataDerived, easyPaceSec: easyPaceSec, seed: seed
            )
            allWorkouts.append(contentsOf: weekWorkouts)
            let totalDuration = sessions.filter { $0.type != .rest }.reduce(0) { $0 + $1.plannedDuration }
            result.append(TrainingWeek(
                id: UUID(), weekNumber: i + 1, startDate: weekStart, endDate: weekEnd,
                phase: .base, sessions: sessions, isRecoveryWeek: isDown,
                targetVolumeKm: round(volume), targetElevationGainM: isTrail ? round(volume * 18) : 0,
                targetDurationSeconds: totalDuration, phaseFocus: nil
            ))
        }
        return (result, allWorkouts)
    }

    // MARK: - Week assembly

    private static func buildWeek(
        weekIndex: Int, weekStart: Date, isDown: Bool,
        volume: Double, runs: Int, focus: TrainingFocus, isTrail: Bool,
        experience: ExperienceLevel, paceProfile: RoadPaceProfile?,
        dataDerived: Bool, easyPaceSec: Double, seed: Int
    ) -> (sessions: [TrainingSession], workouts: [IntervalWorkout]) {
        let cal = Calendar.current
        var workouts: [IntervalWorkout] = []

        // Quality count: focus default, capped by experience / frequency,
        // and trimmed on down weeks.
        var quality = focus.baseQualityCount
        if experience == .beginner { quality = min(quality, 1) }
        if runs <= 3 { quality = min(quality, 1) }
        if isDown { quality = min(quality, 1) }

        // Distances → durations. Long run ~28% of volume (capped); quality
        // sessions are a fixed share; easy runs split the remainder.
        let longKm = min(volume * 0.28, isTrail ? 28 : 26)
        let qualityKm = volume * 0.16
        let usedKm = longKm + qualityKm * Double(quality)
        let easyRuns = max(1, runs - 1 - quality)
        let easyKm = max(4, (volume - usedKm) / Double(easyRuns))

        let longDur = longKm * easyPaceSec
        let easyDur = easyKm * easyPaceSec
        let qualityDur = max(35 * 60, qualityKm * easyPaceSec)

        // Day layout: Tue(1)=Q1, Thu(3)=Q2 (or easy), Sat(5)=long, others easy.
        var byDay: [Int: TrainingSession] = [:]
        func day(_ offset: Int) -> Date { cal.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart }

        // Long run (Saturday).
        byDay[5] = session(.longRun, isTrail ? .moderate : .easy, longDur,
                           date: day(5), focus: nil,
                           desc: longRunDesc(isTrail: isTrail, isDown: isDown, minutes: Int(longDur / 60)))

        // Quality sessions.
        let qSlots = [1, 3]
        let pool = isTrail ? trailPool : roadPool
        for qi in 0..<quality {
            // Advance by 1 per week so the rotation visits EVERY pool entry;
            // the second quality slot is offset ~half the pool so Q1 and Q2
            // stay complementary, and the seed salts it per athlete.
            let idx = (weekIndex + qi * (pool.count / 2 + 1) + seed) % pool.count
            let pick = pool[idx]
            let qs = pick.make(paceProfile, dataDerived, isDown)
            var s = session(qs.type, qs.intensity, qualityDur,
                            date: day(qSlots[qi]), focus: qs.focusLabel, desc: qs.desc)
            // Attach a structured workout so the session shows phase cards.
            if let w = qualityWorkout(for: qs) {
                workouts.append(w)
                s.intervalWorkoutId = w.id
                s.plannedDuration = w.estimatedDurationSeconds
                s.plannedDistanceKm = round(w.estimatedDurationSeconds / 360 * 10) / 10
            }
            byDay[qSlots[qi]] = s
        }

        // Easy runs fill remaining run days (Mon0, Wed2, Thu3, Fri4, Sun6).
        let allRunDays = [0, 2, 3, 4, 6]
        var placedEasy = 0
        let easyTarget = runs - byDay.count
        var stridesPlaced = false
        for d in allRunDays where byDay[d] == nil && placedEasy < easyTarget {
            // One easy day carries strides for economy (not on down weeks).
            let withStrides = !stridesPlaced && !isDown && d == 4
            byDay[d] = session(.recovery, .easy, easyDur, date: day(d), focus: nil,
                               desc: easyDesc(paceProfile: paceProfile, dataDerived: dataDerived, withStrides: withStrides))
            if withStrides { stridesPlaced = true }
            placedEasy += 1
        }

        // Fill the rest with rest days.
        var sessions: [TrainingSession] = []
        for d in 0...6 {
            if let s = byDay[d] {
                sessions.append(s)
            } else {
                sessions.append(session(.rest, .easy, 0, date: day(d), focus: nil,
                                        desc: String(localized: "gf.rest", defaultValue: "Rest day. Easy walk or full rest.")))
            }
        }
        return (sessions, workouts)
    }

    // MARK: - Quality pools

    private struct QualitySpec {
        let type: SessionType
        let intensity: Intensity
        let focusLabel: String
        let desc: String
        // Structured shape for the phase cards. reps == 0 => description-only
        // (a continuous run like a progression or by-feel fartlek).
        var warmUpMin: Int = 0
        var reps: Int = 0
        var workSec: Int = 0
        var recoverySec: Int = 0
        var coolDownMin: Int = 0
    }
    private struct QualityTemplate {
        let make: (_ p: RoadPaceProfile?, _ dataDerived: Bool, _ isDown: Bool) -> QualitySpec
    }

    private static func pace(_ p: RoadPaceProfile?, _ dataDerived: Bool, _ secPerKm: Double?) -> String {
        guard dataDerived, let secPerKm else { return "" }
        return " (~\(RoadCoachAdviceGenerator.formatPace(secPerKm))/km)"
    }

    private static var roadPool: [QualityTemplate] {
        [
            QualityTemplate { p, dd, down in
                let mins = down ? 12 : 20
                return QualitySpec(type: .tempo, intensity: .hard,
                    focusLabel: String(localized: "interval.category.threshold", defaultValue: "Threshold"),
                    desc: String(localized: "gf.road.tempo", defaultValue: "Tempo: 15 min easy, then \(mins) min at threshold\(pace(p, dd, p?.thresholdPacePerKm)), 10 min easy."),
                    warmUpMin: 15, reps: 1, workSec: mins * 60, recoverySec: 0, coolDownMin: 10)
            },
            QualityTemplate { p, dd, down in
                let reps = down ? 3 : 5
                return QualitySpec(type: .intervals, intensity: .hard,
                    focusLabel: String(localized: "interval.category.threshold", defaultValue: "Threshold"),
                    desc: String(localized: "gf.road.cruise", defaultValue: "\(reps) × 5 min at threshold\(pace(p, dd, p?.thresholdPacePerKm)), 90s jog. Cruise intervals."),
                    warmUpMin: 12, reps: reps, workSec: 5 * 60, recoverySec: 90, coolDownMin: 10)
            },
            QualityTemplate { _, _, down in
                let reps = down ? 6 : 8
                return QualitySpec(type: .intervals, intensity: .moderate,
                    focusLabel: String(localized: "interval.category.fartlek", defaultValue: "Fartlek"),
                    desc: String(localized: "gf.road.fartlek", defaultValue: "Fartlek: warm up, then \(reps) × (1 min strong / 2 min easy), cool down. Run by feel."),
                    warmUpMin: 12, reps: reps, workSec: 60, recoverySec: 120, coolDownMin: 10)
            },
            QualityTemplate { _, _, _ in
                QualitySpec(type: .tempo, intensity: .moderate,
                    focusLabel: String(localized: "interval.category.progression", defaultValue: "Progression"),
                    desc: String(localized: "gf.road.progression", defaultValue: "Progression run: start easy and build to a comfortably-hard effort over the final third."))
            },
            QualityTemplate { _, _, _ in
                QualitySpec(type: .intervals, intensity: .hard,
                    focusLabel: String(localized: "interval.category.speed", defaultValue: "Speed"),
                    desc: String(localized: "gf.road.hillStrides", defaultValue: "Easy run + 8 × 20s hill strides with full recovery. Power and economy."),
                    warmUpMin: 20, reps: 8, workSec: 20, recoverySec: 60, coolDownMin: 5)
            },
            QualityTemplate { p, dd, down in
                let reps = down ? 4 : 6
                return QualitySpec(type: .intervals, intensity: .maxEffort,
                    focusLabel: String(localized: "interval.category.vo2max", defaultValue: "VO2max"),
                    desc: String(localized: "gf.road.vo2", defaultValue: "\(reps) × 2 min hard\(pace(p, dd, p?.intervalPacePerKm)), 2 min jog. Keeps the top end sharp."),
                    warmUpMin: 12, reps: reps, workSec: 2 * 60, recoverySec: 2 * 60, coolDownMin: 10)
            }
        ]
    }

    private static var trailPool: [QualityTemplate] {
        [
            QualityTemplate { _, _, down in
                let reps = down ? 4 : 6
                return QualitySpec(type: .verticalGain, intensity: .hard,
                    focusLabel: String(localized: "gf.focus.hills", defaultValue: "Hills"),
                    desc: String(localized: "gf.trail.hillRepeats", defaultValue: "\(reps) × 2 min uphill at steady-hard effort, jog or walk down to recover."),
                    warmUpMin: 12, reps: reps, workSec: 2 * 60, recoverySec: 2 * 60, coolDownMin: 10)
            },
            QualityTemplate { _, _, down in
                let mins = down ? 15 : 22
                return QualitySpec(type: .verticalGain, intensity: .moderate,
                    focusLabel: String(localized: "gf.focus.climbing", defaultValue: "Climbing"),
                    desc: String(localized: "gf.trail.climb", defaultValue: "Sustained climb: \(mins) min uphill at a controlled-hard effort you could just hold a few words at."),
                    warmUpMin: 12, reps: 1, workSec: mins * 60, recoverySec: 0, coolDownMin: 10)
            },
            QualityTemplate { _, _, _ in
                QualitySpec(type: .intervals, intensity: .moderate,
                    focusLabel: String(localized: "interval.category.fartlek", defaultValue: "Fartlek"),
                    desc: String(localized: "gf.trail.fartlek", defaultValue: "Rolling trail fartlek: surge every climb, float the descents, easy on the flats."))
            },
            QualityTemplate { _, _, _ in
                QualitySpec(type: .intervals, intensity: .hard,
                    focusLabel: String(localized: "interval.category.speed", defaultValue: "Speed"),
                    desc: String(localized: "gf.trail.strides", defaultValue: "Easy trail run + 6 × 20s strides on a smooth, flat section. Leg speed."),
                    warmUpMin: 20, reps: 6, workSec: 20, recoverySec: 60, coolDownMin: 5)
            }
        ]
    }

    // MARK: - Descriptions

    private static func longRunDesc(isTrail: Bool, isDown: Bool, minutes: Int) -> String {
        if isDown {
            return String(localized: "gf.long.down", defaultValue: "Easy long run, kept short this week. Conversational throughout.")
        }
        return isTrail
            ? String(localized: "gf.long.trail", defaultValue: "Long trail run, easy aerobic effort. Hike the steep climbs, stay conversational.")
            : String(localized: "gf.long.road", defaultValue: "Long run at an easy, conversational pace. Pure aerobic time on feet.")
    }

    private static func easyDesc(paceProfile: RoadPaceProfile?, dataDerived: Bool, withStrides: Bool) -> String {
        let paceStr: String
        if dataDerived, let p = paceProfile {
            paceStr = "\(RoadCoachAdviceGenerator.formatPace(p.easyPacePerKm.lowerBound))-\(RoadCoachAdviceGenerator.formatPace(p.easyPacePerKm.upperBound))/km"
        } else {
            paceStr = String(localized: "roadSel.conversationalPace", defaultValue: "conversational pace")
        }
        if withStrides {
            return String(localized: "gf.easy.strides", defaultValue: "Easy run @ \(paceStr) + 6 × 20s strides at the end.")
        }
        return String(localized: "gf.easy", defaultValue: "Easy aerobic run @ \(paceStr).")
    }

    // MARK: - Helpers

    /// Builds the structured warm-up → reps → cool-down workout for a quality
    /// spec so the session shows phase cards (not just a description). Returns
    /// nil for description-only specs (continuous runs like a progression or a
    /// by-feel fartlek).
    private static func qualityWorkout(for qs: QualitySpec) -> IntervalWorkout? {
        guard qs.reps > 0, qs.workSec > 0 else { return nil }
        let warm = String(localized: "gf.phase.warmup", defaultValue: "Easy warm-up")
        let recover = String(localized: "gf.phase.recovery", defaultValue: "Easy recovery jog")
        let cool = String(localized: "gf.phase.cooldown", defaultValue: "Easy cool-down")

        var phases: [IntervalPhase] = []
        if qs.warmUpMin > 0 {
            phases.append(IntervalPhase(id: UUID(), phaseType: .warmUp,
                trigger: .duration(seconds: Double(qs.warmUpMin * 60)),
                targetIntensity: .easy, repeatCount: 1, notes: warm))
        }
        phases.append(IntervalPhase(id: UUID(), phaseType: .work,
            trigger: .duration(seconds: Double(qs.workSec)),
            targetIntensity: qs.intensity, repeatCount: qs.reps, notes: qs.focusLabel))
        if qs.recoverySec > 0 {
            phases.append(IntervalPhase(id: UUID(), phaseType: .recovery,
                trigger: .duration(seconds: Double(qs.recoverySec)),
                targetIntensity: .easy, repeatCount: qs.reps, notes: recover))
        }
        if qs.coolDownMin > 0 {
            phases.append(IntervalPhase(id: UUID(), phaseType: .coolDown,
                trigger: .duration(seconds: Double(qs.coolDownMin * 60)),
                targetIntensity: .easy, repeatCount: 1, notes: cool))
        }
        let total = phases.reduce(0.0) { $0 + $1.totalDuration }
        return IntervalWorkout(
            id: UUID(), name: qs.focusLabel, descriptionText: qs.desc,
            phases: phases, category: .roadSpecific,
            estimatedDurationSeconds: total,
            estimatedDistanceKm: round(total / 360 * 10) / 10,
            isUserCreated: false)
    }

    private static func session(_ type: SessionType, _ intensity: Intensity, _ duration: TimeInterval,
                                date: Date, focus: String?, desc: String) -> TrainingSession {
        let avgPace: Double = 360
        let distance = duration > 0 ? round(duration / avgPace * 10) / 10 : 0
        var s = TrainingSession(
            id: UUID(), date: date, type: type,
            plannedDistanceKm: distance, plannedElevationGainM: 0,
            plannedDuration: duration, intensity: intensity, description: desc,
            isCompleted: false, isSkipped: false
        )
        s.intervalFocus = focus
        s.isKeySession = type == .longRun || type == .intervals || type == .tempo || type == .verticalGain
        return s
    }

    private static func starterVolume(_ exp: ExperienceLevel) -> Double {
        switch exp {
        case .beginner:     20
        case .intermediate: 30
        case .advanced:     40
        case .elite:        50
        }
    }

    /// Deterministic, launch-stable hash of a UUID (FNV-1a over its bytes).
    private static func stableSeed(_ id: UUID) -> Int {
        var h: UInt64 = 1469598103934665603
        let b = id.uuid
        for byte in [b.0, b.1, b.2, b.3, b.4, b.5, b.6, b.7, b.8, b.9, b.10, b.11, b.12, b.13, b.14, b.15] {
            h = (h ^ UInt64(byte)) &* 1099511628211
        }
        return Int(h & 0x7FFF_FFFF)
    }
}
