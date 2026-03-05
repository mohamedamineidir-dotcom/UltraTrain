import Foundation

// MARK: - Phase & Override Templates

extension SessionTemplateGenerator {

    // MARK: - Phase Dispatch

    static func phaseTemplates(
        for phase: TrainingPhase,
        experience: ExperienceLevel,
        raceEffectiveKm: Double,
        weekInPhase: Int
    ) -> [SessionTemplate] {
        switch phase {
        case .base:
            return baseTemplates(experience: experience)
        case .build:
            return buildTemplates(experience: experience, raceEffectiveKm: raceEffectiveKm, weekInPhase: weekInPhase)
        case .peak:
            return peakTemplates(experience: experience, raceEffectiveKm: raceEffectiveKm, weekInPhase: weekInPhase)
        case .taper:
            return taperTemplates()
        case .recovery, .race:
            return recoveryTemplates(experience: experience)
        }
    }

    // MARK: - Base

    static func baseTemplates(experience: ExperienceLevel) -> [SessionTemplate] {
        [
            tpl(0, .rest, .easy, 0, "Rest day. Focus on sleep and mobility work."),
            tpl(1, .recovery, .easy, 0.10, "Easy recovery run at conversational pace. Keep heart rate in Zone 1-2."),
            tpl(2, .rest, .easy, 0, "Rest day. Light stretching or yoga recommended."),
            tpl(3, .tempo, .moderate, 0.15, "Tempo run at comfortably hard pace. Maintain steady effort in Zone 3."),
            tpl(4, .rest, .easy, 0, "Rest day. Prepare gear and nutrition for the long run."),
            tplTime(5, .longRun, .easy, 0.30, "Long run at easy pace. Practice race-day nutrition strategy. Stay in Zone 2."),
            crossTrainingOrAlternative(day: 6, experience: experience)
        ]
    }

    // MARK: - Build

    static func buildTemplates(experience: ExperienceLevel, raceEffectiveKm: Double, weekInPhase: Int) -> [SessionTemplate] {
        let hasSignificantElevation = raceEffectiveKm > 0 && raceEffectiveKm > 1.3 * (raceEffectiveKm - raceEffectiveKm * 0.23)
        let wantsDoubleVertical = hasSignificantElevation && weekInPhase % 2 == 1 && (experience == .advanced || experience == .elite)
        let wantsB2B = shouldHaveB2B(phase: .build, experience: experience, raceEffectiveKm: raceEffectiveKm)

        var templates: [SessionTemplate] = [
            tpl(0, .rest, .easy, 0, "Rest day. Prioritize sleep for adaptation."),
        ]

        if wantsDoubleVertical && !wantsB2B {
            templates += [
                tpl(1, .verticalGain, .hard, 0.12, "VO2max hill repeats. Short, intense climbs to build power."),
                tpl(2, .recovery, .easy, 0.08, "Easy recovery run. Flush legs from yesterday's effort."),
                tpl(3, .verticalGain, .moderate, 0.15, "Endurance climbing. Longer moderate efforts to build vertical stamina."),
            ]
        } else {
            templates += [
                tpl(1, .intervals, .hard, 0.12, "Interval session. Build speed and VO2max."),
                tpl(2, .recovery, .easy, 0.08, "Easy recovery run. Flush legs from yesterday's intervals."),
            ]
            if experience == .advanced || experience == .elite {
                templates.append(tpl(3, .verticalGain, .hard, 0.15, "Vertical gain session. Build climbing strength."))
            } else {
                templates.append(tpl(3, .tempo, .moderate, 0.15, "Tempo run with sustained effort. Practice pacing for race intensity."))
            }
        }

        templates.append(tpl(4, .rest, .easy, 0, "Rest day. Hydrate well ahead of the weekend."))

        if wantsB2B {
            templates += [
                tplTime(5, .longRun, .easy, 0.25, "Back-to-back day 1. Moderate long run building fatigue for tomorrow."),
                tplTime(6, .backToBack, .easy, 0.30, "Back-to-back day 2. Long run on tired legs to simulate ultra fatigue."),
            ]
        } else {
            templates += [
                tplTime(5, .longRun, .easy, 0.30, "Long run on trail terrain. Include elevation if possible. Practice nutrition."),
                crossTrainingOrAlternative(day: 6, experience: experience),
            ]
        }

        return templates
    }

    // MARK: - Peak

    static func peakTemplates(experience: ExperienceLevel, raceEffectiveKm: Double, weekInPhase: Int) -> [SessionTemplate] {
        let wantsB2B = shouldHaveB2B(phase: .peak, experience: experience, raceEffectiveKm: raceEffectiveKm)

        var templates: [SessionTemplate] = [
            tpl(0, .rest, .easy, 0, "Rest day. Mental preparation and gear check."),
        ]

        if wantsB2B {
            templates += [
                tpl(1, .intervals, .hard, 0.10, "Short sharp intervals. Maintain sharpness."),
                tpl(2, .recovery, .easy, 0.08, "Easy recovery run. Focus on form and relaxation."),
                tpl(3, .recovery, .easy, 0.07, "Light recovery jog. Keep legs loose."),
                tpl(4, .rest, .easy, 0, "Rest day. Pre-hydrate for the weekend block."),
                tplTime(5, .longRun, .moderate, 0.22, "Back-to-back day 1. Steady effort building fatigue."),
                tplTime(6, .backToBack, .moderate, 0.28, "Back-to-back day 2. Peak simulation on tired legs. Full nutrition rehearsal."),
            ]
        } else {
            templates += [
                tpl(1, .intervals, .hard, 0.10, "Short sharp intervals. Maintain sharpness."),
                tpl(2, .recovery, .easy, 0.08, "Easy recovery run. Focus on form and relaxation."),
                tpl(3, .verticalGain, .hard, 0.12, "Vertical gain work on steep terrain. Practice power hiking."),
                tpl(4, .rest, .easy, 0, "Rest day. Pre-hydrate for the weekend block."),
                tplTime(5, .longRun, .moderate, 0.30, "Peak long run simulating race conditions. Full nutrition rehearsal."),
                crossTrainingOrAlternative(day: 6, experience: experience),
            ]
        }

        return templates
    }

    // MARK: - Taper

    static func taperTemplates() -> [SessionTemplate] {
        [
            tpl(0, .rest, .easy, 0, "Rest day. Enjoy the taper — trust your training."),
            tpl(1, .intervals, .moderate, 0.12, "Short opener intervals. Stay sharp without fatiguing."),
            tpl(2, .rest, .easy, 0, "Rest day. Light stretching and foam rolling."),
            tpl(3, .recovery, .easy, 0.10, "Easy shakeout run. Keep it short and comfortable."),
            tpl(4, .rest, .easy, 0, "Rest day. Final gear and nutrition prep."),
            tplTime(5, .longRun, .easy, 0.25, "Reduced long run at easy effort. No heroics — save it for race day."),
            tpl(6, .rest, .easy, 0, "Full rest. Sleep, hydrate, visualize your race.")
        ]
    }

    // MARK: - Recovery

    static func recoveryTemplates(experience: ExperienceLevel) -> [SessionTemplate] {
        [
            tpl(0, .rest, .easy, 0, "Recovery week rest day. Let your body absorb the training."),
            tpl(1, .recovery, .easy, 0.12, "Easy recovery jog. Very comfortable pace, Zone 1 only."),
            tpl(2, .rest, .easy, 0, "Rest day. Focus on nutrition and sleep quality."),
            crossTrainingOrAlternative(day: 3, experience: experience, isRecoveryWeek: true),
            tpl(4, .rest, .easy, 0, "Rest day. Stretching and mobility work."),
            tplTime(5, .longRun, .easy, 0.25, "Reduced long run at very easy pace. Enjoy the scenery."),
            tpl(6, .rest, .easy, 0, "Full rest day. You've earned it.")
        ]
    }

    // MARK: - Race Override Templates

    static func overrideTemplates(for behavior: IntermediateRaceHandler.Behavior, experience: ExperienceLevel) -> [SessionTemplate] {
        switch behavior {
        case .miniTaper:
            return taperTemplates()
        case .raceWeek(let priority):
            return priority == .cRace ? cRaceWeekTemplates() : bRaceWeekTemplates()
        case .postRaceRecovery:
            return recoveryTemplates(experience: experience)
        }
    }

    static func bRaceWeekTemplates() -> [SessionTemplate] {
        [
            tpl(0, .rest, .easy, 0, "Rest before race. Stay off your feet."),
            tpl(1, .recovery, .easy, 0.08, "Short shakeout run. 15-20 min at easy pace."),
            tpl(2, .rest, .easy, 0, "Rest day. Carb-load and hydrate."),
            tpl(3, .rest, .easy, 0, "Rest day. Final race prep and gear check."),
            tpl(4, .rest, .easy, 0, "Rest day. Visualize your race plan."),
            tpl(5, .rest, .maxEffort, 0, "RACE DAY! Execute your plan. Trust your training."),
            tpl(6, .rest, .easy, 0, "Post-race recovery. Walk, stretch, refuel.")
        ]
    }

    static func cRaceWeekTemplates() -> [SessionTemplate] {
        [
            tpl(0, .rest, .easy, 0, "Rest day. Easy start to race week."),
            tpl(1, .recovery, .easy, 0.10, "Easy run at conversational pace. Keep it short."),
            tpl(2, .rest, .easy, 0, "Rest day. Light stretching."),
            tpl(3, .tempo, .moderate, 0.12, "Short tempo effort. Stay sharp but save energy for race."),
            tpl(4, .rest, .easy, 0, "Rest day. Prepare race gear and nutrition."),
            tpl(5, .rest, .maxEffort, 0, "RACE DAY! Use this as a hard training effort."),
            tpl(6, .recovery, .easy, 0.08, "Easy recovery run. Shake out race-day legs.")
        ]
    }

    // MARK: - B2B Logic

    static func shouldHaveB2B(phase: TrainingPhase, experience: ExperienceLevel, raceEffectiveKm: Double) -> Bool {
        switch (phase, experience) {
        case (.peak, .intermediate): raceEffectiveKm >= 100
        case (.peak, .advanced):     raceEffectiveKm >= 80
        case (.peak, .elite):        raceEffectiveKm >= 80
        case (.build, .advanced):    raceEffectiveKm >= 100
        case (.build, .elite):       raceEffectiveKm >= 80
        default: false
        }
    }

    // MARK: - Cross-Training / Alternative

    static func crossTrainingOrAlternative(
        day: Int,
        experience: ExperienceLevel,
        isRecoveryWeek: Bool = false
    ) -> SessionTemplate {
        switch experience {
        case .elite:
            return tpl(day, .crossTraining, .easy, 0.10,
                "Cross-training: cycling, swimming, or hiking. Active recovery.")
        case .advanced where isRecoveryWeek:
            return tpl(day, .crossTraining, .easy, 0.10,
                "Light cross-training: swimming, yoga, or gentle cycling.")
        case .advanced:
            return tpl(day, .recovery, .easy, 0.08,
                "Easy recovery run. Keep the pace conversational.")
        case .beginner, .intermediate:
            return tpl(day, .rest, .easy, 0,
                "Rest day. Recovery is part of training.")
        }
    }
}
