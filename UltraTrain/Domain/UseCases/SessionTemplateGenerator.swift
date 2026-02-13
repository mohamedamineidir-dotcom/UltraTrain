import Foundation

enum SessionTemplateGenerator {

    struct SessionTemplate: Sendable {
        let dayOffset: Int // 0 = Monday, 6 = Sunday
        let type: SessionType
        let intensity: Intensity
        let volumeFraction: Double
        let description: String
    }

    // MARK: - Public

    static func sessions(
        for skeleton: WeekSkeletonBuilder.WeekSkeleton,
        volume: VolumeCalculator.WeekVolume,
        experience: ExperienceLevel,
        raceOverride: IntermediateRaceHandler.RaceWeekOverride? = nil
    ) -> [TrainingSession] {
        let templates: [SessionTemplate]

        if let override = raceOverride {
            templates = overrideTemplates(for: override.behavior)
        } else if skeleton.isRecoveryWeek {
            templates = recoveryTemplates()
        } else {
            templates = phaseTemplates(for: skeleton.phase, experience: experience)
        }

        let totalFraction = templates.reduce(0.0) { $0 + $1.volumeFraction }

        return templates.map { template in
            let distance = totalFraction > 0
                ? volume.targetVolumeKm * (template.volumeFraction / totalFraction)
                : 0
            let elevation = totalFraction > 0
                ? volume.targetElevationGainM * (template.volumeFraction / totalFraction)
                : 0
            let estimatedDuration = estimateDuration(distanceKm: distance, intensity: template.intensity)

            return TrainingSession(
                id: UUID(),
                date: skeleton.startDate.adding(days: template.dayOffset),
                type: template.type,
                plannedDistanceKm: (distance * 10).rounded() / 10,
                plannedElevationGainM: (elevation * 10).rounded() / 10,
                plannedDuration: estimatedDuration,
                intensity: template.intensity,
                description: template.description,
                nutritionNotes: nutritionNotes(duration: estimatedDuration, distance: distance),
                isCompleted: false,
                linkedRunId: nil
            )
        }
    }

    // MARK: - Phase Templates

    private static func phaseTemplates(for phase: TrainingPhase, experience: ExperienceLevel) -> [SessionTemplate] {
        switch phase {
        case .base:
            return baseTemplates()
        case .build:
            return buildTemplates(experience: experience)
        case .peak:
            return peakTemplates(experience: experience)
        case .taper:
            return taperTemplates()
        case .recovery, .race:
            return recoveryTemplates()
        }
    }

    private static func baseTemplates() -> [SessionTemplate] {
        [
            SessionTemplate(dayOffset: 0, type: .rest, intensity: .easy, volumeFraction: 0,
                           description: "Rest day. Focus on sleep and mobility work."),
            SessionTemplate(dayOffset: 1, type: .recovery, intensity: .easy, volumeFraction: 0.10,
                           description: "Easy recovery run at conversational pace. Keep heart rate in Zone 1-2."),
            SessionTemplate(dayOffset: 2, type: .rest, intensity: .easy, volumeFraction: 0,
                           description: "Rest day. Light stretching or yoga recommended."),
            SessionTemplate(dayOffset: 3, type: .tempo, intensity: .moderate, volumeFraction: 0.15,
                           description: "Tempo run at comfortably hard pace. Maintain steady effort in Zone 3."),
            SessionTemplate(dayOffset: 4, type: .rest, intensity: .easy, volumeFraction: 0,
                           description: "Rest day. Prepare gear and nutrition for the long run."),
            SessionTemplate(dayOffset: 5, type: .longRun, intensity: .easy, volumeFraction: 0.45,
                           description: "Long run at easy pace. Practice race-day nutrition strategy. Stay in Zone 2."),
            SessionTemplate(dayOffset: 6, type: .crossTraining, intensity: .easy, volumeFraction: 0.10,
                           description: "Cross-training: cycling, swimming, or hiking. Active recovery.")
        ]
    }

    private static func buildTemplates(experience: ExperienceLevel) -> [SessionTemplate] {
        var templates = [
            SessionTemplate(dayOffset: 0, type: .rest, intensity: .easy, volumeFraction: 0,
                           description: "Rest day. Prioritize sleep for adaptation."),
            SessionTemplate(dayOffset: 1, type: .intervals, intensity: .hard, volumeFraction: 0.12,
                           description: "Interval session: 6-8 x 3min hard / 2min easy. Build speed and VO2max."),
            SessionTemplate(dayOffset: 2, type: .recovery, intensity: .easy, volumeFraction: 0.08,
                           description: "Easy recovery run. Flush legs from yesterday's intervals."),
            SessionTemplate(dayOffset: 3, type: .tempo, intensity: .moderate, volumeFraction: 0.15,
                           description: "Tempo run with sustained effort. Practice pacing for race intensity."),
            SessionTemplate(dayOffset: 4, type: .rest, intensity: .easy, volumeFraction: 0,
                           description: "Rest day. Hydrate well ahead of the weekend."),
            SessionTemplate(dayOffset: 5, type: .longRun, intensity: .easy, volumeFraction: 0.40,
                           description: "Long run on trail terrain. Include elevation if possible. Practice nutrition."),
            SessionTemplate(dayOffset: 6, type: .crossTraining, intensity: .easy, volumeFraction: 0.10,
                           description: "Cross-training or easy hike. Keep intensity low.")
        ]

        if experience == .advanced || experience == .elite {
            templates[3] = SessionTemplate(dayOffset: 3, type: .verticalGain, intensity: .hard, volumeFraction: 0.15,
                                           description: "Vertical gain session: hill repeats or stair climbing. Build climbing strength.")
        }
        return templates
    }

    private static func peakTemplates(experience: ExperienceLevel) -> [SessionTemplate] {
        [
            SessionTemplate(dayOffset: 0, type: .rest, intensity: .easy, volumeFraction: 0,
                           description: "Rest day. Mental preparation and gear check."),
            SessionTemplate(dayOffset: 1, type: .intervals, intensity: .hard, volumeFraction: 0.10,
                           description: "Short sharp intervals: 8-10 x 1min hard / 1min easy. Maintain sharpness."),
            SessionTemplate(dayOffset: 2, type: .recovery, intensity: .easy, volumeFraction: 0.08,
                           description: "Easy recovery run. Focus on form and relaxation."),
            SessionTemplate(dayOffset: 3, type: .verticalGain, intensity: .hard, volumeFraction: 0.12,
                           description: "Vertical gain work on steep terrain. Practice power hiking technique."),
            SessionTemplate(dayOffset: 4, type: .rest, intensity: .easy, volumeFraction: 0,
                           description: "Rest day. Pre-hydrate for the weekend block."),
            SessionTemplate(dayOffset: 5, type: .longRun, intensity: .moderate, volumeFraction: 0.40,
                           description: "Peak long run simulating race conditions. Full nutrition rehearsal."),
            SessionTemplate(dayOffset: 6, type: experience == .elite ? .backToBack : .crossTraining,
                           intensity: experience == .elite ? .moderate : .easy,
                           volumeFraction: experience == .elite ? 0.20 : 0.10,
                           description: experience == .elite
                               ? "Back-to-back long effort: run on tired legs to simulate ultra fatigue."
                               : "Cross-training or easy hike. Keep intensity low.")
        ]
    }

    private static func taperTemplates() -> [SessionTemplate] {
        [
            SessionTemplate(dayOffset: 0, type: .rest, intensity: .easy, volumeFraction: 0,
                           description: "Rest day. Enjoy the taper — trust your training."),
            SessionTemplate(dayOffset: 1, type: .intervals, intensity: .moderate, volumeFraction: 0.12,
                           description: "Short opener intervals: 4-5 x 2min at tempo / 2min easy. Stay sharp."),
            SessionTemplate(dayOffset: 2, type: .rest, intensity: .easy, volumeFraction: 0,
                           description: "Rest day. Light stretching and foam rolling."),
            SessionTemplate(dayOffset: 3, type: .recovery, intensity: .easy, volumeFraction: 0.10,
                           description: "Easy shakeout run. Keep it short and comfortable."),
            SessionTemplate(dayOffset: 4, type: .rest, intensity: .easy, volumeFraction: 0,
                           description: "Rest day. Final gear and nutrition prep."),
            SessionTemplate(dayOffset: 5, type: .longRun, intensity: .easy, volumeFraction: 0.25,
                           description: "Reduced long run at easy effort. No heroics — save it for race day."),
            SessionTemplate(dayOffset: 6, type: .rest, intensity: .easy, volumeFraction: 0,
                           description: "Full rest. Sleep, hydrate, visualize your race.")
        ]
    }

    private static func recoveryTemplates() -> [SessionTemplate] {
        [
            SessionTemplate(dayOffset: 0, type: .rest, intensity: .easy, volumeFraction: 0,
                           description: "Recovery week rest day. Let your body absorb the training."),
            SessionTemplate(dayOffset: 1, type: .recovery, intensity: .easy, volumeFraction: 0.12,
                           description: "Easy recovery jog. Very comfortable pace, Zone 1 only."),
            SessionTemplate(dayOffset: 2, type: .rest, intensity: .easy, volumeFraction: 0,
                           description: "Rest day. Focus on nutrition and sleep quality."),
            SessionTemplate(dayOffset: 3, type: .crossTraining, intensity: .easy, volumeFraction: 0.10,
                           description: "Light cross-training: swimming, yoga, or gentle cycling."),
            SessionTemplate(dayOffset: 4, type: .rest, intensity: .easy, volumeFraction: 0,
                           description: "Rest day. Stretching and mobility work."),
            SessionTemplate(dayOffset: 5, type: .longRun, intensity: .easy, volumeFraction: 0.25,
                           description: "Reduced long run at very easy pace. Enjoy the scenery."),
            SessionTemplate(dayOffset: 6, type: .rest, intensity: .easy, volumeFraction: 0,
                           description: "Full rest day. You've earned it.")
        ]
    }

    // MARK: - Race Override Templates

    private static func overrideTemplates(for behavior: IntermediateRaceHandler.Behavior) -> [SessionTemplate] {
        switch behavior {
        case .miniTaper:
            return taperTemplates()
        case .raceWeek:
            return [
                SessionTemplate(dayOffset: 0, type: .rest, intensity: .easy, volumeFraction: 0,
                               description: "Rest before race. Stay off your feet."),
                SessionTemplate(dayOffset: 1, type: .recovery, intensity: .easy, volumeFraction: 0.08,
                               description: "Short shakeout run. 15-20 min at easy pace."),
                SessionTemplate(dayOffset: 2, type: .rest, intensity: .easy, volumeFraction: 0,
                               description: "Rest day. Carb-load and hydrate."),
                SessionTemplate(dayOffset: 3, type: .rest, intensity: .easy, volumeFraction: 0,
                               description: "Rest day. Final race prep and gear check."),
                SessionTemplate(dayOffset: 4, type: .rest, intensity: .easy, volumeFraction: 0,
                               description: "Rest day. Visualize your race plan."),
                SessionTemplate(dayOffset: 5, type: .rest, intensity: .maxEffort, volumeFraction: 0,
                               description: "RACE DAY! Execute your plan. Trust your training."),
                SessionTemplate(dayOffset: 6, type: .rest, intensity: .easy, volumeFraction: 0,
                               description: "Post-race recovery. Walk, stretch, refuel.")
            ]
        case .postRaceRecovery:
            return recoveryTemplates()
        }
    }

    // MARK: - Helpers

    private static func estimateDuration(distanceKm: Double, intensity: Intensity) -> TimeInterval {
        guard distanceKm > 0 else { return 0 }
        // Pace in min/km by intensity
        let paceMinPerKm: Double = switch intensity {
        case .easy:      7.0
        case .moderate:  6.0
        case .hard:      5.5
        case .maxEffort: 5.0
        }
        return distanceKm * paceMinPerKm * 60.0
    }

    private static func nutritionNotes(duration: TimeInterval, distance: Double) -> String? {
        let hours = duration / 3600.0
        guard hours > 1.0 else { return nil }

        var notes = "Carry water and fuel for this session."

        if hours > 1.5 {
            let carbsPerHour = 60 // grams for efforts > 1.5h
            notes += " Aim for ~\(carbsPerHour)g carbs/hour (gels, bars, or real food)."
        }

        if hours > 2.0 {
            notes += " Practice your race-day nutrition plan. Train your gut."
        }

        if distance > 30 {
            notes += " Consider electrolyte supplementation (~600mg sodium/hour)."
        }

        return notes
    }
}
