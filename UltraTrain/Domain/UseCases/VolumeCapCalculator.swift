import Foundation

/// Computes dynamic volume caps and week-1 anchoring based on athlete/race profile.
/// All percentages are personalized ranges, not fixed values.
enum VolumeCapCalculator {

    /// Dynamic weekly volume increase cap (15-20% trail/ultra, 10-13% road).
    /// Scales with experience, race distance, philosophy, injury profile.
    static func weeklyVolumeCap(
        experience: ExperienceLevel,
        raceType: RaceType = .trail,
        raceEffectiveKm: Double = 50,
        philosophy: TrainingPhilosophy = .balanced,
        painFrequency: PainFrequency = .never
    ) -> Double {
        if raceType == .road {
            // Road: 10-13% range
            var cap = 10.0
            if experience == .advanced || experience == .elite { cap += 1.0 }
            if philosophy == .performance { cap += 1.0 }
            if raceEffectiveKm > 42 { cap += 1.0 } // marathon+
            return min(cap, 13.0)
        }

        // Trail/Ultra: 15-20% range
        var cap = 15.0
        // Experience bonus: 0-2%
        switch experience {
        case .beginner: break
        case .intermediate: cap += 1.0
        case .advanced: cap += 1.5
        case .elite: cap += 2.0
        }
        // Distance bonus: 0-2% (longer ultras can absorb more low-intensity volume)
        if raceEffectiveKm > 100 { cap += 1.0 }
        if raceEffectiveKm > 160 { cap += 1.0 }
        // Philosophy bonus: 0-1%
        if philosophy == .performance { cap += 1.0 }
        // Injury penalty
        if painFrequency == .often { cap -= 2.0 }
        else if painFrequency == .sometimes { cap -= 1.0 }

        return min(max(cap, 12.0), 20.0)
    }

    /// Dynamic B2B peak fraction of race duration (58-68%).
    /// Scales with experience, philosophy, race distance/profile.
    static func b2bPeakFraction(
        experience: ExperienceLevel,
        philosophy: TrainingPhilosophy = .balanced,
        raceEffectiveKm: Double = 100
    ) -> Double {
        var fraction = 0.58
        // Experience: +0-4%
        switch experience {
        case .beginner: break // no B2B for beginners
        case .intermediate: fraction += 0.02
        case .advanced: fraction += 0.04
        case .elite: fraction += 0.05
        }
        // Philosophy: +0-3%
        switch philosophy {
        case .enjoyment: break
        case .balanced: fraction += 0.01
        case .performance: fraction += 0.03
        }
        // Race distance: +0-3% for mountain ultras
        if raceEffectiveKm > 120 { fraction += 0.01 }
        if raceEffectiveKm > 160 { fraction += 0.01 }

        return min(max(fraction, 0.58), 0.68)
    }

    /// Dynamic B2B weekly volume fraction (70-76%).
    /// How much of total weekly volume the B2B weekend represents.
    static func b2bWeeklyFraction(
        experience: ExperienceLevel,
        raceEffectiveKm: Double = 100,
        philosophy: TrainingPhilosophy = .balanced
    ) -> Double {
        var fraction = 0.70
        // Experience: +0-2%
        if experience == .advanced { fraction += 0.01 }
        if experience == .elite { fraction += 0.02 }
        // Race distance: +0-2%
        if raceEffectiveKm > 120 { fraction += 0.01 }
        if raceEffectiveKm > 160 { fraction += 0.01 }
        // Philosophy: +0-2%
        if philosophy == .performance { fraction += 0.02 }

        return min(max(fraction, 0.70), 0.76)
    }

    /// Dynamic week-1 volume multiplier (1.8-2.5x current volume).
    /// Based on preferredRunsPerWeek (more sessions = safer to ramp faster).
    static func week1VolumeMultiplier(preferredRunsPerWeek: Int) -> Double {
        switch preferredRunsPerWeek {
        case ...3: return 1.8
        case 4:    return 2.0
        case 5:    return 2.2
        case 6:    return 2.3
        default:   return 2.5
        }
    }

    /// Minimum week-1 volume baseline by experience (seconds).
    static func week1MinimumBaseline(experience: ExperienceLevel) -> TimeInterval {
        switch experience {
        case .beginner:     return 120 * 60  // 2h minimum
        case .intermediate: return 180 * 60  // 3h minimum
        case .advanced:     return 240 * 60  // 4h minimum
        case .elite:        return 300 * 60  // 5h minimum
        }
    }

    /// Recovery week cycle by experience (trail/ultra default).
    static func recoveryCycle(for experience: ExperienceLevel) -> Int {
        switch experience {
        case .beginner: return 2     // 2:1 (2 hard + 1 recovery)
        case .intermediate: return 3 // 3:1
        case .advanced: return 3     // 3:1
        case .elite: return 3        // 3:1
        }
    }

    /// Road-specific recovery cycle — marathon runners need longer blocks.
    /// Pfitzinger: uses 3-week cycles in 18-week plans (3 load + natural deload).
    /// For road, advanced+ athletes can sustain 4:1 for marathon prep.
    static func roadRecoveryCycle(for experience: ExperienceLevel, discipline: RoadRaceDiscipline) -> Int {
        switch (experience, discipline) {
        case (.beginner, _):                     return 2 // 2:1
        case (.intermediate, .roadMarathon):     return 3 // 3:1
        case (.intermediate, _):                 return 3 // 3:1
        case (.advanced, .roadMarathon):         return 4 // 4:1 (longer blocks for marathon)
        case (.advanced, _):                     return 3 // 3:1
        case (.elite, .roadMarathon):            return 4 // 4:1
        case (.elite, _):                        return 3 // 3:1
        }
    }

    /// Build phase fraction adaptive to plan length.
    static func buildPhaseFraction(totalWeeks: Int) -> Double {
        if totalWeeks < 12 { return 0.22 }
        if totalWeeks <= 20 { return 0.18 }
        return 0.16
    }
}
