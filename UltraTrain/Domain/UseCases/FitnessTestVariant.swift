import Foundation

/// Mid-prep fitness test variants. The variant chosen depends on the
/// race profile and the athlete's available terrain. Each variant
/// produces a calibration signal we can convert into training paces
/// (or threshold zones for trail).
///
/// Sources:
/// - VMA flat 6-min test: Léger-Boucher; standard French/European school
///   (Lacrouts, Cottin, Aubert, Pons). VMA km/h = distance_m / 100.
/// - 5K time trial: Daniels VDOT (Daniels' *Running Formula* Ch. 5),
///   Pfitzinger tune-up race (*Adv Marathoning* Ch. 5).
/// - 30-min sustained uphill: House & Johnston anaerobic-threshold (AnT)
///   test (*Training for the Uphill Athlete* Ch. 5), the canonical
///   mountain-athlete calibration.
/// - Repeated long-uphill / repeated medium-uphill: Koop's pragmatic
///   substitute when athlete lacks a 30-min sustained climb (*TEU* Ch. 7).
/// - Treadmill incline: House & Johnston Ch. 5, primary recommendation
///   for flat-region athletes prepping for mountain races.
enum FitnessTestVariant: String, Sendable, Codable {

    /// 6-min all-out flat run. Athlete records distance covered.
    /// VMA (km/h) = distance_m / 100. Calibrates aerobic ceiling →
    /// derives all training paces via the Daniels / Lacrouts ratios
    /// already used by RoadPaceCalculator.
    case vmaFlat6Min

    /// 5 km time trial all-out (track or flat road). Records finish
    /// time. Converts to equivalent VMA via the 5K-pace formula
    /// already used in the codebase. Standard for HM / marathon prep.
    case fiveKTT

    /// 30-min sustained uphill TT at threshold effort. Records average
    /// HR + perceived effort. Calibrates threshold zones for trail.
    /// Requires a 25+ min sustained climb (only mountain athletes).
    case uphillSustained30Min

    /// 4 × 6-8 min uphill repeats at threshold effort, jog-down
    /// recovery. Substitute when sustained 25+ min climb is unavailable
    /// but 6-8 min hills exist. Calibrates threshold via average HR.
    case uphillRepeats4x8

    /// 5-6 × 4-min uphill repeats at threshold effort. Substitute for
    /// athletes with only 4-6 min hills.
    case uphillRepeats6x4

    /// 30 min on a treadmill at 8-12% incline at threshold effort.
    /// House & Johnston's primary fallback for flat-region athletes
    /// prepping for mountain races.
    case treadmillIncline30Min

    var displayName: String {
        switch self {
        case .vmaFlat6Min:           "VMA 6-min flat test"
        case .fiveKTT:               "5K time trial"
        case .uphillSustained30Min:  "30-min sustained uphill test"
        case .uphillRepeats4x8:      "4 × 6-8 min uphill repeats"
        case .uphillRepeats6x4:      "5-6 × 4 min uphill repeats"
        case .treadmillIncline30Min: "Treadmill 30-min incline test"
        }
    }

    /// Descriptive copy shown on the session card. Kept structured so
    /// athletes know exactly what to do without coaching context.
    var description: String {
        switch self {
        case .vmaFlat6Min:
            return """
            VMA 6-min flat test (Léger-Boucher).

            Warm up 15-20 min easy + 4-6 strides.
            Run 6 minutes all-out on a flat surface (track ideal). Cover as much distance as possible.
            Cool down 10 min easy.

            Record the distance you covered. Your VMA (km/h) = distance in meters ÷ 100.
            (e.g., 1500m → VMA 15 km/h)

            The result re-anchors all your training paces, easy, threshold, intervals, race pace.
            """
        case .fiveKTT:
            return """
            5K time trial.

            Warm up 15-20 min easy + 4-6 strides.
            Run 5 km as hard as you sustainably can. Track or flat road, even pacing, don't go out hard.
            Cool down 10-15 min easy.

            Record your finish time. The result re-anchors your half-marathon / marathon pace targets via Daniels VDOT.
            """
        case .uphillSustained30Min:
            return """
            30-min sustained uphill test (House & Johnston).

            Warm up 15-20 min easy on flat.
            Run 30 minutes uphill at threshold effort, the hardest sustainable pace where you can still breathe rhythmically (about 80-85% max HR).
            Cool down jog down + 10 min easy.

            Record average HR + total elevation gain.
            Calibrates your threshold zones for the rest of the plan.
            """
        case .uphillRepeats4x8:
            return """
            4 × 6-8 min uphill repeats.

            Warm up 15-20 min easy.
            4 reps: 6-8 min uphill at threshold effort, then jog down for recovery (~3 min between reps).
            Cool down 10 min easy.

            Record average HR over the work intervals + average pace.
            Substitute for the 30-min sustained test when you don't have a long enough climb. Same threshold signal.
            """
        case .uphillRepeats6x4:
            return """
            5-6 × 4 min uphill repeats.

            Warm up 15-20 min easy.
            5-6 reps: 4 min uphill at threshold effort, jog down (~2 min between reps).
            Cool down 10 min easy.

            Record average HR over the work intervals + average pace.
            Threshold calibration for athletes with shorter hills.
            """
        case .treadmillIncline30Min:
            return """
            30-min treadmill incline test.

            Warm up 10 min on flat (or 0% incline).
            Set incline to 8-12% (steeper if you can sustain). Run 30 min at threshold effort, hardest sustainable pace where you can still breathe rhythmically.
            Cool down 5-10 min flat.

            Record average HR + speed used.
            Calibrates your threshold zones, House & Johnston's primary recommendation for flat-region athletes.
            """
        }
    }

    /// Coach advice, short, framed as "this is a test, not a workout."
    var coachAdvice: String {
        switch self {
        case .vmaFlat6Min:
            return "📊 VMA test, not a workout. Go all-out over 6 min, no pacing games. Track or flat road. Distance covered ÷ 100 = your VMA. Log it on validate so we can re-anchor your paces."
        case .fiveKTT:
            return "📊 5K time trial. Test, not workout. Even pacing, first 1K should not be the fastest. Log your finish time so we can re-anchor your paces."
        case .uphillSustained30Min, .uphillRepeats4x8, .uphillRepeats6x4:
            return "📊 Threshold test, hardest sustainable effort, NOT all-out. You should be able to speak in 3-4 word fragments, not full sentences. Log your average HR (and pace if you have it) on validate."
        case .treadmillIncline30Min:
            return "📊 Treadmill threshold test. Pick an incline you can sustain for 30 min, start conservative, you can always push the speed up after 10 min if it feels too easy. Log average HR + speed."
        }
    }

    /// What the result-entry UI should ask for. The recalibrator
    /// converts the response into a VMA-equivalent value (or threshold
    /// zone delta for uphill / treadmill variants).
    var resultPrompt: ResultPrompt {
        switch self {
        case .vmaFlat6Min:           .distanceMeters
        case .fiveKTT:               .timeSeconds(distanceKm: 5)
        case .uphillSustained30Min,
             .uphillRepeats4x8,
             .uphillRepeats6x4,
             .treadmillIncline30Min:
            .heartRateAndPerceivedEffort
        }
    }

    /// Whether this variant produces a recalibrable VMA signal. Trail
    /// uphill / treadmill tests calibrate threshold zones (HR-based)
    /// for now we surface the result but don't auto-modify the plan
    /// for those because the codebase's pace prescriptions don't use
    /// HR zones for trail.
    var producesPaceRecalibration: Bool {
        switch self {
        case .vmaFlat6Min, .fiveKTT: true
        case .uphillSustained30Min,
             .uphillRepeats4x8,
             .uphillRepeats6x4,
             .treadmillIncline30Min: false
        }
    }

    static let intervalFocusLabel: String = "Fitness Test"

    /// Encodes the variant into the session's `intervalFocus` string so
    /// the validation view can recover it without extra plumbing.
    /// Format: "Fitness Test:<rawValue>" (e.g., "Fitness Test:vmaFlat6Min").
    var intervalFocusEncoded: String {
        "\(Self.intervalFocusLabel):\(rawValue)"
    }

    /// Recovers the variant from an encoded `intervalFocus` string.
    /// Returns nil for non-fitness-test focus strings or unknown raw
    /// values.
    static func fromIntervalFocus(_ focus: String?) -> FitnessTestVariant? {
        guard let focus,
              focus.hasPrefix("\(intervalFocusLabel):") else { return nil }
        let raw = String(focus.dropFirst("\(intervalFocusLabel):".count))
        return FitnessTestVariant(rawValue: raw)
    }

    /// True for any string that begins with the fitness-test prefix.
    /// Handy when only presence matters, not the variant itself.
    static func isFitnessTestFocus(_ focus: String?) -> Bool {
        focus?.hasPrefix("\(intervalFocusLabel):") == true
            || focus == intervalFocusLabel
    }

    enum ResultPrompt: Equatable, Sendable {
        case distanceMeters
        case timeSeconds(distanceKm: Double)
        case heartRateAndPerceivedEffort
    }
}
