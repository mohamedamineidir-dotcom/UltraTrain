import Foundation

/// Calculates weekly training volumes for road race plans.
///
/// Research basis:
/// - **Pfitzinger (Advanced Marathoning)**: Peak weekly volume:
///   - 18/55 plan: 55 mi (88 km) peak
///   - 18/70 plan: 70 mi (112 km) peak
///   - 18/85 plan: 85 mi (137 km) peak
///   Progression: start at ~70% of peak, build 5-8% per week with
///   recovery weeks every 3rd-4th week at 70-75% of load week.
///
/// - **Daniels (Running Formula)**: Weekly volume should not increase
///   more than 1 hour OR 10% (whichever is less). Long run ≤ 25% of
///   weekly volume or 2.5h, whichever is less.
///
/// - **Canova**: Marathon runners need peak volume 2-3× their current
///   volume but reached gradually over 12-20 weeks. The quality of
///   volume matters more than raw numbers.
///
/// - **Hanson (Marathon Method)**: Even "beginner" marathoners should
///   peak around 57 mi (92 km). Cumulative fatigue is the training
///   stimulus, not individual session volume.
enum RoadVolumeCalculator {

    static func calculate(
        skeletons: [WeekSkeletonBuilder.WeekSkeleton],
        athlete: Athlete,
        raceDistanceKm: Double,
        taperProfile: TaperProfile
    ) -> [VolumeCalculator.WeekVolume] {
        guard !skeletons.isEmpty else { return [] }

        let discipline = RoadRaceDiscipline.from(distanceKm: raceDistanceKm)
        let experience = athlete.experienceLevel
        let totalWeeks = skeletons.count

        // Starting volume: athlete's actual weekly volume with experience-based floor.
        // Advanced runners preparing for a marathon are NOT starting at 15km/week.
        let floor = startingVolumeFloor(discipline: discipline, experience: experience)
        let startKm = max(athlete.weeklyVolumeKm, floor)

        // Peak volume: based on discipline, experience, and runs per week.
        // Scaled DOWN slightly for fewer runs/week (can't hit 110km on 3 runs/week).
        let basePeak = discipline.peakWeeklyKm(experience: experience)
        let runsScale: Double = switch athlete.preferredRunsPerWeek {
        case ...3:  0.65
        case 4:     0.78
        case 5:     0.90
        case 6:     0.97
        default:    1.00
        }
        let peakKm = basePeak * runsScale

        // Ensure peak is meaningfully higher than start (at least 40% increase)
        let effectivePeak = max(peakKm, startKm * 1.4)

        // Pace for duration conversion
        let avgPaceSecPerKm: Double = switch experience {
        case .beginner:     370
        case .intermediate: 330
        case .advanced:     295
        case .elite:        265
        }

        // Build the volume curve: linear with recovery dips
        // Pfitzinger pattern: steady 5-8% build, recovery every 3rd/4th week
        var volumes: [VolumeCalculator.WeekVolume] = []
        var taperWeekCounter = 0

        // Number of build weeks (before taper)
        let taperStart = totalWeeks - taperProfile.totalTaperWeeks
        let buildWeeks = max(taperStart, 1)

        for (index, skeleton) in skeletons.enumerated() {
            let weekInTaper = skeleton.phase == .taper ? taperWeekCounter : 0

            var weeklyKm: Double

            if index < buildWeeks {
                // Linear progression from start to peak over the build period
                // Pfitzinger: reach peak 2-3 weeks before taper starts
                let peakReachWeek = max(buildWeeks - 2, 1)
                let t = min(Double(index) / Double(peakReachWeek), 1.0)
                weeklyKm = startKm + (effectivePeak - startKm) * t

                // Week-over-week cap: max 8% increase (Pfitzinger)
                if let prevKm = volumes.last?.targetVolumeKm, prevKm > 0 {
                    weeklyKm = min(weeklyKm, prevKm * 1.08)
                }

                // Recovery weeks: reduce to 75% of current load (not of peak)
                if skeleton.isRecoveryWeek {
                    weeklyKm *= 0.75
                }
            } else {
                // Taper phase: apply taper profile fractions
                let fraction = taperProfile.volumeFraction(forWeekInTaper: weekInTaper)
                weeklyKm = effectivePeak * fraction
                taperWeekCounter += 1
            }

            let totalDuration = weeklyKm * avgPaceSecPerKm

            // Long run calculation
            let longRunDuration = RoadLongRunCalculator.longRunDuration(
                weekIndex: index,
                totalWeeks: totalWeeks,
                phase: skeleton.phase,
                experience: experience,
                raceDistanceKm: raceDistanceKm,
                currentWeeklyVolumeKm: weeklyKm,
                isRecoveryWeek: skeleton.isRecoveryWeek
            )

            // Distribute remaining time across sessions
            let remainingAfterLR = max(totalDuration - longRunDuration, 0)
            let qualityFraction: Double
            switch skeleton.phase {
            case .base:  qualityFraction = 0.25
            case .build: qualityFraction = 0.35
            case .peak:  qualityFraction = 0.40
            case .taper: qualityFraction = 0.30
            default:     qualityFraction = 0.25
            }
            let qualityDuration = remainingAfterLR * qualityFraction
            let easyDuration = remainingAfterLR - qualityDuration

            let intervalDuration = qualityDuration * 0.55
            let tempoDuration = qualityDuration * 0.45
            let easy1 = easyDuration * 0.55
            let easy2 = easyDuration * 0.45

            volumes.append(VolumeCalculator.WeekVolume(
                weekNumber: skeleton.weekNumber,
                targetVolumeKm: round(weeklyKm * 10) / 10,
                targetElevationGainM: 0,
                targetDurationSeconds: round(totalDuration),
                targetLongRunDurationSeconds: round(longRunDuration),
                isB2BWeek: false,
                b2bDay1Seconds: 0,
                b2bDay2Seconds: 0,
                baseSessionDurations: VolumeCalculator.BaseSessionDurations(
                    easyRun1Seconds: round(easy1),
                    easyRun2Seconds: round(easy2),
                    intervalSeconds: round(intervalDuration),
                    vgSeconds: round(tempoDuration) // Repurposed: tempo for road
                ),
                weekNumberInTaper: weekInTaper,
                taperProfile: skeleton.phase == .taper ? taperProfile : nil
            ))
        }

        return volumes
    }

    // MARK: - Starting Volume Floor

    /// Minimum starting volume by discipline and experience.
    ///
    /// An advanced runner preparing for a marathon is not starting from 15km/week.
    /// These floors represent the minimum reasonable base for plan generation.
    ///
    /// Pfitzinger: lowest plan starts runners at ~42-48 km/week.
    /// Hanson: starts at ~45 km/week for "beginner" marathoners.
    private static func startingVolumeFloor(
        discipline: RoadRaceDiscipline,
        experience: ExperienceLevel
    ) -> Double {
        switch (discipline, experience) {
        case (.road10K, .beginner):       20
        case (.road10K, .intermediate):   25
        case (.road10K, .advanced):       35
        case (.road10K, .elite):          45
        case (.roadHalf, .beginner):      25
        case (.roadHalf, .intermediate):  35
        case (.roadHalf, .advanced):      45
        case (.roadHalf, .elite):         55
        case (.roadMarathon, .beginner):  30
        case (.roadMarathon, .intermediate): 40
        case (.roadMarathon, .advanced):  50
        case (.roadMarathon, .elite):     65
        }
    }
}
