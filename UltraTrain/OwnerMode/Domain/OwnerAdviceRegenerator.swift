#if OWNER_MODE
import Foundation

/// Regenerates a single session's coach advice after an owner edit, so
/// the advice text stays consistent with the edited values instead of
/// referencing the original auto-generated ones. Dispatches to the
/// same generators the plan-generation engine itself uses
/// (`CoachAdviceGenerator` for trail, `RoadCoachAdviceGenerator` for
/// road) — this is regeneration with the edited session's own fields,
/// not new advice logic.
///
/// Scope note: `weekInPhase` isn't recomputed here (defaults to 0), so
/// phrasing that references progression within a phase may be slightly
/// generic compared to the original generation pass. Everything else
/// (type, intensity, phase, recovery week, duration, HR context) is
/// exact.
enum OwnerAdviceRegenerator {

    static func advice(
        for session: TrainingSession,
        week: TrainingWeek,
        athlete: Athlete,
        targetRace: Race?
    ) -> String? {
        if targetRace?.raceType == .road {
            let discipline = RoadRaceDiscipline.from(distanceKm: targetRace?.distanceKm ?? 0)
            return RoadCoachAdviceGenerator.advice(
                type: session.type,
                intensity: session.intensity,
                phase: week.phase,
                discipline: discipline,
                isRecoveryWeek: week.isRecoveryWeek,
                paceProfile: nil,
                raceName: targetRace?.name,
                experience: athlete.experienceLevel,
                restingHR: athlete.restingHeartRate,
                maxHR: athlete.maxHeartRate,
                biologicalSex: athlete.biologicalSex
            )
        }

        return CoachAdviceGenerator.advice(
            for: session.type,
            intensity: session.intensity,
            phase: week.phase,
            isRecoveryWeek: week.isRecoveryWeek,
            plannedDurationSeconds: session.plannedDuration,
            restingHR: athlete.restingHeartRate,
            maxHR: athlete.maxHeartRate,
            biologicalSex: athlete.biologicalSex,
            athleteAge: athlete.age
        )
    }
}
#endif
