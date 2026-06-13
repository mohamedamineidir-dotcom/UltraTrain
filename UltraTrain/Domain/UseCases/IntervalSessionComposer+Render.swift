import Foundation

/// Rendering for `IntervalSessionComposer`: turns the planned rep segments
/// into a structured `IntervalWorkout` (warm-up → work/recovery → cool-down),
/// a compact name, and a no-repeat signature.
extension IntervalSessionComposer {

    static func render(_ ctx: Context, segments: [Segment], shape: Shape) -> Composed {
        var phases: [IntervalPhase] = []

        // Age-based warm-up (older athletes warm up longer; injury prevention).
        let warmUp: Double = switch ctx.athleteAge {
        case ..<25: 12
        case ..<35: 14
        case ..<45: 16
        case ..<55: 18
        default:    20
        }
        phases.append(IntervalPhase(
            id: UUID(), phaseType: .warmUp,
            trigger: .duration(seconds: warmUp * 60), targetIntensity: .easy,
            repeatCount: 1, notes: warmUpNotes(ctx)
        ))

        for (i, seg) in segments.enumerated() {
            let isLast = i == segments.count - 1
            let pace = pace(for: seg, ctx: ctx)
            let intensity = intensity(for: seg.zone)
            let note = String(localized: "interval.note.target",
                              defaultValue: "Target: \(RoadCoachAdviceGenerator.formatPace(pace))/km")

            if seg.repDistanceM > 0 {
                phases.append(IntervalPhase(
                    id: UUID(), phaseType: .work,
                    trigger: .distance(km: Double(seg.repDistanceM) / 1000.0),
                    targetIntensity: intensity, repeatCount: seg.repCount, notes: note
                ))
            } else {
                phases.append(IntervalPhase(
                    id: UUID(), phaseType: .work,
                    trigger: .duration(seconds: Double(seg.repDurationSec)),
                    targetIntensity: intensity, repeatCount: seg.repCount, notes: note
                ))
            }

            if seg.recoverySec > 0 {
                let recCount = isLast ? max(seg.repCount - 1, 0) : seg.repCount
                if recCount > 0 {
                    phases.append(IntervalPhase(
                        id: UUID(), phaseType: .recovery,
                        trigger: .duration(seconds: Double(seg.recoverySec)),
                        targetIntensity: .easy, repeatCount: recCount,
                        notes: recoveryNote(seg.recoveryType)
                    ))
                }
            }
        }

        let coolDown: Double = ctx.category == .speed ? 8 : 10
        phases.append(IntervalPhase(
            id: UUID(), phaseType: .coolDown,
            trigger: .duration(seconds: coolDown * 60), targetIntensity: .easy,
            repeatCount: 1,
            notes: String(localized: "interval.note.cooldown", defaultValue: "Easy jog cool-down.")
        ))

        // Duration phases carry their own time; distance phases (which report
        // totalDuration 0) are converted via the target pace.
        let cleanDuration = cleanTotalDuration(
            phases: phases,
            distanceWorkSeconds: distanceWorkSeconds(phases: phases, ctx: ctx, segments: segments)
        )
        let estKm = cleanDuration / (ctx.paceProfile?.thresholdPacePerKm ?? 300)
        let name = name(ctx, segments: segments, shape: shape)

        let workout = IntervalWorkout(
            id: UUID(),
            name: name,
            descriptionText: description(ctx, shape: shape),
            phases: phases,
            category: workoutCategory(ctx.category),
            estimatedDurationSeconds: cleanDuration,
            estimatedDistanceKm: round(estKm * 10) / 10,
            isUserCreated: false
        )
        return Composed(
            workout: workout,
            signature: signature(ctx, segments: segments, shape: shape),
            focus: ctx.category.displayName,
            template: synthesizedTemplate(ctx, segments: segments, name: name),
            // A progression shape is the only sustained, continuous work the
            // composer builds (one unbroken block or two long broken blocks).
            // Every other shape is repeated efforts, i.e. intervals.
            isTempo: shape == .progression && !ctx.isRecoveryWeek
        )
    }

    /// A library `Template` mirroring the composed primary segment, so the
    /// existing coach-advice + label pipeline reads the right category, zone
    /// and rep structure without any change.
    private static func synthesizedTemplate(
        _ ctx: Context, segments: [Segment], name: String
    ) -> RoadIntervalLibrary.Template {
        let primary = segments.max(by: { $0.repCount < $1.repCount })
            ?? Segment(repCount: 1, repDistanceM: 0, repDurationSec: 0,
                       zone: targetZone(ctx), recoverySec: 0, recoveryType: .jog)
        var workSeconds: TimeInterval = 0
        for seg in segments {
            let pace = pace(for: seg, ctx: ctx)
            if seg.repDistanceM > 0 {
                workSeconds += Double(seg.repDistanceM) / 1000.0 * pace * Double(seg.repCount)
            } else {
                workSeconds += Double(seg.repDurationSec) * Double(seg.repCount)
            }
        }
        return RoadIntervalLibrary.Template(
            name: name, category: ctx.category,
            description: description(ctx, shape: .uniform),
            targetPaceZone: targetZone(ctx),
            repDistanceM: primary.repDistanceM,
            repCount: primary.repCount,
            recoverySeconds: primary.recoverySec,
            recoveryType: primary.recoveryType,
            totalWorkMinutes: workSeconds / 60.0,
            applicablePhases: [ctx.phase],
            applicableDistances: [ctx.discipline],
            minExperience: .beginner
        )
    }

    // MARK: - Duration

    private static func distanceWorkSeconds(phases: [IntervalPhase], ctx: Context, segments: [Segment]) -> TimeInterval {
        var total: TimeInterval = 0
        for seg in segments where seg.repDistanceM > 0 {
            let pace = pace(for: seg, ctx: ctx)
            total += Double(seg.repDistanceM) / 1000.0 * pace * Double(seg.repCount)
        }
        return total
    }

    private static func cleanTotalDuration(phases: [IntervalPhase], distanceWorkSeconds: TimeInterval) -> TimeInterval {
        var total = distanceWorkSeconds
        for p in phases {
            if case .distance = p.trigger { continue }
            total += p.totalDuration
        }
        return total
    }

    // MARK: - Pace / intensity

    private static func pace(for seg: Segment, ctx: Context) -> Double {
        guard let p = ctx.paceProfile else { return 300 }
        switch seg.zone {
        case .easy:         return p.easyPacePerKm.lowerBound
        case .marathonPace: return p.marathonPacePerKm
        case .threshold:
            let repLen = seg.repDurationSec > 0 ? Double(seg.repDurationSec) : 600
            return repLen <= 600 ? p.thresholdPaceRangePerKm.lowerBound : p.thresholdPaceRangePerKm.upperBound
        case .interval:     return p.intervalPacePerKm
        case .repetition:   return p.repetitionPacePerKm
        case .racePace:     return p.racePacePerKm
        }
    }

    private static func intensity(for zone: RoadIntervalLibrary.PaceZone) -> Intensity {
        switch zone {
        case .easy:         return .easy
        case .marathonPace: return .moderate
        case .threshold:    return .moderate
        case .interval:     return .hard
        case .repetition:   return .maxEffort
        case .racePace:     return .hard
        }
    }

    private static func workoutCategory(_ c: RoadIntervalLibrary.Category) -> WorkoutCategory {
        switch c {
        case .speed:          return .speedWork
        case .raceSpecific:   return .racePrep
        default:              return .roadSpecific
        }
    }

    // MARK: - Naming

    private static func name(_ ctx: Context, segments: [Segment], shape: Shape) -> String {
        if ctx.isRecoveryWeek {
            return ctx.slotIndex == 0
                ? String(localized: "interval.name.strides", defaultValue: "6×20s strides")
                : String(localized: "interval.name.mixedPrimer", defaultValue: "Mixed primer")
        }
        switch shape {
        case .pyramid:
            let mins = segments.map { fmtRep(distanceM: $0.repDistanceM, durationSec: $0.repDurationSec) }
            let tag = segments.first.map { zoneTag($0.zone) } ?? ""
            return String(localized: "interval.shape.pyramid", defaultValue: "Pyramid")
                + " \(mins.joined(separator: "-")) \(tag)"
        case .mixedContrast:
            // Counts + zone tags only (T / I / MP) — no translatable words.
            return segments.map { "\($0.repCount)×\(fmtRep(distanceM: $0.repDistanceM, durationSec: $0.repDurationSec)) \(zoneTag($0.zone))" }
                .joined(separator: " + ")
        case .cutdown:
            let tag = segments.first.map { zoneTag($0.zone) } ?? ""
            return String(localized: "interval.shape.cutdown", defaultValue: "Cutdown")
                + " " + segments.map { "\($0.repCount)×\(fmtRep(distanceM: $0.repDistanceM, durationSec: $0.repDurationSec))" }.joined(separator: "/") + " \(tag)"
        case .progression:
            guard let s = segments.first else { return ctx.category.displayName }
            let mins = s.repDurationSec / 60
            let label = ctx.category == .raceSpecific
                ? String(localized: "interval.label.mpTempo", defaultValue: "MP tempo")
                : (ctx.category == .threshold
                    ? String(localized: "interval.label.tempo", defaultValue: "tempo")
                    : String(localized: "interval.label.progression", defaultValue: "progression"))
            return s.repCount > 1 ? "\(s.repCount)×\(mins)min \(label)" : "\(mins)min \(label)"
        case .uniform:
            guard let s = segments.first else { return ctx.category.displayName }
            let reps = "\(s.repCount)×\(fmtRep(distanceM: s.repDistanceM, durationSec: s.repDurationSec))"
            // Only append a pace when it's data-derived (PRs / VMA / goal
            // time). Fabricating "5:00/km" for an athlete with no baseline
            // reads as false precision (RR-17); the zone tag carries the
            // intent instead.
            guard ctx.paceProfile?.isDataDerived == true else {
                return "\(reps) \(zoneTag(s.zone))"
            }
            let paceStr = RoadCoachAdviceGenerator.formatPace(pace(for: s, ctx: ctx))
            return "\(reps) @ \(paceStr)/km"
        }
    }

    private static func fmtRep(distanceM: Int, durationSec: Int) -> String {
        if distanceM > 0 {
            return distanceM >= 1000 && distanceM % 1000 == 0 ? "\(distanceM / 1000)K" : "\(distanceM)m"
        }
        if durationSec < 60 { return "\(durationSec)s" }
        let m = durationSec / 60, s = durationSec % 60
        return s > 0 ? "\(m)m\(s)s" : "\(m)min"
    }

    private static func zoneTag(_ z: RoadIntervalLibrary.PaceZone) -> String {
        switch z {
        case .threshold: return "T"
        case .interval:  return "I"
        case .marathonPace: return "MP"
        case .racePace:  return "RP"
        case .repetition: return "R"
        case .easy:      return "E"
        }
    }

    // MARK: - Description / signature / notes

    private static func description(_ ctx: Context, shape: Shape) -> String {
        if ctx.isRecoveryWeek {
            return String(localized: "interval.desc.recovery",
                          defaultValue: "Recovery-week primer. Keep it light and short; fatigue should drop to zero.")
        }
        return RoadIntervalLibrary.purposeLine(for: ctx.category.displayName)
            ?? String(localized: "interval.desc.fallback",
                      defaultValue: "Quality session at \(ctx.category.displayName) effort.")
    }

    static func signature(_ ctx: Context, segments: [Segment], shape: Shape) -> String {
        let segs = segments.map { "\($0.repCount)x\($0.repDistanceM)/\($0.repDurationSec)@\($0.zone.rawValue)r\($0.recoverySec)" }
            .joined(separator: ",")
        return "\(ctx.category.rawValue)|\(shape.rawValue)|\(segs)"
    }

    private static func warmUpNotes(_ ctx: Context) -> String {
        var note = String(localized: "interval.warmup.intro", defaultValue: "Easy jog to warm up.")
        if let p = ctx.paceProfile {
            note += " " + String(localized: "interval.warmup.pace",
                defaultValue: "~\(RoadCoachAdviceGenerator.formatPace(p.easyPacePerKm.upperBound))/km or slower.")
        }
        note += " " + String(localized: "interval.warmup.strides",
            defaultValue: "Include 4-6 strides in the last 2 minutes.")
        return note
    }

    private static func recoveryNote(_ type: RoadIntervalLibrary.RecoveryType) -> String {
        switch type {
        case .jog:      return String(localized: "interval.recovery.jog", defaultValue: "Easy jog recovery")
        case .walk:     return String(localized: "interval.recovery.walk", defaultValue: "Walk recovery")
        case .float:    return String(localized: "interval.recovery.float", defaultValue: "Float recovery (moderate jog)")
        case .standing: return String(localized: "interval.recovery.standing", defaultValue: "Standing or very slow jog")
        }
    }
}
