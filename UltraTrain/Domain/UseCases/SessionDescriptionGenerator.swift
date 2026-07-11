import Foundation

/// Trail per-session descriptions. All copy is localized via
/// `String(localized:)`; the English text is the `defaultValue`.
/// Back-to-back long runs use the French trail term "Weekend Choc"
/// (Jour 1 / J2).
enum SessionDescriptionGenerator {

    // MARK: - Long Run

    static func longRun(phase: TrainingPhase, isRecoveryWeek: Bool) -> String {
        if isRecoveryWeek {
            return String(localized: "sdesc.longRun.recovery", defaultValue: "Recovery week long run. Easy effort, no pace targets. Just enjoy the trail.")
        }
        switch phase {
        case .base:
            return String(localized: "sdesc.longRun.base", defaultValue: "Long run at easy effort. Focus on building time on feet. Walk uphills freely.")
        case .build:
            return String(localized: "sdesc.longRun.build", defaultValue: "Long run with blocks at race effort. Practice your nutrition strategy.")
        case .peak:
            return String(localized: "sdesc.longRun.peak", defaultValue: "Race simulation long run. Start easy, build to race effort. Full nutrition and gear rehearsal.")
        case .taper:
            return String(localized: "sdesc.longRun.taper", defaultValue: "Reduced long run at easy effort. Trust your fitness.")
        case .recovery, .race:
            return String(localized: "sdesc.longRun.recoveryRace", defaultValue: "Easy long run. Conversational pace. Focus on recovery and movement quality.")
        }
    }

    // MARK: - B2B (Weekend Choc)

    static func b2bDay1(phase: TrainingPhase) -> String {
        switch phase {
        case .build:
            return String(localized: "sdesc.b2b.day1.build", defaultValue: "Back-to-back Day 1: Long run building fatigue for tomorrow. Easy pace. Practice fueling.")
        case .peak:
            return String(localized: "sdesc.b2b.day1.peak", defaultValue: "Back-to-back Day 1: Long effort building toward race intensity. Include terrain-specific sections.")
        default:
            return String(localized: "sdesc.b2b.day1.default", defaultValue: "Back-to-back Day 1: Long run at easy pace. Fuel well for tomorrow.")
        }
    }

    static func b2bDay2(phase: TrainingPhase) -> String {
        switch phase {
        case .build:
            return String(localized: "sdesc.b2b.day2.build", defaultValue: "Back-to-back Day 2: Run on tired legs. First hour very easy, then build to race effort.")
        case .peak:
            return String(localized: "sdesc.b2b.day2.peak", defaultValue: "Back-to-back Day 2: Start on yesterday's fatigue. Build from easy to race effort. Full race simulation.")
        default:
            return String(localized: "sdesc.b2b.day2.default", defaultValue: "Back-to-back Day 2: Long run on tired legs. Stay patient, keep it easy.")
        }
    }

    // MARK: - Uphill Intervals

    static func verticalGain(phase: TrainingPhase, isRecoveryWeek: Bool) -> String {
        if isRecoveryWeek {
            return String(localized: "sdesc.vg.recovery", defaultValue: "Light uphill intervals. Easy climbing effort. No pushing.")
        }
        switch phase {
        case .base:
            return String(localized: "sdesc.vg.base", defaultValue: "Uphill intervals at moderate effort. Focus on form, cadence, and power hiking technique.")
        case .build:
            return String(localized: "sdesc.vg.build", defaultValue: "Uphill intervals at threshold effort. Build race-specific climbing endurance.")
        case .peak:
            return String(localized: "sdesc.vg.peak", defaultValue: "Race-specific climbing. Short steep repeats mimicking your race profile.")
        case .taper:
            return String(localized: "sdesc.vg.taper", defaultValue: "Light uphill intervals. Short climbs to stay sharp.")
        case .recovery, .race:
            return String(localized: "sdesc.vg.recoveryRace", defaultValue: "Easy uphill intervals at comfortable effort.")
        }
    }

    // MARK: - Intervals

    static func intervals(phase: TrainingPhase, isRecoveryWeek: Bool, weekInPhase: Int = 0) -> String {
        if isRecoveryWeek {
            return String(localized: "sdesc.intervals.recovery", defaultValue: "Recovery week: no hard intervals. Easy effort only.")
        }
        // `.intervals` is the flat/speed session type — `.verticalGain`
        // (see the `sdesc.vg.*` cases above) is the dedicated hill/climbing
        // type. Keep this copy flat/threshold-themed; "uphill"/"hill"/
        // "climbs" here was a mislabeling bug duplicating the VG copy.
        switch phase {
        case .base:
            return String(localized: "sdesc.intervals.base", defaultValue: "Flat threshold intervals. Short reps with equal recovery.")
        case .build:
            if weekInPhase < 6 {
                return String(localized: "sdesc.intervals.buildEarly", defaultValue: "Fast intervals at high intensity. Short hard reps with full recovery.")
            }
            return String(localized: "sdesc.intervals.buildLate", defaultValue: "Sustained threshold work at race effort. Practice fueling.")
        case .peak:
            return String(localized: "sdesc.intervals.peak", defaultValue: "Threshold intervals at race effort. Medium reps building endurance.")
        case .taper:
            return String(localized: "sdesc.intervals.taper", defaultValue: "Short opener intervals to stay sharp without fatiguing.")
        case .recovery, .race:
            return String(localized: "sdesc.intervals.recoveryRace", defaultValue: "Easy effort. No hard intervals this week.")
        }
    }

    // MARK: - Tempo

    static func tempo(phase: TrainingPhase) -> String {
        switch phase {
        case .base:
            return String(localized: "sdesc.tempo.base", defaultValue: "Tempo run at threshold effort. Build sustained race pace ability.")
        case .build:
            return String(localized: "sdesc.tempo.build", defaultValue: "Tempo blocks at race effort. Practice pacing and fueling.")
        case .peak:
            return String(localized: "sdesc.tempo.peak", defaultValue: "Race-pace tempo on varied terrain.")
        case .taper:
            return String(localized: "sdesc.tempo.taper", defaultValue: "Short tempo to stay sharp. Controlled effort.")
        default:
            return String(localized: "sdesc.tempo.default", defaultValue: "Easy tempo at comfortable effort.")
        }
    }

    // MARK: - Cross-Training

    static func crossTraining() -> String {
        String(localized: "sdesc.crossTraining", defaultValue: "Cross-training: cycling, swimming, hiking, or yoga. Active recovery without impact.")
    }

    // MARK: - Easy Run

    static func easyRun(isRecoveryWeek: Bool, isPreLongRun: Bool = false, isPreRace: Bool = false) -> String {
        if isRecoveryWeek {
            return String(localized: "sdesc.easy.recovery", defaultValue: "Recovery week easy jog. Conversational pace. Blood flow, not fitness.")
        }
        if isPreRace {
            return String(localized: "sdesc.easy.preRace", defaultValue: "Pre-race shakeout. Short easy jog. Stay loose and relaxed.")
        }
        if isPreLongRun {
            return String(localized: "sdesc.easy.preLong", defaultValue: "Easy run to loosen up before the long run. Keep it conversational.")
        }
        return String(localized: "sdesc.easy.default", defaultValue: "Easy run at conversational pace. Active recovery between quality sessions.")
    }

    // MARK: - Taper Sub-Phase

    static func taperLongRun(subPhase: TaperProfile.SubPhase) -> String {
        switch subPhase {
        case .volumeTransition:
            return String(localized: "sdesc.taperLong.vt", defaultValue: "Taper long run. Reduced volume, easy effort. Practice your nutrition one last time.")
        case .trueTaper:
            return String(localized: "sdesc.taperLong.tt", defaultValue: "Short taper long run. Easy effort. Your fitness is locked in.")
        }
    }

    static func taperIntervals(subPhase: TaperProfile.SubPhase) -> String {
        switch subPhase {
        case .volumeTransition:
            return String(localized: "sdesc.taperInt.vt", defaultValue: "Taper intervals. Short reps at race effort to maintain sharpness.")
        case .trueTaper:
            return String(localized: "sdesc.taperInt.tt", defaultValue: "Opener strides. Short pickups to stay sharp.")
        }
    }

    static func taperVerticalGain(subPhase: TaperProfile.SubPhase) -> String {
        switch subPhase {
        case .volumeTransition:
            return String(localized: "sdesc.taperVG.vt", defaultValue: "Light uphill intervals. Short climbs at moderate effort.")
        case .trueTaper:
            return String(localized: "sdesc.taperVG.tt", defaultValue: "No hard climbing this week. Easy terrain only.")
        }
    }

    static func taperEasyRun(subPhase: TaperProfile.SubPhase) -> String {
        switch subPhase {
        case .volumeTransition:
            return String(localized: "sdesc.taperEasy.vt", defaultValue: "Easy taper run. Volume is dropping by design.")
        case .trueTaper:
            return String(localized: "sdesc.taperEasy.tt", defaultValue: "Short easy run. Keep legs loose for race day.")
        }
    }

    static func taperStrides() -> String {
        String(localized: "sdesc.taperStrides", defaultValue: "Opener strides: short pickups at fast but controlled effort. Full recovery between reps.")
    }

    // MARK: - Rest

    static func rest(isRecoveryWeek: Bool, isPreRace: Bool = false) -> String {
        if isPreRace {
            return String(localized: "sdesc.rest.preRace", defaultValue: "Rest day. Final gear check, carb-load, and visualize your race plan.")
        }
        if isRecoveryWeek {
            return String(localized: "sdesc.rest.recovery", defaultValue: "Recovery week rest. Sleep well, eat well. Your body is adapting.")
        }
        return String(localized: "sdesc.rest.default", defaultValue: "Rest day. Recovery is part of training. Prioritize sleep.")
    }
}
