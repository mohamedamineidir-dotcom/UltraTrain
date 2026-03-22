import Foundation

enum SessionDescriptionGenerator {

    // MARK: - Long Run

    static func longRun(phase: TrainingPhase, isRecoveryWeek: Bool) -> String {
        if isRecoveryWeek {
            return "Recovery week long run. Easy effort throughout. Enjoy the trail — no pace targets."
        }
        switch phase {
        case .base:
            return "Long run at easy effort (Zone 2). Focus on building time on feet. Walk all uphills freely."
        case .build:
            return "Long run with race-effort blocks. Include 20-30min at goal race pace mid-run. Practice nutrition."
        case .peak:
            return "Race simulation long run. Start easy, build to race effort. Full nutrition and gear rehearsal."
        case .taper:
            return "Reduced long run. Easy effort. Trust your fitness — save it for race day."
        case .recovery, .race:
            return "Easy long run. Conversational pace only. Focus on recovery and movement quality."
        }
    }

    // MARK: - B2B

    static func b2bDay1(phase: TrainingPhase) -> String {
        switch phase {
        case .build:
            return "B2B Day 1: Long run building fatigue for tomorrow. Easy pace (Zone 2). Practice fueling."
        case .peak:
            return "B2B Day 1: Long effort building toward race intensity. Include terrain-specific sections."
        default:
            return "B2B Day 1: Long run at easy pace. Fuel well — tomorrow runs on today's fatigue."
        }
    }

    static func b2bDay2(phase: TrainingPhase) -> String {
        switch phase {
        case .build:
            return "B2B Day 2: Run on tired legs. First hour very easy, then build to race effort. Ultra-specific fatigue training."
        case .peak:
            return "B2B Day 2: Start on yesterday's fatigue. Build from easy to race effort. Full race simulation."
        default:
            return "B2B Day 2: Long run on tired legs. Simulate ultra fatigue. Stay patient (Zone 2)."
        }
    }

    // MARK: - Uphill Intervals

    static func verticalGain(phase: TrainingPhase, isRecoveryWeek: Bool) -> String {
        if isRecoveryWeek {
            return "Light uphill intervals. Easy effort climbs. Enjoy the trail without pushing."
        }
        switch phase {
        case .base:
            return "Uphill intervals: hill repeats at moderate effort. Focus on form, cadence, and power hiking technique."
        case .build:
            return "Uphill intervals: sustained climbing at threshold effort. Build race-specific climbing endurance."
        case .peak:
            return "Uphill intervals: race-specific climbing. Short steep repeats mimicking your race profile."
        case .taper:
            return "Light uphill intervals. Short climbs to stay sharp. Controlled effort."
        case .recovery, .race:
            return "Easy uphill intervals. Light climbing at comfortable effort."
        }
    }

    // MARK: - Intervals

    static func intervals(phase: TrainingPhase, isRecoveryWeek: Bool, weekInPhase: Int = 0) -> String {
        if isRecoveryWeek {
            return "Recovery week: no intervals. Easy effort only."
        }
        switch phase {
        case .base:
            return "Short uphill threshold intervals — 30min total at tempo (Zone 3-4). Short reps with equal recovery on hills."
        case .build:
            if weekInPhase < 6 {
                return "VO2max hill repeats (Zone 4). Short intense climbs with full recovery. Push hard but controlled."
            }
            return "Sustained threshold — 60min total work at race effort (Zone 3-4) on rolling terrain. Practice fueling."
        case .peak:
            return "Sustained threshold intervals — 60min total at race effort (Zone 3-4). Medium reps building endurance."
        case .taper:
            return "Opener intervals. Short efforts to stay sharp without fatiguing."
        case .recovery, .race:
            return "Easy effort. No hard intervals this week."
        }
    }

    // MARK: - Tempo

    static func tempo(phase: TrainingPhase) -> String {
        switch phase {
        case .base:
            return "Tempo run at threshold effort (Zone 3). Build sustained race pace ability."
        case .build:
            return "Tempo blocks at race effort (Zone 3-4). Practice pacing and fueling."
        case .peak:
            return "Race-pace tempo. Run at target race effort on varied terrain."
        case .taper:
            return "Short tempo to stay sharp. Controlled effort, don't push."
        default:
            return "Easy tempo at comfortable effort."
        }
    }

    // MARK: - Cross-Training

    static func crossTraining() -> String {
        "Cross-training: cycling, swimming, hiking, or yoga. Active recovery without impact."
    }

    // MARK: - Easy Run

    static func easyRun(isRecoveryWeek: Bool, isPreLongRun: Bool = false, isPreRace: Bool = false) -> String {
        if isRecoveryWeek {
            return "Recovery week: easy jog at conversational pace. Focus on blood flow, not fitness."
        }
        if isPreRace {
            return "Pre-race shakeout. Short, easy jog. Stay loose and relaxed."
        }
        if isPreLongRun {
            return "Easy run. Loosen up before the long run. Keep effort conversational (Zone 2)."
        }
        return "Easy run at conversational pace (Zone 2). Active recovery between quality sessions."
    }

    // MARK: - Taper Sub-Phase

    static func taperLongRun(subPhase: TaperProfile.SubPhase) -> String {
        switch subPhase {
        case .volumeTransition:
            return "Taper long run. Reduced volume, easy effort. Practice nutrition strategy one last time."
        case .trueTaper:
            return "Short taper long run. Easy effort. The hay is in the barn — trust your fitness."
        }
    }

    static func taperIntervals(subPhase: TaperProfile.SubPhase) -> String {
        switch subPhase {
        case .volumeTransition:
            return "Taper intervals. Maintain sharpness with reduced volume. Short reps at race effort."
        case .trueTaper:
            return "Opener strides. 4-6 × 20s pickups. Stay sharp without fatiguing."
        }
    }

    static func taperVerticalGain(subPhase: TaperProfile.SubPhase) -> String {
        switch subPhase {
        case .volumeTransition:
            return "Light uphill intervals. Short climbs at moderate effort. Maintain climbing legs."
        case .trueTaper:
            return "No quality climbing this week. Easy terrain only."
        }
    }

    static func taperEasyRun(subPhase: TaperProfile.SubPhase) -> String {
        switch subPhase {
        case .volumeTransition:
            return "Easy taper run. Volume dropping by design — don't add extra."
        case .trueTaper:
            return "Short easy run. Conversational pace. Keep legs loose for race day."
        }
    }

    static func taperStrides() -> String {
        "Opener strides: 4-6 × 20s pickups at fast but controlled effort. Full recovery between reps."
    }

    // MARK: - Rest

    static func rest(isRecoveryWeek: Bool, isPreRace: Bool = false) -> String {
        if isPreRace {
            return "Rest day. Final gear check, carb-load, and visualize your race plan."
        }
        if isRecoveryWeek {
            return "Recovery week rest. Sleep well, eat well. Your body is adapting."
        }
        return "Rest day. Recovery is part of training. Prioritize sleep."
    }
}
