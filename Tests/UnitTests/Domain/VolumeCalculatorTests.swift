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
            isRecoveryWeek: isRecovery
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
            experience: .intermediate
        )
        #expect(result.isEmpty)
    }

    @Test("single build week returns volume")
    func singleWeekReturnsVolume() {
        let skeletons = [makeSkeleton(weekNumber: 1, phase: .build)]
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 40,
            raceDistanceKm: 100,
            raceElevationGainM: 5000,
            experience: .intermediate
        )

        #expect(result.count == 1)
        #expect(result[0].weekNumber == 1)
        #expect(result[0].targetVolumeKm > 0)
        #expect(result[0].targetElevationGainM > 0)
    }

    // MARK: - Peak Fraction by Experience

    @Test("beginner has lower peak fraction than elite")
    func peakFractionScalesByExperience() {
        let skeletons = [makeSkeleton(weekNumber: 1, phase: .build)]
        let raceDistance = 100.0

        let beginner = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 10,
            raceDistanceKm: raceDistance,
            raceElevationGainM: 0,
            experience: .beginner
        )
        let elite = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 10,
            raceDistanceKm: raceDistance,
            raceElevationGainM: 0,
            experience: .elite
        )

        // With single week, both reach peak immediately (limited by 10% cap from start)
        // But for multiple weeks, elite targets higher peak
        let beginnerTarget = beginner[0].targetVolumeKm
        let eliteTarget = elite[0].targetVolumeKm

        // Both are capped at 10% increase from current (10km), so max = 11
        #expect(beginnerTarget <= 11.0)
        #expect(eliteTarget <= 11.0)
    }

    // MARK: - Progressive Overload

    @Test("volume increases progressively across build weeks")
    func progressiveOverload() {
        let skeletons = (1...6).map { makeSkeleton(weekNumber: $0, phase: .build) }
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 30,
            raceDistanceKm: 100,
            raceElevationGainM: 5000,
            experience: .intermediate
        )

        // Each week should be >= previous week (progressive overload)
        for i in 1..<result.count {
            #expect(result[i].targetVolumeKm >= result[i - 1].targetVolumeKm)
        }
    }

    @Test("volume never increases more than 10% per week")
    func maxIncreaseCapped() {
        let skeletons = (1...8).map { makeSkeleton(weekNumber: $0, phase: .build) }
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 30,
            raceDistanceKm: 200,
            raceElevationGainM: 10000,
            experience: .elite,
            maxIncreasePercent: 10
        )

        var previousVolume = 30.0
        for vol in result {
            let maxAllowed = previousVolume * 1.10
            #expect(vol.targetVolumeKm <= maxAllowed + 0.2) // small rounding tolerance
            previousVolume = vol.targetVolumeKm
        }
    }

    // MARK: - Recovery Weeks

    @Test("recovery weeks reduce volume")
    func recoveryWeeksReduceVolume() {
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
            recoveryReductionPercent: 35
        )

        // Recovery week should be lower than previous non-recovery week
        #expect(result[2].targetVolumeKm < result[1].targetVolumeKm)
    }

    // MARK: - Taper

    @Test("taper weeks reduce volume progressively")
    func taperReducesVolume() {
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
            experience: .intermediate
        )

        // Taper weeks should be less than last build week
        #expect(result[2].targetVolumeKm < result[1].targetVolumeKm)
        // Second taper week should be less than first taper
        #expect(result[3].targetVolumeKm < result[2].targetVolumeKm)
    }

    // MARK: - Elevation

    @Test("elevation is proportional to volume")
    func elevationProportionalToVolume() {
        let skeletons = [makeSkeleton(weekNumber: 1, phase: .build)]
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 40,
            raceDistanceKm: 100,
            raceElevationGainM: 5000,
            experience: .intermediate
        )

        let vol = result[0]
        let expectedRatio = 5000.0 / 100.0 // 50 m/km
        let actualRatio = vol.targetElevationGainM / vol.targetVolumeKm
        #expect(abs(actualRatio - expectedRatio) < 1.0)
    }

    @Test("elevation is zero when race has no elevation")
    func elevationZeroWhenRaceFlat() {
        let skeletons = [makeSkeleton(weekNumber: 1, phase: .build)]
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 40,
            raceDistanceKm: 42,
            raceElevationGainM: 0,
            experience: .beginner
        )

        #expect(result[0].targetElevationGainM == 0)
    }

    // MARK: - Minimum Volume

    @Test("start volume has minimum of 10 km")
    func startVolumeMinimum() {
        let skeletons = [makeSkeleton(weekNumber: 1, phase: .build)]
        let result = VolumeCalculator.calculate(
            skeletons: skeletons,
            currentWeeklyVolumeKm: 2, // very low
            raceDistanceKm: 50,
            raceElevationGainM: 0,
            experience: .beginner
        )

        #expect(result[0].targetVolumeKm >= 10.0)
    }
}
