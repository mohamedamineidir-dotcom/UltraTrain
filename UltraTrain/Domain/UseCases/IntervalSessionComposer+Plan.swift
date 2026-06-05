import Foundation

/// Work-structure planning for `IntervalSessionComposer`: turns the athlete's
/// profile + progression coordinate + chosen shape into concrete rep segments.
extension IntervalSessionComposer {

    // MARK: - Plan dispatch

    static func plan(_ ctx: Context, shape: Shape) -> [Segment] {
        switch shape {
        case .uniform:       return uniformSegments(ctx)
        case .pyramid:       return pyramidSegments(ctx)
        case .cutdown:       return cutdownSegments(ctx)
        case .mixedContrast: return mixedContrastSegments(ctx)
        case .progression:   return progressionSegments(ctx)
        }
    }

    // MARK: - Budget (total work minutes)

    /// Total time at the target pace, scaled by weekly volume + experience and
    /// progressively overloaded by the session ordinal (Daniels: VO2max ≈
    /// 6-8% of weekly km, threshold ≈ 8-10%).
    static func workBudgetMinutes(_ ctx: Context) -> Double {
        let vol = min(max(ctx.weeklyVolumeKm, 20), 140)
        let expFactor: Double = switch ctx.experience {
        case .beginner:     0.78
        case .intermediate: 0.90
        case .advanced:     1.00
        case .elite:        1.10
        }
        let volFactor = 0.75 + vol / 200.0            // 20→0.85, 79→1.15, 140→1.45
        let growth = 1.0 + min(Double(ctx.ordinal), 6) * 0.045  // up to +27%
        let base: Double = switch ctx.category {
        case .vo2max:         9
        case .threshold:      14
        case .raceSpecific:   ctx.phase == .peak ? 32 : 20
        case .speed:          8
        case .progression:    28
        case .longRunVariant: 18
        }
        let firstTimer = ctx.isFirstTimer ? 0.85 : 1.0
        return base * expFactor * volFactor * growth * firstTimer
    }

    // MARK: - Rep sizing

    /// Primary rep size for this session, walked up a discipline-specific menu
    /// by the ordinal so each successive session uses a different rep length.
    /// Returns (distanceM, durationSec); exactly one is non-zero.
    static func primaryRep(_ ctx: Context) -> (distanceM: Int, durationSec: Int) {
        switch ctx.category {
        case .speed:
            let menu = [200, 300, 400, 400]
            return (menu[min(ctx.ordinal, menu.count - 1)], 0)
        case .vo2max:
            // VO2max rep distance cycles so successive sessions vary the rep
            // length (400m sharpeners ⇄ 1200m sustained), with overload via
            // total volume + recovery ratio.
            let menu: [Int] = ctx.discipline == .roadMarathon
                ? [800, 1000, 1200, 1600]
                : [400, 600, 800, 1000, 1200]
            return (cycleMenu(menu, ctx), 0)
        case .threshold:
            // Time-based cruise reps (Campus Coach 1'→2'→3'→5' family). Cycled
            // (not capped) so successive threshold sessions keep changing rep
            // length; overload comes from total volume + recovery ratio. Menu
            // size 5 is coprime to the 4-shape rotation, so each shape samples
            // every rep length before repeating.
            let menu = [60, 90, 120, 180, 300]
            return (0, cycleMenu(menu, ctx))
        case .raceSpecific:
            // Race-pace blocks walk forward (progression matters here).
            let menu: [Int] = ctx.discipline == .roadMarathon
                ? [1000, 1500, 2000, 3000]
                : (ctx.discipline == .roadHalf ? [1600, 2000, 3000] : [1000, 1600, 2000])
            return (cappedMenu(menu, ctx), 0)
        case .progression, .longRunVariant:
            return (0, 0)  // continuous
        }
    }

    /// Walks a menu by ordinal, capping at the top (one notch short for
    /// first-timers so they don't jump straight to the longest rep). Used
    /// where forward progression matters (race-pace blocks, speed).
    private static func cappedMenu(_ menu: [Int], _ ctx: Context) -> Int {
        let last = menu.count - 1
        let cap = ctx.isFirstTimer ? max(0, last - 1) : last
        return menu[min(ctx.ordinal, cap)]
    }

    /// Cycles a menu so the rep length keeps changing each session and visits
    /// every entry. The shape rotation has a different period (3-4), so the
    /// (shape × length) pair only repeats after lcm(shapes, menu) sessions —
    /// far more than a plan ever contains. First-timers stay off the longest
    /// entry.
    private static func cycleMenu(_ menu: [Int], _ ctx: Context) -> Int {
        let usable = ctx.isFirstTimer ? Array(menu.dropLast()) : menu
        return usable[ctx.ordinal % usable.count]
    }

    /// Recovery duration (sec) for a rep, with the work:rest ratio tightening
    /// as the block matures — Campus Coach's deliberate difficulty dial
    /// (1:1 early → toward 2:1 work-dominant later).
    static func recovery(_ ctx: Context, repSeconds: Double) -> (sec: Int, type: RoadIntervalLibrary.RecoveryType) {
        switch ctx.category {
        case .speed:
            return (Int((repSeconds * 1.5).rounded()), .jog)
        case .vo2max:
            let ratio = max(0.5, 1.0 - Double(ctx.ordinal) * 0.08)  // 1:1 → 1:2
            return (Int((repSeconds * ratio).rounded()), .jog)
        case .threshold:
            let ratio = max(0.33, 0.9 - Double(ctx.ordinal) * 0.1)  // ~1:1 → 1:3
            return (max(30, Int((repSeconds * ratio).rounded())), .jog)
        case .raceSpecific:
            return (max(45, 90 - ctx.ordinal * 5), .jog)            // 90s → 45s float-ish jog
        case .progression, .longRunVariant:
            return (0, .standing)
        }
    }

    // MARK: - Shape builders

    static func uniformSegments(_ ctx: Context) -> [Segment] {
        let rep = primaryRep(ctx)
        let repSec = repSeconds(ctx, distanceM: rep.distanceM, durationSec: rep.durationSec)
        let rec = recovery(ctx, repSeconds: repSec)
        let count = repCount(ctx, repSeconds: repSec)
        return [Segment(repCount: count, repDistanceM: rep.distanceM,
                        repDurationSec: rep.durationSec, zone: targetZone(ctx),
                        recoverySec: rec.sec, recoveryType: rec.type)]
    }

    /// Ascending-then-descending rep sizes around a peak (Campus Coach
    /// "Pyramid of Pain"). Built in TIME so it reads 1'-2'-3'-2'-1'. The apex
    /// varies between recurrences so two pyramids are never identical.
    static func pyramidSegments(_ ctx: Context) -> [Segment] {
        let zone = targetZone(ctx)
        let rec = recovery(ctx, repSeconds: 90)
        let peak = [120, 180, 150, 240][(ctx.ordinal / 3) % 4]  // apex rotates
        var ladder: [Int] = []
        var s = 60
        while s < peak { ladder.append(s); s += 60 }
        ladder.append(peak)
        let full = ladder + ladder.dropLast().reversed()  // up then down
        return full.map {
            Segment(repCount: 1, repDistanceM: 0, repDurationSec: $0, zone: zone,
                    recoverySec: rec.sec, recoveryType: rec.type)
        }
    }

    /// Descending rep length at the same pace — teaches holding form as reps
    /// shorten (a cutdown ladder), e.g. 1200/1000/800/600m.
    static func cutdownSegments(_ ctx: Context) -> [Segment] {
        let zone = targetZone(ctx)
        let rep = primaryRep(ctx)
        let rec = recovery(ctx, repSeconds: repSeconds(ctx, distanceM: rep.distanceM, durationSec: rep.durationSec))
        if rep.distanceM > 0 {
            let sizes = [rep.distanceM, Int(Double(rep.distanceM) * 0.8), Int(Double(rep.distanceM) * 0.6)]
                .map { ($0 / 100) * 100 }
            return sizes.map {
                Segment(repCount: 2, repDistanceM: $0, repDurationSec: 0, zone: zone,
                        recoverySec: rec.sec, recoveryType: rec.type)
            }
        }
        let sizes = [rep.durationSec, Int(Double(rep.durationSec) * 0.66)].map { max(30, $0) }
        return sizes.map {
            Segment(repCount: 2, repDistanceM: 0, repDurationSec: $0, zone: zone,
                    recoverySec: rec.sec, recoveryType: rec.type)
        }
    }

    /// Two contrasting zones in one session (Campus Coach "Catapult":
    /// threshold reps + VO2max reps). Both portions vary between recurrences.
    static func mixedContrastSegments(_ ctx: Context) -> [Segment] {
        let rec = recovery(ctx, repSeconds: 120)
        let k = ctx.ordinal / 4   // mixed-contrast recurs ~every 4 ordinals
        let thrDur = [120, 150, 180, 90][k % 4]
        let thrReps = 4 + (k % 3)
        let vo2Reps = 3 + (k % 2)
        return [
            Segment(repCount: thrReps, repDistanceM: 0, repDurationSec: thrDur,
                    zone: .threshold, recoverySec: rec.sec, recoveryType: .jog),
            Segment(repCount: vo2Reps, repDistanceM: 0, repDurationSec: 60,
                    zone: .interval, recoverySec: 60, recoveryType: .jog)
        ]
    }

    /// Continuous sustained block, alternating between one unbroken block and
    /// two blocks (broken tempo) between recurrences so successive continuous
    /// sessions differ in structure as well as length (the `progression`
    /// category itself stays a single continuous build).
    static func progressionSegments(_ ctx: Context) -> [Segment] {
        let minutes = workBudgetMinutes(ctx)
        let zone: RoadIntervalLibrary.PaceZone = switch ctx.category {
        case .raceSpecific: .marathonPace
        case .threshold:    .threshold
        default:            .racePace
        }
        let broken = ctx.category != .progression && (ctx.ordinal / 2) % 2 == 1
        if broken {
            let per = Int((minutes * 60 / 2).rounded())
            return [Segment(repCount: 2, repDistanceM: 0, repDurationSec: per,
                            zone: zone, recoverySec: 120, recoveryType: .jog)]
        }
        return [Segment(repCount: 1, repDistanceM: 0,
                        repDurationSec: Int((minutes * 60).rounded()),
                        zone: zone, recoverySec: 0, recoveryType: .standing)]
    }

    // MARK: - Helpers

    static func targetZone(_ ctx: Context) -> RoadIntervalLibrary.PaceZone {
        switch ctx.category {
        case .speed:          return .repetition
        case .vo2max:         return .interval
        case .threshold:      return .threshold
        case .raceSpecific:   return ctx.discipline == .roadMarathon ? .marathonPace : .racePace
        case .progression:    return .racePace
        case .longRunVariant: return .threshold
        }
    }

    /// Seconds of work for one rep at the target pace.
    static func repSeconds(_ ctx: Context, distanceM: Int, durationSec: Int) -> Double {
        if durationSec > 0 { return Double(durationSec) }
        let pace = zonePaceSeconds(ctx, repLengthSec: 240)  // distance rep: use steady end
        return Double(distanceM) / 1000.0 * pace
    }

    /// repCount so total work ≈ the budget, clamped to a sane band.
    static func repCount(_ ctx: Context, repSeconds: Double) -> Int {
        guard repSeconds > 0 else { return 1 }
        let target = workBudgetMinutes(ctx) * 60.0
        let raw = Int((target / repSeconds).rounded())
        return min(20, max(3, raw))
    }

    /// Pace (sec/km) for the session's target zone. Threshold reps shorter
    /// than ~10 min take the faster (cruise) end of the threshold range.
    static func zonePaceSeconds(_ ctx: Context, repLengthSec: Double) -> Double {
        guard let p = ctx.paceProfile else { return 300 }
        switch targetZone(ctx) {
        case .easy:         return p.easyPacePerKm.lowerBound
        case .marathonPace: return p.marathonPacePerKm
        case .threshold:    return repLengthSec <= 600 ? p.thresholdPaceRangePerKm.lowerBound
                                                       : p.thresholdPaceRangePerKm.upperBound
        case .interval:     return p.intervalPacePerKm
        case .repetition:   return p.repetitionPacePerKm
        case .racePace:     return p.racePacePerKm
        }
    }
}
