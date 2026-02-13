import Foundation

enum VolumeCalculator {

    struct WeekVolume: Equatable, Sendable {
        let weekNumber: Int
        let targetVolumeKm: Double
        let targetElevationGainM: Double
    }

    static func calculate(
        skeletons: [WeekSkeletonBuilder.WeekSkeleton],
        currentWeeklyVolumeKm: Double,
        raceDistanceKm: Double,
        raceElevationGainM: Double,
        experience: ExperienceLevel,
        maxIncreasePercent: Double = AppConfiguration.Training.maxWeeklyVolumeIncreasePercent,
        recoveryReductionPercent: Double = AppConfiguration.Training.recoveryWeekVolumeReductionPercent
    ) -> [WeekVolume] {
        guard !skeletons.isEmpty else { return [] }

        let peakFraction = peakFraction(for: experience)
        let peakVolume = raceDistanceKm * peakFraction
        let startVolume = max(currentWeeklyVolumeKm, 10.0)

        // Find the last non-taper, non-recovery week index for peak target
        let buildWeeks = skeletons.filter { $0.phase != .taper && !$0.isRecoveryWeek }
        let buildWeekCount = buildWeeks.count

        // Calculate progressive volumes
        var volumes: [WeekVolume] = []
        var previousNonRecoveryVolume = startVolume
        var buildWeekIndex = 0

        for skeleton in skeletons {
            let volume: Double
            let elevation: Double

            if skeleton.isRecoveryWeek {
                volume = previousNonRecoveryVolume * (1.0 - recoveryReductionPercent / 100.0)
                elevation = elevationForVolume(volume, raceDistanceKm: raceDistanceKm, raceElevationGainM: raceElevationGainM)
            } else if skeleton.phase == .taper {
                let taperWeeks = skeletons.filter { $0.phase == .taper }
                let taperIndex = taperWeeks.firstIndex(where: { $0.weekNumber == skeleton.weekNumber }) ?? 0
                let taperTotal = taperWeeks.count
                // Progressive reduction: from ~80% to ~50% of peak
                let taperFraction = 0.8 - (Double(taperIndex) / Double(max(taperTotal - 1, 1))) * 0.3
                volume = previousNonRecoveryVolume * taperFraction
                elevation = elevationForVolume(volume, raceDistanceKm: raceDistanceKm, raceElevationGainM: raceElevationGainM)
            } else {
                // Progressive overload toward peak
                let targetAtStep: Double
                if buildWeekCount > 1 {
                    let progress = Double(buildWeekIndex) / Double(buildWeekCount - 1)
                    targetAtStep = startVolume + (peakVolume - startVolume) * progress
                } else {
                    targetAtStep = peakVolume
                }

                // Cap at 10% increase from last non-recovery week
                let maxAllowed = previousNonRecoveryVolume * (1.0 + maxIncreasePercent / 100.0)
                volume = min(targetAtStep, maxAllowed)

                previousNonRecoveryVolume = volume
                buildWeekIndex += 1
                elevation = elevationForVolume(volume, raceDistanceKm: raceDistanceKm, raceElevationGainM: raceElevationGainM)
            }

            volumes.append(WeekVolume(
                weekNumber: skeleton.weekNumber,
                targetVolumeKm: (volume * 10).rounded() / 10,
                targetElevationGainM: (elevation * 10).rounded() / 10
            ))
        }
        return volumes
    }

    private static func peakFraction(for experience: ExperienceLevel) -> Double {
        switch experience {
        case .beginner:     0.40
        case .intermediate: 0.50
        case .advanced:     0.60
        case .elite:        0.70
        }
    }

    private static func elevationForVolume(_ volume: Double, raceDistanceKm: Double, raceElevationGainM: Double) -> Double {
        guard raceDistanceKm > 0 else { return 0 }
        let elevationPerKm = raceElevationGainM / raceDistanceKm
        return volume * elevationPerKm
    }
}
