import Foundation

/// Builds structured IntervalWorkout objects for road race quality sessions.
///
/// Every interval and tempo session gets a proper warm-up → work → recovery → cool-down
/// structure with pace-specific notes. This is what the UI uses to display workout cards
/// and guide the athlete through each phase.
///
/// Standard road workout structure (Daniels):
/// - Warm-up: 10-15min easy jog + 4-6 strides
/// - Work intervals with recovery jogs
/// - Cool-down: 5-10min easy jog
enum RoadWorkoutBuilder {

    /// Builds an IntervalWorkout from a library template and pace profile.
    static func build(
        from template: RoadIntervalLibrary.Template,
        paceProfile: RoadPaceProfile?,
        experience: ExperienceLevel
    ) -> IntervalWorkout {
        var phases: [IntervalPhase] = []

        // Warm-up: 10-15min easy (longer for harder sessions)
        let warmUpMinutes: Double = template.category == .speed || template.category == .vo2max ? 15 : 10
        phases.append(IntervalPhase(
            id: UUID(),
            phaseType: .warmUp,
            trigger: .duration(seconds: warmUpMinutes * 60),
            targetIntensity: .easy,
            repeatCount: 1,
            notes: warmUpNotes(paceProfile: paceProfile)
        ))

        // Work + recovery: use repeatCount on SINGLE phases (not a loop)
        // This produces 2-3 phases instead of 2N, giving clean UI display:
        // "6×2m41s @ Hard (90s jog)" instead of 12 separate entries
        let workIntensity = intensityForZone(template.targetPaceZone)
        let paceNotes = workNotes(template: template, paceProfile: paceProfile)

        if template.repDistanceM > 0 {
            // Distance-based → convert to duration using target pace
            let repDistKm = Double(template.repDistanceM) / 1000.0
            let targetPace = targetPaceSeconds(zone: template.targetPaceZone, profile: paceProfile)
            let repDurationSeconds = repDistKm * targetPace

            phases.append(IntervalPhase(
                id: UUID(), phaseType: .work,
                trigger: .duration(seconds: repDurationSeconds),
                targetIntensity: workIntensity,
                repeatCount: template.repCount,
                notes: paceNotes
            ))
            if template.recoverySeconds > 0 {
                phases.append(IntervalPhase(
                    id: UUID(), phaseType: .recovery,
                    trigger: .duration(seconds: Double(template.recoverySeconds)),
                    targetIntensity: .easy,
                    repeatCount: max(template.repCount - 1, 1),
                    notes: recoveryNotes(template: template)
                ))
            }
        } else if template.repCount > 1 {
            // Multiple duration blocks (e.g., double tempo)
            let blockDuration = template.totalWorkMinutes * 60 / Double(template.repCount)
            phases.append(IntervalPhase(
                id: UUID(), phaseType: .work,
                trigger: .duration(seconds: blockDuration),
                targetIntensity: workIntensity,
                repeatCount: template.repCount,
                notes: paceNotes
            ))
            if template.recoverySeconds > 0 {
                phases.append(IntervalPhase(
                    id: UUID(), phaseType: .recovery,
                    trigger: .duration(seconds: Double(template.recoverySeconds)),
                    targetIntensity: .easy,
                    repeatCount: max(template.repCount - 1, 1),
                    notes: recoveryNotes(template: template)
                ))
            }
        } else {
            // Single continuous block (tempo, progression)
            phases.append(IntervalPhase(
                id: UUID(), phaseType: .work,
                trigger: .duration(seconds: template.totalWorkMinutes * 60),
                targetIntensity: workIntensity,
                repeatCount: 1,
                notes: paceNotes
            ))
        }

        // Cool-down: 5-10min easy
        let coolDownMinutes: Double = template.category == .speed ? 10 : 8
        phases.append(IntervalPhase(
            id: UUID(),
            phaseType: .coolDown,
            trigger: .duration(seconds: coolDownMinutes * 60),
            targetIntensity: .easy,
            repeatCount: 1,
            notes: coolDownNotes(paceProfile: paceProfile)
        ))

        // No need to remove trailing recovery — repeatCount handles it

        let totalDuration = phases.reduce(0.0) { $0 + $1.totalDuration }
        let estimatedKm = totalDuration / (paceProfile?.thresholdPacePerKm ?? 300)

        // Build compact name: "10×200m @ 3:43/km" format
        let compactName: String
        if template.repDistanceM > 0 {
            let pace = targetPaceSeconds(zone: template.targetPaceZone, profile: paceProfile)
            let paceStr = RoadCoachAdviceGenerator.formatPace(pace)
            compactName = "\(template.repCount)×\(template.repDistanceM)m @ \(paceStr)/km"
        } else if template.repCount > 1 {
            let mins = Int(template.totalWorkMinutes) / template.repCount
            compactName = "\(template.repCount)×\(mins)min @ T-pace"
        } else {
            compactName = template.name
        }

        return IntervalWorkout(
            id: UUID(),
            name: compactName,
            descriptionText: template.description,
            phases: phases,
            category: categoryMapping(template.category),
            estimatedDurationSeconds: totalDuration,
            estimatedDistanceKm: round(estimatedKm * 10) / 10,
            isUserCreated: false
        )
    }

    // MARK: - Helpers

    private static func intensityForZone(_ zone: RoadIntervalLibrary.PaceZone) -> Intensity {
        switch zone {
        case .easy:          .easy
        case .marathonPace:  .moderate
        case .threshold:     .moderate
        case .interval:      .hard
        case .repetition:    .maxEffort
        case .racePace:      .hard
        }
    }

    private static func categoryMapping(_ cat: RoadIntervalLibrary.Category) -> WorkoutCategory {
        switch cat {
        case .speed:         .speedWork
        case .vo2max:        .roadSpecific
        case .threshold:     .roadSpecific
        case .raceSpecific:  .racePrep
        case .progression:   .roadSpecific
        case .longRunVariant: .roadSpecific
        }
    }

    private static func warmUpNotes(paceProfile: RoadPaceProfile?) -> String {
        var note = "Easy jog to warm up."
        if let p = paceProfile {
            let pace = RoadCoachAdviceGenerator.formatPace(p.easyPacePerKm.upperBound)
            note += " ~\(pace)/km or slower."
        }
        note += " Include 4-6 strides (20s accelerations) in the last 2 minutes."
        return note
    }

    private static func workNotes(
        template: RoadIntervalLibrary.Template,
        paceProfile: RoadPaceProfile?
    ) -> String {
        guard let p = paceProfile else { return template.description }
        let targetPace: Double
        switch template.targetPaceZone {
        case .easy:          targetPace = p.easyPacePerKm.lowerBound
        case .marathonPace:  targetPace = p.marathonPacePerKm
        case .threshold:     targetPace = p.thresholdPacePerKm
        case .interval:      targetPace = p.intervalPacePerKm
        case .repetition:    targetPace = p.repetitionPacePerKm
        case .racePace:      targetPace = p.racePacePerKm
        }
        return "Target: \(RoadCoachAdviceGenerator.formatPace(targetPace))/km"
    }

    private static func recoveryNotes(template: RoadIntervalLibrary.Template) -> String {
        switch template.recoveryType {
        case .jog:      "Easy jog recovery"
        case .walk:     "Walk recovery"
        case .float:    "Float recovery (moderate jog)"
        case .standing: "Standing or very slow jog"
        }
    }

    private static func coolDownNotes(paceProfile: RoadPaceProfile?) -> String {
        "Easy jog cool-down."
    }

    /// Returns target pace in sec/km for a given pace zone.
    private static func targetPaceSeconds(
        zone: RoadIntervalLibrary.PaceZone,
        profile: RoadPaceProfile?
    ) -> Double {
        guard let p = profile else { return 300 } // 5:00/km fallback
        switch zone {
        case .easy:          return p.easyPacePerKm.lowerBound
        case .marathonPace:  return p.marathonPacePerKm
        case .threshold:     return p.thresholdPacePerKm
        case .interval:      return p.intervalPacePerKm
        case .repetition:    return p.repetitionPacePerKm
        case .racePace:      return p.racePacePerKm
        }
    }
}
