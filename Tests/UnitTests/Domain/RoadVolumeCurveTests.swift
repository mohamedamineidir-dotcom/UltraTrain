import Foundation
import Testing
@testable import UltraTrain

/// Characterizes the road weekly-volume CURVE shape, locking in the
/// periodisation properties that make the plan read like a real coach's
/// plan (Campus Coach / Pfitzinger): a clean 3:1 sawtooth, deep recovery
/// troughs, progressive block-to-block overload, a single peak before the
/// taper, and a decreasing taper into race week.
@Suite("Road volume curve shape")
struct RoadVolumeCurveTests {

    private func athlete(
        experience: ExperienceLevel,
        weeklyVolumeKm: Double,
        longestRunKm: Double,
        runsPerWeek: Int
    ) -> Athlete {
        var a = Athlete(
            id: UUID(),
            firstName: "Curve", lastName: "Test",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -32, to: .now)!,
            weightKg: 66, heightCm: 178, restingHeartRate: 46, maxHeartRate: 188,
            experienceLevel: experience,
            weeklyVolumeKm: weeklyVolumeKm,
            longestRunKm: longestRunKm,
            preferredUnit: .metric
        )
        a.preferredRunsPerWeek = runsPerWeek
        return a
    }

    /// Generates the weekly volumes + skeletons the same way the road
    /// generator does, for a given distance / experience / weeks-out.
    private func curve(
        distanceKm: Double,
        experience: ExperienceLevel,
        weeksOut: Int,
        weeklyVolumeKm: Double,
        longestRunKm: Double,
        runsPerWeek: Int
    ) -> [(vol: VolumeCalculator.WeekVolume, skeleton: WeekSkeletonBuilder.WeekSkeleton)] {
        let a = athlete(experience: experience, weeklyVolumeKm: weeklyVolumeKm,
                        longestRunKm: longestRunKm, runsPerWeek: runsPerWeek)
        let taper = TaperProfile.forRoadRace(distanceKm: distanceKm)
        let phases = RoadPhaseDistributor.distribute(
            totalWeeks: weeksOut, experience: experience,
            raceDistanceKm: distanceKm, taperProfile: taper
        )
        let discipline = RoadRaceDiscipline.from(distanceKm: distanceKm)
        let cycle = VolumeCapCalculator.roadRecoveryCycle(for: experience, discipline: discipline)
        let raceDate = Calendar.current.date(byAdding: .weekOfYear, value: weeksOut - 1, to: .now)!
        let skeletons = WeekSkeletonBuilder.build(
            raceDate: raceDate, phases: phases, recoveryCycle: cycle, postRaceRecoveryWeeks: 0
        )
        let volumes = RoadVolumeCalculator.calculate(
            skeletons: skeletons, athlete: a, raceDistanceKm: distanceKm,
            taperProfile: taper, raceGoal: .targetTime(9000), preferredRunsPerWeek: runsPerWeek
        )
        return Array(zip(volumes, skeletons))
    }

    // MARK: - Marathon (the Campus Coach reference case)

    @Test("Lyon advanced marathon: week 1 anchors to the declared base")
    func week1Anchors() {
        let c = curve(distanceKm: 42.195, experience: .advanced, weeksOut: 21,
                      weeklyVolumeKm: 79, longestRunKm: 28, runsPerWeek: 6)
        // Week 1 should land near declared base × 0.85 (here ≈ 67 km), not a
        // tier-generic ~79 km. Within 12% of target.
        let target = 79.0 * 0.85
        #expect(abs(c[0].vol.targetVolumeKm - target) < target * 0.12)
    }

    @Test("Recovery weeks cut ~20-35% below the preceding load week")
    func recoveryTroughsAreDeep() {
        let c = curve(distanceKm: 42.195, experience: .advanced, weeksOut: 21,
                      weeklyVolumeKm: 79, longestRunKm: 28, runsPerWeek: 6)
        for i in 1..<c.count where c[i].skeleton.isRecoveryWeek {
            let prev = c[i - 1].vol.targetVolumeKm
            let here = c[i].vol.targetVolumeKm
            // Deload must be clearly visible (>=15% cut) but not a shutdown.
            #expect(here <= prev * 0.85, "Recovery week \(i + 1) only cut to \(here)/\(prev)")
            #expect(here >= prev * 0.55, "Recovery week \(i + 1) over-cut to \(here)/\(prev)")
        }
    }

    @Test("Recovery weeks themselves trend upward (progressive overload)")
    func recoveryWeeksEscalate() {
        let c = curve(distanceKm: 42.195, experience: .advanced, weeksOut: 21,
                      weeklyVolumeKm: 79, longestRunKm: 28, runsPerWeek: 6)
        let recoveryKm = c.filter { $0.skeleton.isRecoveryWeek }.map { $0.vol.targetVolumeKm }
        #expect(recoveryKm.count >= 3)
        for i in 1..<recoveryKm.count {
            #expect(recoveryKm[i] > recoveryKm[i - 1],
                    "Recovery troughs should rise over the plan: \(recoveryKm)")
        }
    }

    @Test("Volume escalates from base into a single peak before taper")
    func escalatesToPeak() {
        let c = curve(distanceKm: 42.195, experience: .advanced, weeksOut: 21,
                      weeklyVolumeKm: 79, longestRunKm: 28, runsPerWeek: 6)
        let firstLoad = c.first { !$0.skeleton.isRecoveryWeek }!.vol.targetVolumeKm
        let nonTaperPeak = c.filter { $0.skeleton.phase != .taper }
            .map { $0.vol.targetVolumeKm }.max()!
        // The peak is well above the opening load week (real overload), and
        // stays in a sane advanced-marathon band (not 140 km elite territory).
        #expect(nonTaperPeak > firstLoad * 1.4)
        #expect(nonTaperPeak >= 100 && nonTaperPeak <= 125)
    }

    @Test("Taper decreases monotonically into race week")
    func taperDecreases() {
        let c = curve(distanceKm: 42.195, experience: .advanced, weeksOut: 21,
                      weeklyVolumeKm: 79, longestRunKm: 28, runsPerWeek: 6)
        let taper = c.filter { $0.skeleton.phase == .taper }.map { $0.vol.targetVolumeKm }
        #expect(taper.count == 3)
        for i in 1..<taper.count {
            #expect(taper[i] < taper[i - 1], "Taper should descend: \(taper)")
        }
        let peak = c.map { $0.vol.targetVolumeKm }.max()!
        #expect(taper.last! < peak)
    }

    // MARK: - Generality across distances

    @Test("10K and half marathon also anchor week 1 and show a real deload")
    func shorterDistancesShareTheShape() {
        for (dist, base, lr) in [(10.0, 50.0, 16.0), (21.1, 60.0, 22.0)] {
            let c = curve(distanceKm: dist, experience: .advanced, weeksOut: 16,
                          weeklyVolumeKm: base, longestRunKm: lr, runsPerWeek: 5)
            let target = base * 0.85
            #expect(abs(c[0].vol.targetVolumeKm - target) < target * 0.15,
                    "\(dist)km week 1 \(c[0].vol.targetVolumeKm) off target \(target)")
            // At least one recovery week with a clearly visible cut.
            let hasDeepDeload = (1..<c.count).contains { i in
                c[i].skeleton.isRecoveryWeek
                    && c[i].vol.targetVolumeKm <= c[i - 1].vol.targetVolumeKm * 0.85
            }
            #expect(hasDeepDeload, "\(dist)km plan has no visible deload week")
        }
    }
}
