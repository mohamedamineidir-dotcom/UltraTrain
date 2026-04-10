import Foundation

/// Calculates weekly training volumes for road race plans.
///
/// Key differences from trail VolumeCalculator:
/// - No B2B weeks (road runners don't do back-to-back long runs).
/// - No vertical gain sessions (elevation = 0).
/// - Volume progression capped at 10% per week (Pfitzinger, Daniels).
/// - Peak volume scaled by distance and experience.
/// - Session duration splits: long run ~25-30%, quality ~30%, easy fills remainder.
enum RoadVolumeCalculator {

    /// Calculates weekly volumes for a road training plan.
    /// Returns the same `WeekVolume` type as the trail VolumeCalculator.
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
        let peakKm = discipline.peakWeeklyKm(experience: experience)

        // Starting volume: athlete's current volume or a conservative default
        let startKm = max(athlete.weeklyVolumeKm, 15)

        // Average pace for duration estimation
        let avgPaceSecPerKm: Double = switch experience {
        case .beginner:     370
        case .intermediate: 330
        case .advanced:     295
        case .elite:        265
        }

        var volumes: [VolumeCalculator.WeekVolume] = []
        var taperWeekCounter = 0

        for (index, skeleton) in skeletons.enumerated() {
            let weekInTaper = skeleton.phase == .taper ? taperWeekCounter : 0

            // Progressive volume ramp: quadratic from start to peak
            let peakWeekIndex = Int(Double(totalWeeks) * 0.78)
            let progress: Double
            if index <= peakWeekIndex {
                let t = Double(index) / max(Double(peakWeekIndex), 1.0)
                progress = t * (2.0 - t)
            } else {
                progress = 1.0
            }

            var weeklyKm = startKm + (peakKm - startKm) * progress

            // Week-over-week cap: max 10% increase (Pfitzinger safety rule)
            if index > 0, let prevKm = volumes.last?.targetVolumeKm, prevKm > 0 {
                let maxAllowed = prevKm * 1.10
                weeklyKm = min(weeklyKm, maxAllowed)
            }

            // Recovery week: 70% of target (Daniels: reduce volume, maintain frequency)
            if skeleton.isRecoveryWeek {
                weeklyKm *= 0.70
            }

            // Taper reduction
            if skeleton.phase == .taper {
                let fraction = taperProfile.volumeFraction(forWeekInTaper: weekInTaper)
                weeklyKm *= fraction
                taperWeekCounter += 1
            }

            let totalDuration = weeklyKm * avgPaceSecPerKm

            // Long run: ~28% of weekly volume
            let longRunDuration = RoadLongRunCalculator.longRunDuration(
                weekIndex: index,
                totalWeeks: totalWeeks,
                phase: skeleton.phase,
                experience: experience,
                raceDistanceKm: raceDistanceKm,
                currentWeeklyVolumeKm: weeklyKm,
                isRecoveryWeek: skeleton.isRecoveryWeek
            )

            // Quality sessions: ~30% of remaining volume
            let remainingAfterLR = max(totalDuration - longRunDuration, 0)
            let qualityFraction: Double = skeleton.phase == .base ? 0.25 : 0.35
            let qualityDuration = remainingAfterLR * qualityFraction
            let easyDuration = remainingAfterLR - qualityDuration

            // Split quality into interval + tempo
            let intervalDuration = qualityDuration * 0.55
            let tempoDuration = qualityDuration * 0.45

            // Split easy into 2 runs
            let easy1 = easyDuration * 0.55
            let easy2 = easyDuration * 0.45

            volumes.append(VolumeCalculator.WeekVolume(
                weekNumber: skeleton.weekNumber,
                targetVolumeKm: round(weeklyKm * 10) / 10,
                targetElevationGainM: 0,  // Road: no elevation
                targetDurationSeconds: round(totalDuration),
                targetLongRunDurationSeconds: round(longRunDuration),
                isB2BWeek: false,  // Road: never B2B
                b2bDay1Seconds: 0,
                b2bDay2Seconds: 0,
                baseSessionDurations: VolumeCalculator.BaseSessionDurations(
                    easyRun1Seconds: round(easy1),
                    easyRun2Seconds: round(easy2),
                    intervalSeconds: round(intervalDuration),
                    vgSeconds: round(tempoDuration)  // Repurposed: tempo for road plans
                ),
                weekNumberInTaper: weekInTaper,
                taperProfile: skeleton.phase == .taper ? taperProfile : nil
            ))
        }

        return volumes
    }
}
