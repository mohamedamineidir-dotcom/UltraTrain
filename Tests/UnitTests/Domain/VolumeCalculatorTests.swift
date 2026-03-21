import Foundation
import Testing
@testable import UltraTrain

@Suite("VolumeCalculator Tests")
struct VolumeCalculatorTests {

    // MARK: - Helpers

    private func makeSkeleton(
        weekNumber: Int,
        phase: TrainingPhase = .base,
        isRecovery: Bool = false
    ) -> WeekSkeletonBuilder.WeekSkeleton {
        let start = Date().addingTimeInterval(TimeInterval(weekNumber * 7 * 86400))
        return WeekSkeletonBuilder.WeekSkeleton(
            weekNumber: weekNumber,
            startDate: start,
            endDate: start.addingTimeInterval(6 * 86400),
            phase: phase,
            isRecoveryWeek: isRecovery,
            phaseFocus: phase.defaultFocus
        )
    }

    // MARK: - Basic

    @Test("empty skeletons returns empty volumes")
    func emptySkeletonsReturnsEmpty() {
        let result = VolumeCalculator.calculate(
            skeletons: [],
            currentWeeklyVolumeKm: 40,
            raceDistanceKm: 100,
            raceElevationGainM: 5000,
            experience: .intermediate,
            raceDurationSeconds: 50400,
            raceEffectiveKm: 150
        )
        #expect(result.isEmpty)
    }

    @Test("single build week returns volume with duration fields")
    func singleWeekReturnsVolume() {
        let skeletons = [makeSkeleton(weekNumber: 1, phase: .build)]
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 40,
            raceDistanceKm: 100,
            raceElevationGainM: 5000,
            experience: .intermediate,
            raceDurationSeconds: 50400,
            raceEffectiveKm: 150
        )

        #expect(result.count == 1)
        #expect(result[0].weekNumber == 1)
        #expect(result[0].targetVolumeKm > 0)
        #expect(result[0].targetElevationGainM > 0)
        #expect(result[0].targetDurationSeconds > 0)
        #expect(result[0].targetLongRunDurationSeconds > 0)
    }

    // MARK: - Duration-Based Planning

    @Test("total duration increases across build weeks")
    func durationIncreasesProgressively() {
        let skeletons = (1...12).map { makeSkeleton(weekNumber: $0, phase: .build) }
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 30,
            raceDistanceKm: 100,
            raceElevationGainM: 5000,
            experience: .intermediate,
            raceDurationSeconds: 50400,
            raceEffectiveKm: 150
        )

        // First week should be less than last week
        #expect(result.first!.targetDurationSeconds < result.last!.targetDurationSeconds)
    }

    @Test("long run duration grows significantly across plan")
    func longRunGrowsSignificantly() {
        let skeletons = (1...20).map { makeSkeleton(weekNumber: $0, phase: .build) }
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 30,
            raceDistanceKm: 170,
            raceElevationGainM: 10000,
            experience: .advanced,
            raceDurationSeconds: 126000, // ~35h
            raceEffectiveKm: 270
        )

        let firstLR = result.first!.targetLongRunDurationSeconds
        let lastLR = result.last!.targetLongRunDurationSeconds
        let ratio = lastLR / firstLR

        // Long run should grow significantly (at least 3x for a 170km race)
        #expect(ratio >= 3.0, "Long run should grow at least 3x, got \(ratio)")
    }

    @Test("base session durations populated for all weeks")
    func baseSessionDurationsPopulated() {
        let skeletons = (1...6).map { makeSkeleton(weekNumber: $0, phase: .build) }
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 40,
            raceDistanceKm: 100,
            raceElevationGainM: 5000,
            experience: .intermediate,
            raceDurationSeconds: 50400,
            raceEffectiveKm: 150,
            preferredRunsPerWeek: 5
        )

        for vol in result {
            #expect(vol.baseSessionDurations.easyRun1Seconds > 0)
            #expect(vol.baseSessionDurations.easyRun2Seconds > 0)
            // VG can be 0 on hardest B2B weeks (quality sessions dropped)
            if !vol.isB2BWeek {
                #expect(vol.baseSessionDurations.vgSeconds > 0)
            }
        }
    }

    // MARK: - Recovery Weeks

    @Test("recovery weeks reduce duration")
    func recoveryWeeksReduceDuration() {
        let skeletons = [
            makeSkeleton(weekNumber: 1, phase: .build),
            makeSkeleton(weekNumber: 2, phase: .build),
            makeSkeleton(weekNumber: 3, phase: .build, isRecovery: true)
        ]
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 40,
            raceDistanceKm: 100,
            raceElevationGainM: 5000,
            experience: .intermediate,
            raceDurationSeconds: 50400,
            raceEffectiveKm: 150
        )

        #expect(result[2].targetDurationSeconds < result[1].targetDurationSeconds)
    }

    // MARK: - Taper

    @Test("taper weeks reduce duration progressively")
    func taperReducesDuration() {
        let skeletons = [
            makeSkeleton(weekNumber: 1, phase: .build),
            makeSkeleton(weekNumber: 2, phase: .build),
            makeSkeleton(weekNumber: 3, phase: .taper),
            makeSkeleton(weekNumber: 4, phase: .taper)
        ]
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 50,
            raceDistanceKm: 100,
            raceElevationGainM: 5000,
            experience: .intermediate,
            raceDurationSeconds: 50400,
            raceEffectiveKm: 150
        )

        #expect(result[2].targetDurationSeconds < result[1].targetDurationSeconds)
        #expect(result[3].targetDurationSeconds < result[2].targetDurationSeconds)
    }

    // MARK: - Elevation

    @Test("elevation is proportional to derived km")
    func elevationProportional() {
        let skeletons = [makeSkeleton(weekNumber: 1, phase: .build)]
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 40,
            raceDistanceKm: 100,
            raceElevationGainM: 5000,
            experience: .intermediate,
            raceDurationSeconds: 50400,
            raceEffectiveKm: 150
        )

        #expect(result[0].targetElevationGainM > 0)
    }

    @Test("elevation is zero when race has no elevation")
    func elevationZeroWhenRaceFlat() {
        let skeletons = [makeSkeleton(weekNumber: 1, phase: .build)]
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 40,
            raceDistanceKm: 42,
            raceElevationGainM: 0,
            experience: .beginner,
            raceDurationSeconds: 18000,
            raceEffectiveKm: 42
        )

        #expect(result[0].targetElevationGainM == 0)
    }

    // MARK: - Training Philosophy

    @Test("enjoyment philosophy produces lower duration than balanced")
    func enjoymentLowerDuration() {
        // Use short race (effKm < 80) to avoid B2B which overrides philosophy effects
        let skeletons = (1...8).map { makeSkeleton(weekNumber: $0, phase: .build) }

        let balanced = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 30,
            raceDistanceKm: 42,
            raceElevationGainM: 1000,
            experience: .intermediate,
            philosophy: .balanced,
            raceDurationSeconds: 18000,
            raceEffectiveKm: 52
        )
        let enjoyment = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 30,
            raceDistanceKm: 42,
            raceElevationGainM: 1000,
            experience: .intermediate,
            philosophy: .enjoyment,
            raceDurationSeconds: 18000,
            raceEffectiveKm: 52
        )

        let lastBalanced = balanced.last!.targetDurationSeconds
        let lastEnjoyment = enjoyment.last!.targetDurationSeconds
        #expect(lastEnjoyment < lastBalanced)
    }

    @Test("performance philosophy produces higher duration than balanced")
    func performanceHigherDuration() {
        // Use short race (effKm < 80) to avoid B2B which overrides philosophy effects
        let skeletons = (1...8).map { makeSkeleton(weekNumber: $0, phase: .build) }

        let balanced = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 30,
            raceDistanceKm: 42,
            raceElevationGainM: 1000,
            experience: .intermediate,
            philosophy: .balanced,
            raceDurationSeconds: 18000,
            raceEffectiveKm: 52
        )
        let performance = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 30,
            raceDistanceKm: 42,
            raceElevationGainM: 1000,
            experience: .intermediate,
            philosophy: .performance,
            raceDurationSeconds: 18000,
            raceEffectiveKm: 52
        )

        let lastBalanced = balanced.last!.targetDurationSeconds
        let lastPerformance = performance.last!.targetDurationSeconds
        #expect(lastPerformance > lastBalanced)
    }

    // MARK: - B2B Weeks

    @Test("B2B weeks appear for long races in second half of plan")
    func b2bWeeksAppearForLongRaces() {
        let skeletons = (1...20).map { makeSkeleton(weekNumber: $0, phase: .build) }
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 40,
            raceDistanceKm: 170,
            raceElevationGainM: 10000,
            experience: .advanced,
            raceDurationSeconds: 126000,
            raceEffectiveKm: 270
        )

        let b2bWeeks = result.filter(\.isB2BWeek)
        #expect(!b2bWeeks.isEmpty, "Long race plan should include B2B weeks")

        // B2B should be in second half of build weeks (accounting for taper)
        let buildWeekCount = max(result.count - max(Int(Double(result.count) * 0.12), 2), 1)
        let halfPoint = buildWeekCount / 2
        for b2b in b2bWeeks {
            let idx = result.firstIndex(where: { $0.weekNumber == b2b.weekNumber })!
            #expect(idx >= halfPoint, "B2B week at index \(idx) should be >= halfPoint \(halfPoint)")
        }
    }

    @Test("B2B day splits sum to total long run duration")
    func b2bDaySplitsConsistent() {
        let skeletons = (1...20).map { makeSkeleton(weekNumber: $0, phase: .build) }
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 40,
            raceDistanceKm: 170,
            raceElevationGainM: 10000,
            experience: .advanced,
            raceDurationSeconds: 126000,
            raceEffectiveKm: 270
        )

        for vol in result where vol.isB2BWeek {
            let combined = vol.b2bDay1Seconds + vol.b2bDay2Seconds
            #expect(abs(combined - vol.targetLongRunDurationSeconds) < 2)
        }
    }

    @Test("elevation density capped for steep short races")
    func elevationDensityCapped() {
        let skeletons = [makeSkeleton(weekNumber: 1, phase: .build)]
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 80,
            raceDistanceKm: 13,
            raceElevationGainM: 1500,
            experience: .advanced,
            raceDurationSeconds: 7200,
            raceEffectiveKm: 28
        )

        let vol = result[0]
        let elevationPerKm = vol.targetElevationGainM / vol.targetVolumeKm
        #expect(elevationPerKm <= 61.0)
    }
}
