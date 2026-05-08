import Foundation

/// Substitutes a session in the trail plan with a road-race-specific
/// quality workout when an injection is scheduled for that week.
///
/// Given an `Injection` from `BRaceSpecificityCalculator`, this builds
/// the appropriate workout via `RoadIntervalLibrary` + `RoadWorkoutBuilder`
/// or `RoadLongRunWorkoutBuilder` and rewrites the session's
/// description / coachAdvice / intervalWorkoutId / intensity.
///
/// Skips fitness-test sessions (those have their own intervalFocus
/// encoding) and intermediate-race override sessions (mini-taper /
/// race-week / post-race-recovery shouldn't be rewritten).
enum BRaceSpecificitySubstitutor {

    /// Applies a single injection to the week's session list. Returns
    /// the rebuilt IntervalWorkout (when applicable) so the caller can
    /// add it to `plan.workouts`.
    static func apply(
        injection: BRaceSpecificityCalculator.Injection,
        sessions: inout [TrainingSession],
        athlete: Athlete
    ) -> IntervalWorkout? {
        // Find a session matching the requested slot type. Fallback
        // to .verticalGain for intervals/tempo slots — trail plans
        // for big-D+ A-races often substitute VG for intervals based
        // on the quality-ratio resolver, so we'd miss them otherwise.
        // VG is a high-intensity slot, same purpose: swapping it for
        // road-specific work doesn't add load, just changes the
        // stimulus for the upcoming tune-up.
        let preferredTypes: [SessionType] = {
            switch injection.slot {
            case .intervals: return [.intervals, .verticalGain]
            case .tempo:     return [.tempo, .verticalGain]
            case .longRun:   return [.longRun]
            }
        }()

        var targetIdx: Int?
        for type in preferredTypes {
            if let idx = sessions.firstIndex(where: { sess in
                sess.type == type
                    && !sess.isCompleted && !sess.isSkipped
                    // Don't overwrite fitness-test slots — those carry a
                    // higher-priority calibration purpose.
                    && !FitnessTestVariant.isFitnessTestFocus(sess.intervalFocus)
            }) {
                targetIdx = idx
                break
            }
        }
        guard let idx = targetIdx else { return nil }

        // Build a B-race-specific pace profile from the goal time.
        // We pass the athlete's PRs / VMA so the calculator can
        // sanity-check goal realism — but the goalTime is the
        // authoritative anchor for THIS race.
        let paceProfile = RoadPaceCalculator.paceProfile(
            goalTime: injection.bRaceGoalTime,
            raceDistanceKm: injection.bRaceDistanceKm,
            personalBests: athlete.personalBests,
            vmaKmh: athlete.vmaKmh,
            experience: athlete.experienceLevel
        )

        // Build the workout per kind.
        let totalDuration = sessions[idx].plannedDuration
        let workout = buildWorkout(
            kind: injection.kind,
            discipline: injection.bRaceDiscipline,
            paceProfile: paceProfile,
            athlete: athlete,
            totalDuration: totalDuration
        )
        guard let workout else { return nil }

        // Rewrite the session.
        sessions[idx].intervalWorkoutId = workout.id
        sessions[idx].description = workout.descriptionText
        sessions[idx].plannedDuration = workout.estimatedDurationSeconds > 0
            ? workout.estimatedDurationSeconds
            : sessions[idx].plannedDuration
        sessions[idx].plannedElevationGainM = 0  // road-specific = flat
        sessions[idx].intensity = intensity(for: injection.kind)
        sessions[idx].intervalFocus = focusLabel(for: injection)
        sessions[idx].coachAdvice = coachAdvice(for: injection, paceProfile: paceProfile)
        sessions[idx].isKeySession = true
        return workout
    }

    // MARK: - Workout building

    private static func buildWorkout(
        kind: BRaceSpecificityCalculator.Kind,
        discipline: RoadRaceDiscipline,
        paceProfile: RoadPaceProfile,
        athlete: Athlete,
        totalDuration: TimeInterval
    ) -> IntervalWorkout? {
        switch kind {
        case .vo2maxIntervals:
            return buildIntervalWorkout(
                category: .vo2max, discipline: discipline,
                paceProfile: paceProfile, athlete: athlete
            )
        case .thresholdTempo:
            return buildIntervalWorkout(
                category: .threshold, discipline: discipline,
                paceProfile: paceProfile, athlete: athlete
            )
        case .marathonPaceTempo:
            return buildIntervalWorkout(
                category: .raceSpecific, discipline: discipline,
                paceProfile: paceProfile, athlete: athlete
            )
        case .marathonPaceLongRun:
            return RoadLongRunWorkoutBuilder.build(
                variant: .marathonPaceBlocks,
                totalDuration: totalDuration,
                paceProfile: paceProfile,
                weekInPhase: 0
            )
        }
    }

    /// Picks a template from RoadIntervalLibrary matching (discipline,
    /// category) and builds via RoadWorkoutBuilder.
    private static func buildIntervalWorkout(
        category: RoadIntervalLibrary.Category,
        discipline: RoadRaceDiscipline,
        paceProfile: RoadPaceProfile,
        athlete: Athlete
    ) -> IntervalWorkout? {
        // Fetch all road templates for this discipline + the build phase
        // (most race-specific work targets build/peak), then filter by
        // category. The trail plan's actual phase doesn't matter for
        // template selection — the B-race is what we're prepping for.
        let candidates = RoadIntervalLibrary.templates(
            phase: .build,
            discipline: discipline,
            experience: athlete.experienceLevel,
            weekInPhase: 0
        ).filter { $0.category == category }

        guard let template = candidates.first else {
            // Fallback: try the broader template pool.
            let fallback = RoadIntervalLibrary.templates(
                phase: .peak, discipline: discipline,
                experience: athlete.experienceLevel, weekInPhase: 0
            ).filter { $0.category == category }.first
            guard let template = fallback else { return nil }
            return RoadWorkoutBuilder.build(
                from: template, paceProfile: paceProfile,
                experience: athlete.experienceLevel, athleteAge: athlete.age
            )
        }
        return RoadWorkoutBuilder.build(
            from: template, paceProfile: paceProfile,
            experience: athlete.experienceLevel, athleteAge: athlete.age
        )
    }

    // MARK: - Session metadata

    private static func intensity(for kind: BRaceSpecificityCalculator.Kind) -> Intensity {
        switch kind {
        case .vo2maxIntervals:        return .hard
        case .thresholdTempo:         return .moderate
        case .marathonPaceTempo:      return .moderate
        case .marathonPaceLongRun:    return .moderate
        }
    }

    private static func focusLabel(for injection: BRaceSpecificityCalculator.Injection) -> String {
        let raceLabel: String
        switch injection.bRaceDiscipline {
        case .road10K:      raceLabel = "10K"
        case .roadHalf:     raceLabel = "HM"
        case .roadMarathon: raceLabel = "Marathon"
        }
        switch injection.kind {
        case .vo2maxIntervals:     return "\(raceLabel) prep · VO2max"
        case .thresholdTempo:      return "\(raceLabel) prep · Threshold"
        case .marathonPaceTempo:   return "\(raceLabel) prep · MP tempo"
        case .marathonPaceLongRun: return "\(raceLabel) prep · MP long"
        }
    }

    private static func coachAdvice(
        for injection: BRaceSpecificityCalculator.Injection,
        paceProfile: RoadPaceProfile
    ) -> String {
        let pace = goalPaceText(for: injection.bRaceDiscipline, profile: paceProfile)
        switch injection.kind {
        case .vo2maxIntervals:
            return "🎯 10K-pace work for your upcoming road tune-up. Hit the work intervals at \(pace) — fast enough that the last rep is hard, not so fast that you fall off pace by rep 3. Borrowed from your A-race prep so it doesn't add net fatigue."
        case .thresholdTempo:
            return "🎯 Half-marathon-pace threshold work for your tune-up. Hold \(pace) — comfortably hard, sustainable for ~1 hour. The point is rhythm at race pace, not max effort."
        case .marathonPaceTempo:
            return "🎯 Marathon-pace tempo for your tune-up. \(pace) should feel like \"hard but easy\" — fueling and rhythm matter as much as the pace itself."
        case .marathonPaceLongRun:
            return "🎯 Marathon-pace blocks inside today's long run. Run easy, then drop into \(pace) for the prescribed blocks. Practice your race-day fueling. This is your most race-specific session before the tune-up."
        }
    }

    private static func goalPaceText(
        for discipline: RoadRaceDiscipline,
        profile: RoadPaceProfile
    ) -> String {
        let secondsPerKm: Double
        switch discipline {
        case .road10K:
            secondsPerKm = profile.intervalPacePerKm
        case .roadHalf:
            secondsPerKm = profile.thresholdPacePerKm
        case .roadMarathon:
            secondsPerKm = profile.marathonPacePerKm
        }
        let m = Int(secondsPerKm) / 60
        let s = Int(secondsPerKm) % 60
        return String(format: "%d:%02d/km", m, s)
    }
}
