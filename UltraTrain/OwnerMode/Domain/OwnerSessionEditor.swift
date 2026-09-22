#if OWNER_MODE
import Foundation

/// Free-form owner override for one session's planned values. Every
/// field is optional; nil means "leave as generated."
struct OwnerSessionEdit: Equatable, Sendable {
    var plannedDistanceKm: Double?
    var plannedElevationGainM: Double?
    var plannedDuration: TimeInterval?
    /// Overall target pace for the session (sec/km). When exactly one
    /// of plannedDistanceKm/plannedDuration is also set, the other is
    /// derived from this pace.
    var targetPaceSecondsPerKm: Double?
    /// Per-block pace overrides for a structured interval/fractionné
    /// workout. Ignored when the session has no linked IntervalWorkout.
    var phasePaces: [OwnerPhasePaceEdit] = []
}

struct OwnerPhasePaceEdit: Equatable, Sendable {
    let phaseId: UUID
    let paceSecondsPerKm: Double
}

/// Applies a free-form owner edit to a generated session (and its
/// linked interval workout, if any), then regenerates that session's
/// coach advice so it stays consistent with the edit instead of
/// referencing the original auto-generated values. Pure domain logic,
/// no persistence: the caller applies the returned session/workout to
/// the in-memory plan and saves it.
enum OwnerSessionEditor {

    struct Result {
        var session: TrainingSession
        var updatedWorkout: IntervalWorkout?
    }

    static func apply(
        _ edit: OwnerSessionEdit,
        to session: TrainingSession,
        week: TrainingWeek,
        workout: IntervalWorkout?,
        athlete: Athlete,
        targetRace: Race?
    ) -> Result {
        var session = session

        if let distance = edit.plannedDistanceKm {
            session.plannedDistanceKm = max(0, distance)
        }
        if let elevation = edit.plannedElevationGainM {
            session.plannedElevationGainM = max(0, elevation)
        }
        if let duration = edit.plannedDuration {
            session.plannedDuration = max(0, duration)
        }

        // Session-level pace edit derives whichever of distance/duration
        // the owner didn't set explicitly in this same edit.
        if let pace = edit.targetPaceSecondsPerKm, pace > 0 {
            let distanceSetExplicitly = edit.plannedDistanceKm != nil
            let durationSetExplicitly = edit.plannedDuration != nil
            if durationSetExplicitly, !distanceSetExplicitly {
                session.plannedDistanceKm = session.plannedDuration / pace
            } else if distanceSetExplicitly, !durationSetExplicitly {
                session.plannedDuration = session.plannedDistanceKm * pace
            } else if !distanceSetExplicitly, !durationSetExplicitly, session.plannedDuration > 0 {
                session.plannedDistanceKm = session.plannedDuration / pace
            }
        }

        var updatedWorkout = workout
        if !edit.phasePaces.isEmpty, let workout {
            let rebuilt = OwnerIntervalWorkoutEditor.apply(edit.phasePaces, to: workout)
            updatedWorkout = rebuilt
            // A structured workout's own duration estimate is the more
            // precise source once phase paces change; carry it down to
            // the session unless the owner also typed an explicit
            // session-level duration this same edit.
            if edit.plannedDuration == nil, rebuilt.estimatedDurationSeconds > 0 {
                session.plannedDuration = rebuilt.estimatedDurationSeconds
            }
        }

        session.coachAdvice = OwnerAdviceRegenerator.advice(
            for: session,
            week: week,
            athlete: athlete,
            targetRace: targetRace
        )

        return Result(session: session, updatedWorkout: updatedWorkout)
    }
}
#endif
