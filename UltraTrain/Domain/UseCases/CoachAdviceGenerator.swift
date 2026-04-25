import Foundation

enum CoachAdviceGenerator {

    static func advice(
        for type: SessionType,
        intensity: Intensity,
        phase: TrainingPhase,
        weekInPhase: Int = 0,
        isB2BDay2: Bool = false,
        isRecoveryWeek: Bool = false,
        verticalGainEnvironment: VerticalGainEnvironment = .mountain,
        intervalFocus: IntervalFocus? = nil,
        isRoadRace: Bool = false,
        plannedDurationSeconds: TimeInterval = 0,
        isHotRaceForecast: Bool = false,
        isHotSessionForecast: Bool = false,
        restingHR: Int? = nil,
        maxHR: Int? = nil,
        biologicalSex: BiologicalSex? = nil
    ) -> String? {
        let recoveryPrefix = isRecoveryWeek
            ? "Recovery week, so keep everything easy. Your body adapts when you rest. "
            : ""

        let focusPrefix = focusAdvice(type: type, focus: intervalFocus, isRoadRace: isRoadRace, weekInPhase: weekInPhase)

        let baseAdvice: String?
        switch type {
        case .rest:
            baseAdvice = restAdvice(phase: phase, isRecoveryWeek: isRecoveryWeek)
        case .recovery:
            baseAdvice = recoveryRunAdvice(phase: phase)
        case .crossTraining:
            baseAdvice = "Keep it light and fun. Different movements help your body recover while staying active."
        case .backToBack:
            baseAdvice = b2bAdvice(phase: phase, isDay2: isB2BDay2)
        case .longRun:
            baseAdvice = longRunAdvice(phase: phase, intensity: intensity, weekInPhase: weekInPhase)
        case .tempo:
            baseAdvice = tempoAdvice(phase: phase)
        case .intervals:
            baseAdvice = intervalAdvice(phase: phase, weekInPhase: weekInPhase)
        case .verticalGain:
            baseAdvice = verticalGainAdvice(phase: phase, intensity: intensity, environment: verticalGainEnvironment)
        case .strengthConditioning:
            baseAdvice = nil
        case .race:
            baseAdvice = "Race day. Trust your training, execute your pacing plan, and stay fueled."
        }

        guard let advice = baseAdvice else { return nil }
        var result = isRecoveryWeek && type != .rest ? recoveryPrefix + advice : advice
        if let prefix = focusPrefix {
            result = prefix + " " + result
        }
        // #14: append Karvonen HR range when both resting + max HR are
        // known. Skips rest days (no meaningful zone), strength /
        // cross-training (HR too variable to prescribe a range), and —
        // critically for ultras — sessions ≥ 2 hours, where cardiac
        // drift makes HR zones misleading: at hour 5 your HR climbs
        // 10-15 bpm at the same effort. Athletes who chase HR through
        // a long ultra slow inappropriately. RPE / effort cues stay
        // truer over long durations.
        let isLongSession = plannedDurationSeconds >= 2 * 3600
        if type != .rest, type != .strengthConditioning, type != .crossTraining,
           !isLongSession,
           let restingHR, let maxHR, restingHR > 0, maxHR > restingHR {
            let range = PaceCalculator.heartRateRange(
                for: intensity, restingHR: restingHR, maxHR: maxHR
            )
            result += " Target HR: \(range.min)-\(range.max) bpm."
        } else if type != .rest, type != .strengthConditioning, type != .crossTraining,
                  isLongSession {
            // Pure RPE guidance for long sessions — HR drifts, effort doesn't.
            let effortLabel: String
            switch intensity {
            case .easy:      effortLabel = "Stay at conversational effort throughout — if HR climbs but the effort feels the same, trust the effort."
            case .moderate:  effortLabel = "Moderate effort the whole way. Past 2 hours your HR will drift up at the same effort — that's normal, ignore it."
            case .hard:      effortLabel = "Hard effort but sustainable. Pace by feel, not by HR — long-effort cardiac drift will lie to you."
            case .maxEffort: effortLabel = "Race effort. RPE-driven — HR drift makes the bpm number meaningless after the first hour."
            }
            result += " " + effortLabel
        }
        // #15: append research-backed sex-specific note when relevant.
        if let biologicalSex,
           let note = SexSpecificAdviceHelper.note(
               biologicalSex: biologicalSex,
               sessionType: type,
               phase: phase,
               isRecoveryWeek: isRecoveryWeek,
               isRaceWeek: phase == .race
           ) {
            result += " " + note
        }
        // Heat-acclimation advice. Surfaces in peak / race-week / long-
        // run sessions when the forecasted race-day weather is hot
        // (≥22°C or ≥65% humidity). Coach principle: 10-14 days of
        // heat exposure pre-race is enough to confer most of the
        // adaptation; pure plan structure doesn't change, but the
        // athlete sees the cue at the right moment.
        if isHotRaceForecast,
           type != .rest, type != .strengthConditioning,
           let heatNote = heatAcclimationNote(
                phase: phase, type: type, weekInPhase: weekInPhase
           ) {
            result += " " + heatNote
        }
        // Session-day weather flag — today's forecast is hot enough that
        // a hard session is unsafe / unproductive. Surface a swap cue
        // instead of just a "drink more water" warning. Athlete makes
        // the call (skip / swap with tomorrow's easy / move to early
        // morning). One short sentence — no over-stuffed card.
        if isHotSessionForecast,
           type == .intervals || type == .tempo || type == .verticalGain {
            result += " Today's forecast is hot — consider swapping with tomorrow's easy day or moving this to dawn."
        }
        // Mental cue. Short — one sentence. Surfaces only on the few
        // sessions where it actually matters: peak-phase race-effort
        // efforts, race-week prep, and the race itself. Skipped on
        // routine easy / recovery / strength so the card stays focused.
        if let mentalCue = mentalCue(for: type, phase: phase, weekInPhase: weekInPhase) {
            result += " " + mentalCue
        }
        return result
    }

    /// Single-sentence mental cue. Matches research-backed sport-
    /// psychology themes — visualisation, controlled self-talk,
    /// pace-by-feel — without bloating the card. Returns nil when the
    /// session doesn't warrant one.
    private static func mentalCue(
        for type: SessionType,
        phase: TrainingPhase,
        weekInPhase: Int
    ) -> String? {
        switch (phase, type) {
        case (.race, .race):
            return "Trust your training. The race goes to who's calmest, not who's fittest."
        case (.taper, .longRun), (.taper, .backToBack):
            return "Visualise the race tonight: start, mid-race, finish. Three minutes is enough."
        case (.taper, .intervals), (.taper, .tempo):
            return "Sharpening, not building. Stay relaxed — speed comes from looseness."
        case (.peak, .longRun), (.peak, .backToBack):
            return "If a bad patch hits, walk 60 seconds, fuel, then run. Patches pass."
        case (.peak, .race):
            return "Race-pace work. Pace by feel for the first half, push when you'd want to fade."
        case (.build, .intervals), (.build, .tempo):
            return "Hard, not desperate. Hold form when it stings."
        default:
            return nil
        }
    }

    /// Heat-acclimation cue — surfaced on peak / taper sessions when the
    /// race-day forecast is hot. Returns nil for sessions where the cue
    /// would be misleading (recovery weeks, base phase, etc.).
    private static func heatAcclimationNote(
        phase: TrainingPhase,
        type: SessionType,
        weekInPhase: Int
    ) -> String? {
        switch (phase, type) {
        case (.peak, .longRun), (.peak, .backToBack):
            return "Race-day forecast is hot — start your 10-14 day heat-acclimation block by training in the warmest part of the day, layered, or in a sauna 20-30 min post-run."
        case (.taper, .longRun), (.taper, .backToBack), (.taper, .race):
            return "Stay heat-adapted: short heat exposures (warm bath, sauna 15 min) every 2-3 days through taper. Don't add new training stress."
        case (.peak, .race):
            return "Race day will be hot. Pre-cool if possible, sip-and-eat early before thirst/hunger spikes, and drop pace targets 5-10% in heat."
        default:
            return nil
        }
    }

    // MARK: - Interval Focus Advice

    private static func focusAdvice(
        type: SessionType,
        focus: IntervalFocus?,
        isRoadRace: Bool,
        weekInPhase: Int
    ) -> String? {
        guard type == .intervals || type == .verticalGain else { return nil }
        guard let focus else { return nil }

        if isRoadRace && type == .verticalGain {
            return "One hill session every few weeks keeps your legs strong and makes your flat running more efficient. Trust the process."
        }

        switch focus {
        case .uphill where type == .verticalGain:
            return "Your climbing is a weapon. We are going to keep sharpening it."
        case .speed where type == .intervals:
            return "Speed is what closes races. Today we work on yours."
        case .mixed:
            if weekInPhase % 2 == 0 && type == .verticalGain {
                return "Your climbing is a weapon. We are going to keep sharpening it."
            } else if weekInPhase % 2 != 0 && type == .intervals {
                return "Speed is what closes races. Today we work on yours."
            }
            return nil
        default:
            return nil
        }
    }

    // MARK: - Rest

    private static func restAdvice(phase: TrainingPhase, isRecoveryWeek: Bool) -> String {
        if isRecoveryWeek {
            return "Your body is absorbing the training right now. Focus on sleeping well, eating well, and maybe some gentle stretching."
        }
        switch phase {
        case .taper:
            return "Trust your training. Take a walk, foam roll, relax. You've done the work."
        default:
            return "Foam roll, walk, stretch. A good night of sleep tonight will do more for your fitness than any run."
        }
    }

    // MARK: - Recovery Run

    private static func recoveryRunAdvice(phase: TrainingPhase) -> String {
        switch phase {
        case .taper:
            return "Just a short easy jog to keep the legs moving. If anything feels off, cut it short. You're almost there."
        default:
            return "When in doubt, go slower. This run is about blood flow, not building fitness. You should be able to hold a full conversation."
        }
    }

    // MARK: - Long Run (Phase-Aware)

    private static func longRunAdvice(phase: TrainingPhase, intensity: Intensity, weekInPhase: Int) -> String {
        switch phase {
        case .base:
            if weekInPhase < 3 {
                return "Pure aerobic building today. Walk all the uphills, keep it easy, focus on time on feet. This is where your foundation gets built."
            }
            return "Keep the effort easy and steady. Practice walking technical sections. You're building your engine right now."
        case .build:
            if weekInPhase < 4 {
                return "Start easy, then include some sections at race effort in the second half. Practice eating and drinking on the move."
            }
            return "Include some blocks at your goal race pace. Eat and drink on schedule. Treat this like a mini dress rehearsal."
        case .peak:
            return "Race simulation day. Start easy, then settle into race effort. Wear your race gear and practice your full fueling plan."
        case .taper:
            return "Keep it short and easy. Your fitness is locked in. Just enjoy the trail."
        default:
            return longRunByIntensity(intensity)
        }
    }

    private static func longRunByIntensity(_ intensity: Intensity) -> String {
        switch intensity {
        case .easy:
            return "Focus on time on feet, not pace. Walk the uphills if you need to."
        case .moderate:
            return "Find a steady rhythm and lock in. Good time to practice your race nutrition too."
        case .hard, .maxEffort:
            return "Push the pace but stay controlled. Practice fueling at effort."
        }
    }

    // MARK: - B2B (Phase-Aware)

    private static func b2bAdvice(phase: TrainingPhase, isDay2: Bool) -> String {
        if isDay2 {
            switch phase {
            case .peak:
                return "Day 2 on tired legs. Start very easy to warm up, then build to race effort. This is what the second half of your ultra will feel like."
            default:
                return "Day 2 on yesterday's fatigue. Start very easy for the first hour, then gradually build. If you bonk, slow down and eat. Just like you would on race day."
            }
        }
        switch phase {
        case .peak:
            return "Day 1 at steady effort. Fuel well because tomorrow you run on today's tired legs. Try to include terrain that matches your race."
        default:
            return "Day 1 to build fatigue for tomorrow. Easy to moderate effort. Fuel consistently so your body has something to work with tomorrow."
        }
    }

    // MARK: - Intervals (Phase-Aware)

    private static func intervalAdvice(phase: TrainingPhase, weekInPhase: Int = 0) -> String {
        switch phase {
        case .base:
            return "Hill repeats at a controlled effort today. Focus on smooth form and consistent pacing. Full recovery between each rep."
        case .build:
            if weekInPhase < 6 {
                return "Push hard on the climbs but stay in control. If your form starts breaking down, stop the set early. Quality over quantity."
            }
            return "Sustained effort on rolling terrain today. Stay controlled and eat on schedule. This type of work builds real ultra fitness."
        case .peak:
            return "Short and sharp today. You're already fit, this is just fine-tuning. Maximum quality, not maximum volume."
        case .taper:
            return "Just enough to keep your legs sharp. Controlled effort, don't chase times. Save the fire for race day."
        default:
            return "Full recovery between reps matters more than speed. If your form breaks down, call it."
        }
    }

    // MARK: - Tempo (Phase-Aware)

    private static func tempoAdvice(phase: TrainingPhase) -> String {
        switch phase {
        case .base:
            return "Find a rhythm you can hold for the whole session. You should be able to speak in short phrases. This builds your threshold."
        case .build:
            return "Sustained effort at race pace. Push the tempo but stay in control. This is how you develop race-day pacing."
        case .peak:
            return "Lock into your goal race effort. Practice holding form when fatigue starts to build."
        default:
            return "Find a rhythm you can sustain. If you can't finish a sentence, back off a touch."
        }
    }

    // MARK: - Vertical Gain (Phase + Environment Aware)

    private static func verticalGainAdvice(
        phase: TrainingPhase,
        intensity: Intensity,
        environment: VerticalGainEnvironment
    ) -> String {
        let phaseAdvice: String
        switch phase {
        case .base:
            phaseAdvice = "Build your climbing confidence. Short steps, hands on thighs, rhythmic breathing. Good power hiking technique matters more than speed."
        case .build:
            phaseAdvice = "Push the effort on the climbs today. This is where ultra trail races are won and lost."
        case .peak:
            phaseAdvice = "Race-specific climbing. Try to mimic the kind of gradients you'll face on race day."
        case .taper:
            phaseAdvice = "Light climbing to keep the mountain legs without the fatigue. Short efforts, easy intensity."
        default:
            phaseAdvice = "Consistent effort on the uphills today. Focus on your climbing rhythm."
        }

        let envTip: String
        switch environment {
        case .mountain:
            envTip = " Find trails with sustained elevation."
        case .hill:
            envTip = " Find a hill with a few minutes of sustained climbing."
        case .treadmill:
            envTip = treadmillTip(intensity: intensity)
        case .mixed:
            envTip = " Mix outdoor and treadmill climbing."
        }

        return phaseAdvice + envTip
    }

    private static func treadmillTip(intensity: Intensity) -> String {
        switch intensity {
        case .easy, .moderate:
            return " Set the incline to 8-10% and walk at a brisk pace."
        case .hard:
            return " Set the incline to 10-15% at a brisk pace."
        case .maxEffort:
            return " Crank the incline to 15%+ and go hard."
        }
    }
}
