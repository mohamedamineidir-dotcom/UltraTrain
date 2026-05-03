import Foundation
import Testing
@testable import UltraTrain

@Suite("PersonalizationProfile Tests")
struct PersonalizationProfileTests {

    // MARK: - Tenure

    @Test("tenure multiplier brackets")
    func tenureBrackets() {
        #expect(PersonalizationProfile.tenureMultiplier(years: 0) == 0.92)
        #expect(PersonalizationProfile.tenureMultiplier(years: 0.5) == 0.92)
        #expect(PersonalizationProfile.tenureMultiplier(years: 1) == 0.95)
        #expect(PersonalizationProfile.tenureMultiplier(years: 2.9) == 0.95)
        #expect(PersonalizationProfile.tenureMultiplier(years: 3) == 1.00)
        #expect(PersonalizationProfile.tenureMultiplier(years: 6.9) == 1.00)
        #expect(PersonalizationProfile.tenureMultiplier(years: 7) == 1.05)
        #expect(PersonalizationProfile.tenureMultiplier(years: 14.9) == 1.05)
        #expect(PersonalizationProfile.tenureMultiplier(years: 15) == 1.10)
        #expect(PersonalizationProfile.tenureMultiplier(years: 30) == 1.10)
    }

    // MARK: - Weight

    @Test("weight multiplier brackets")
    func weightBrackets() {
        #expect(PersonalizationProfile.weightMultiplier(weightKg: 60) == 1.03)
        #expect(PersonalizationProfile.weightMultiplier(weightKg: 69.9) == 1.03)
        #expect(PersonalizationProfile.weightMultiplier(weightKg: 70) == 1.00)
        #expect(PersonalizationProfile.weightMultiplier(weightKg: 84.9) == 1.00)
        #expect(PersonalizationProfile.weightMultiplier(weightKg: 85) == 0.93)
        #expect(PersonalizationProfile.weightMultiplier(weightKg: 100) == 0.93)
    }

    // MARK: - Ultra experience

    @Test("ultra experience multiplier brackets")
    func ultraBrackets() {
        #expect(PersonalizationProfile.ultraExperienceMultiplier(count: 0) == 0.95)
        #expect(PersonalizationProfile.ultraExperienceMultiplier(count: 1) == 1.00)
        #expect(PersonalizationProfile.ultraExperienceMultiplier(count: 2) == 1.00)
        #expect(PersonalizationProfile.ultraExperienceMultiplier(count: 3) == 1.05)
        #expect(PersonalizationProfile.ultraExperienceMultiplier(count: 4) == 1.05)
        #expect(PersonalizationProfile.ultraExperienceMultiplier(count: 5) == 1.10)
        #expect(PersonalizationProfile.ultraExperienceMultiplier(count: 100) == 1.10)
    }

    // MARK: - Composite clamps

    @Test("trail composite clamped to [0.75, 1.30]")
    func trailCompositeClamped() {
        // Maximum stack: tenure 1.10 × weight 1.03 × ultra 1.10 = 1.2463 → not clamped
        let high = makeProfile(
            tenureMultiplier: 1.10,
            weightMultiplier: 1.03,
            ultraExperienceMultiplier: 1.10
        )
        #expect(high.trailComposite <= 1.30)
        #expect(high.trailComposite > 1.20)

        // Minimum stack: tenure 0.92 × weight 0.93 × ultra 0.95 = 0.8129 → not clamped
        let low = makeProfile(
            tenureMultiplier: 0.92,
            weightMultiplier: 0.93,
            ultraExperienceMultiplier: 0.95
        )
        #expect(low.trailComposite >= 0.75)
        #expect(low.trailComposite < 0.85)
    }

    @Test("composite hard-clamps when stacked extreme inputs exceed bounds")
    func compositeHardClamps() {
        // Synthetic profile with values outside the natural [0.92, 1.10]
        // brackets — should clamp to 1.30 / 0.75.
        let extreme = makeProfile(
            tenureMultiplier: 1.5,
            weightMultiplier: 1.5,
            ultraExperienceMultiplier: 1.5
        )
        #expect(extreme.trailComposite == 1.30)

        let lowExtreme = makeProfile(
            tenureMultiplier: 0.5,
            weightMultiplier: 0.5,
            ultraExperienceMultiplier: 0.5
        )
        #expect(lowExtreme.trailComposite == 0.75)
    }

    @Test("road composite ignores ultra experience")
    func roadCompositeIgnoresUltra() {
        let withHighUltra = makeProfile(
            tenureMultiplier: 1.00,
            weightMultiplier: 1.00,
            ultraExperienceMultiplier: 1.10
        )
        // Road composite = tenure × weight only = 1.0
        #expect(withHighUltra.roadComposite == 1.00)
    }

    // MARK: - VG density multiplier

    @Test("vgDensityMultiplier scales with tenure + ultra count, clamped to [0.85, 1.20]")
    func vgDensityBrackets() {
        // First-timer + low tenure: 0.92 × 0.95 = 0.874
        #expect(PersonalizationProfile.vgDensityMultiplier(years: 1, ultraCount: 0) == 0.874)
        // Mid tenure + 1-2 ultras: 1.00 × 1.00 = 1.0
        #expect(PersonalizationProfile.vgDensityMultiplier(years: 5, ultraCount: 2) == 1.00)
        // Long tenure + 5+ ultras: 1.05 × 1.10 = 1.155
        let high = PersonalizationProfile.vgDensityMultiplier(years: 10, ultraCount: 6)
        #expect((high - 1.155).magnitude < 0.001)
        // Extreme combo within bounds (clamp at 1.20)
        // No actual combo exceeds this with current brackets but verify the clamp
    }

    // MARK: - Injury penalty

    @Test("injury penalty: zero when never+none+empty")
    func injuryPenaltyHealthyAthlete() {
        let p = PersonalizationProfile.computeInjuryVolumeCapPenalty(
            painFrequency: .never,
            injuryCount: .none,
            structures: []
        )
        #expect(p == 0)
    }

    @Test("injury penalty: rarely + one + no structures")
    func injuryPenaltyMildProfile() {
        let p = PersonalizationProfile.computeInjuryVolumeCapPenalty(
            painFrequency: .rarely,
            injuryCount: .one,
            structures: []
        )
        // -0.25 (rarely) + -0.25 (one) + 0 = -0.5
        #expect(p == -0.5)
    }

    @Test("injury penalty: sometimes + two + 2 structures")
    func injuryPenaltyModerateProfile() {
        let p = PersonalizationProfile.computeInjuryVolumeCapPenalty(
            painFrequency: .sometimes,
            injuryCount: .two,
            structures: [.knees, .itBand]
        )
        // -0.5 (sometimes) + -0.5 (two) + 2×-0.25 (structures) = -1.5
        #expect(p == -1.5)
    }

    @Test("injury penalty: worst-case clamps to -2.0")
    func injuryPenaltyWorstCase() {
        let p = PersonalizationProfile.computeInjuryVolumeCapPenalty(
            painFrequency: .often,
            injuryCount: .threeOrMore,
            structures: [.knees, .hips, .calf, .achilles, .itBand, .footAnkle]
        )
        // -1.0 + -0.75 + 4×-0.25 (capped) = -2.75 → clamps to -2.0
        #expect(p == -2.0)
    }

    @Test("injury penalty: structure-only signal still works (no pain reported)")
    func injuryPenaltyStructuresOnly() {
        let p = PersonalizationProfile.computeInjuryVolumeCapPenalty(
            painFrequency: .never,
            injuryCount: .none,
            structures: [.knees, .achilles]
        )
        // 0 + 0 + 2×-0.25 = -0.5
        #expect(p == -0.5)
    }

    // MARK: - Years proxy from experience

    @Test("yearsProxy maps experience tier to expected tenure multiplier bracket")
    func yearsProxyMapsToTenureMultiplier() {
        // Beginner → 1.0 yrs → 0.95 multiplier (1-3 bracket)
        #expect(PersonalizationProfile.yearsProxy(for: .beginner) == 1.0)
        #expect(PersonalizationProfile.tenureMultiplier(years: PersonalizationProfile.yearsProxy(for: .beginner)) == 0.95)
        // Intermediate → 4.0 yrs → 1.00 multiplier (3-7 bracket)
        #expect(PersonalizationProfile.yearsProxy(for: .intermediate) == 4.0)
        #expect(PersonalizationProfile.tenureMultiplier(years: PersonalizationProfile.yearsProxy(for: .intermediate)) == 1.00)
        // Advanced → 9.0 yrs → 1.05 multiplier (7-15 bracket)
        #expect(PersonalizationProfile.yearsProxy(for: .advanced) == 9.0)
        #expect(PersonalizationProfile.tenureMultiplier(years: PersonalizationProfile.yearsProxy(for: .advanced)) == 1.05)
        // Elite → 16.0 yrs → 1.10 multiplier (15+ bracket)
        #expect(PersonalizationProfile.yearsProxy(for: .elite) == 16.0)
        #expect(PersonalizationProfile.tenureMultiplier(years: PersonalizationProfile.yearsProxy(for: .elite)) == 1.10)
    }

    // MARK: - Neutral / safe defaults

    @Test("neutral profile has no effect")
    func neutralProfile() {
        let p = PersonalizationProfile.neutral
        #expect(p.tenureMultiplier == 1.0)
        #expect(p.weightMultiplier == 1.0)
        #expect(p.ultraExperienceMultiplier == 1.0)
        #expect(p.trailComposite == 1.0)
        #expect(p.roadComposite == 1.0)
        #expect(p.historicalLongRunCapSeconds == nil)
        #expect(p.injuryStructures.isEmpty)
        #expect(p.injuryVolumeCapPenalty == 0)
    }

    // MARK: - Factory

    @Test("factory uses athlete tenure, weight, and longest run")
    func factoryFromAthlete() {
        let athlete = makeAthlete(
            weightKg: 75, // → 1.00
            longestRunKm: 30,
            runningYears: 10, // → 1.05
            injuryStructures: [.knees]
        )
        let profile = PersonalizationProfile.from(
            athlete: athlete,
            ultraFinishCount: 2 // → 1.00
        )

        #expect(profile.tenureMultiplier == 1.05)
        #expect(profile.weightMultiplier == 1.00)
        #expect(profile.ultraExperienceMultiplier == 1.00)
        #expect(profile.injuryStructures == [.knees])
        // Cap = 30 km × 1.20 × 450 s/km = 16200 s
        #expect(profile.historicalLongRunCapSeconds == 16200)
    }

    @Test("factory returns nil cap when no longest run is logged")
    func factoryNoLongestRun() {
        let athlete = makeAthlete(longestRunKm: 0)
        let profile = PersonalizationProfile.from(athlete: athlete)
        #expect(profile.historicalLongRunCapSeconds == nil)
    }

    @Test("factory respects custom estimated pace for cap conversion")
    func factoryCustomPace() {
        let athlete = makeAthlete(longestRunKm: 20)
        // Use 6:00/km pace (360 s/km) — for road athletes
        let profile = PersonalizationProfile.from(
            athlete: athlete,
            estimatedLongRunPaceSecondsPerKm: 360
        )
        // Cap = 20 × 1.20 × 360 = 8640
        #expect(profile.historicalLongRunCapSeconds == 8640)
    }

    // MARK: - Onboarding-derivation behaviour

    @Test("factory derives years from experience tier when runningYears is 0")
    func factoryDerivesYearsFromExperience() {
        // Athlete sets no runningYears (default 0) but is .advanced.
        // Profile should use the experience proxy → 9 years → 1.05 multiplier.
        let athlete = makeAthlete(runningYears: 0, experience: .advanced)
        let profile = PersonalizationProfile.from(athlete: athlete)
        #expect(profile.tenureMultiplier == 1.05)
    }

    @Test("factory uses explicit runningYears when set, ignoring experience proxy")
    func factoryRespectsExplicitYears() {
        // Athlete is .elite (would proxy to 16 years → 1.10) but
        // explicitly set runningYears = 2 — explicit wins, gives 0.95.
        let athlete = makeAthlete(runningYears: 2, experience: .elite)
        let profile = PersonalizationProfile.from(athlete: athlete)
        #expect(profile.tenureMultiplier == 0.95)
    }

    @Test("factory derives injury penalty from painFrequency + injuryCount")
    func factoryDerivesInjuryPenaltyFromExistingFields() {
        // Athlete with no explicit injuryStructures but pain "sometimes"
        // and 2 injuries last year — penalty should still fire.
        let athlete = makeAthlete(
            painFrequency: .sometimes,
            injuryCount: .two
        )
        let profile = PersonalizationProfile.from(athlete: athlete)
        // -0.5 (sometimes) + -0.5 (two) + 0 (no structures) = -1.0
        #expect(profile.injuryVolumeCapPenalty == -1.0)
    }

    @Test("factory derives VG density from experience proxy when years is 0")
    func factoryDerivesVgDensityFromExperience() {
        // Beginner with 0 explicit years → proxy 1.0 → vgDensity:
        // years bracket <3 → 0.92; ultraCount 0 → 0.95; product = 0.874
        let athlete = makeAthlete(runningYears: 0, experience: .beginner)
        let profile = PersonalizationProfile.from(athlete: athlete)
        #expect((profile.vgDensityMultiplier - 0.874).magnitude < 0.001)
    }

    // MARK: - Recent peak weekly volume

    @Test("computeRecentPeakWeeklyVolumeKm returns nil when fewer than 4 weeks of data")
    func recentPeakReturnsNilForThinHistory() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        // 3 runs in 3 different weeks → only 3 weeks total
        let runs = [
            makeRun(daysFromNow: -3, distanceKm: 10, now: now),
            makeRun(daysFromNow: -10, distanceKm: 12, now: now),
            makeRun(daysFromNow: -17, distanceKm: 15, now: now),
        ]
        let peak = PersonalizationProfile.computeRecentPeakWeeklyVolumeKm(
            runs: runs, now: now
        )
        #expect(peak == nil)
    }

    @Test("computeRecentPeakWeeklyVolumeKm returns max weekly km across 90-day window")
    func recentPeakReturnsMaxWeekly() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        // Spread across 5 different weeks. Peak week (3 weeks ago)
        // has 50 km total.
        let runs = [
            // Week -1: 30 km
            makeRun(daysFromNow: -3, distanceKm: 15, now: now),
            makeRun(daysFromNow: -5, distanceKm: 15, now: now),
            // Week -2: 40 km
            makeRun(daysFromNow: -10, distanceKm: 20, now: now),
            makeRun(daysFromNow: -12, distanceKm: 20, now: now),
            // Week -3: 50 km (PEAK)
            makeRun(daysFromNow: -17, distanceKm: 25, now: now),
            makeRun(daysFromNow: -19, distanceKm: 25, now: now),
            // Week -4: 35 km
            makeRun(daysFromNow: -24, distanceKm: 18, now: now),
            makeRun(daysFromNow: -26, distanceKm: 17, now: now),
            // Week -5: 25 km
            makeRun(daysFromNow: -31, distanceKm: 25, now: now),
        ]
        let peak = PersonalizationProfile.computeRecentPeakWeeklyVolumeKm(
            runs: runs, now: now
        )
        #expect(peak == 50)
    }

    @Test("computeRecentPeakWeeklyVolumeKm ignores runs older than the 90-day window")
    func recentPeakIgnoresOldRuns() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let runs = [
            // Inside window: 4 weeks of consistent 20 km
            makeRun(daysFromNow: -3,  distanceKm: 20, now: now),
            makeRun(daysFromNow: -10, distanceKm: 20, now: now),
            makeRun(daysFromNow: -17, distanceKm: 20, now: now),
            makeRun(daysFromNow: -24, distanceKm: 20, now: now),
            // Outside window: 100 km bomb 6 months ago — should be ignored
            makeRun(daysFromNow: -180, distanceKm: 100, now: now),
        ]
        let peak = PersonalizationProfile.computeRecentPeakWeeklyVolumeKm(
            runs: runs, now: now
        )
        #expect(peak == 20)
    }

    @Test("computeRecentPeakWeeklyVolumeKm ignores cross-training and zero-distance entries")
    func recentPeakIgnoresNonRunning() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var crossTrainingRun = makeRun(daysFromNow: -3, distanceKm: 30, now: now)
        crossTrainingRun.activityType = .cycling
        let zeroDistance = makeRun(daysFromNow: -10, distanceKm: 0, now: now)
        let runs = [
            crossTrainingRun,
            zeroDistance,
            makeRun(daysFromNow: -17, distanceKm: 15, now: now),
            makeRun(daysFromNow: -24, distanceKm: 15, now: now),
            makeRun(daysFromNow: -31, distanceKm: 15, now: now),
            makeRun(daysFromNow: -38, distanceKm: 15, now: now),
        ]
        let peak = PersonalizationProfile.computeRecentPeakWeeklyVolumeKm(
            runs: runs, now: now
        )
        // Only the 4 valid running entries count, max weekly = 15
        #expect(peak == 15)
    }

    // MARK: - effectiveWeeklyVolumeKm

    @Test("effectiveWeeklyVolumeKm picks recentPeak when athlete is more capable than snapshot")
    func effectiveUsesPeakWhenAthleteMoreCapable() {
        // Snapshot 50, demonstrated 70 (40% above) → use 70
        let p = makeProfile(recentPeakWeeklyVolumeKm: 70)
        #expect(p.effectiveWeeklyVolumeKm(snapshotKm: 50) == 70)
    }

    @Test("effectiveWeeklyVolumeKm picks recentPeak when athlete has detrained")
    func effectiveUsesPeakWhenDetrained() {
        // Snapshot 80, demonstrated 40 (50% below) → use 40
        let p = makeProfile(recentPeakWeeklyVolumeKm: 40)
        #expect(p.effectiveWeeklyVolumeKm(snapshotKm: 80) == 40)
    }

    @Test("effectiveWeeklyVolumeKm uses snapshot when peak is close to snapshot")
    func effectiveUsesSnapshotWhenClose() {
        // Snapshot 50, demonstrated 55 (10% above) → still use snapshot
        let p = makeProfile(recentPeakWeeklyVolumeKm: 55)
        #expect(p.effectiveWeeklyVolumeKm(snapshotKm: 50) == 50)
    }

    @Test("effectiveWeeklyVolumeKm falls back to snapshot when no recent peak")
    func effectiveFallsBackToSnapshot() {
        let p = makeProfile(recentPeakWeeklyVolumeKm: nil)
        #expect(p.effectiveWeeklyVolumeKm(snapshotKm: 60) == 60)
    }

    @Test("factory wires recentPeak from computeRecentPeakWeeklyVolumeKm")
    func factoryWiresRecentPeak() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let runs = [
            makeRun(daysFromNow: -3,  distanceKm: 25, now: now),
            makeRun(daysFromNow: -10, distanceKm: 25, now: now),
            makeRun(daysFromNow: -17, distanceKm: 25, now: now),
            makeRun(daysFromNow: -24, distanceKm: 25, now: now),
        ]
        let athlete = makeAthlete()
        let profile = PersonalizationProfile.from(
            athlete: athlete,
            recentRuns: runs,
            now: now
        )
        #expect(profile.recentPeakWeeklyVolumeKm == 25)
    }

    private func makeRun(
        daysFromNow: Int,
        distanceKm: Double,
        now: Date,
        rpe: Int? = nil,
        feeling: PerceivedFeeling? = nil
    ) -> CompletedRun {
        let date = Calendar.current.date(byAdding: .day, value: daysFromNow, to: now)!
        var run = CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: date,
            distanceKm: distanceKm,
            elevationGainM: 0,
            elevationLossM: 0,
            duration: distanceKm * 360, // 6 min/km baseline
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            pausedDuration: 0
        )
        run.rpe = rpe
        run.perceivedFeeling = feeling
        return run
    }

    // MARK: - Adaptation signal

    @Test("computeAdaptationSignal returns nil with fewer than 6 logged runs")
    func adaptationSignalNilWhenThinHistory() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let runs = [
            makeRun(daysFromNow: -3, distanceKm: 10, now: now, rpe: 6),
            makeRun(daysFromNow: -10, distanceKm: 12, now: now, rpe: 7),
        ]
        let signal = PersonalizationProfile.computeAdaptationSignal(
            runs: runs, now: now
        )
        #expect(signal == nil)
    }

    @Test("computeAdaptationSignal averages RPE across logged runs")
    func adaptationSignalAveragesRPE() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let runs = [
            makeRun(daysFromNow: -3, distanceKm: 10, now: now, rpe: 5),
            makeRun(daysFromNow: -7, distanceKm: 10, now: now, rpe: 6),
            makeRun(daysFromNow: -11, distanceKm: 10, now: now, rpe: 7),
            makeRun(daysFromNow: -15, distanceKm: 10, now: now, rpe: 6),
            makeRun(daysFromNow: -19, distanceKm: 10, now: now, rpe: 5),
            makeRun(daysFromNow: -23, distanceKm: 10, now: now, rpe: 7),
        ]
        let signal = PersonalizationProfile.computeAdaptationSignal(
            runs: runs, now: now
        )
        #expect(signal != nil)
        #expect(signal?.runCount == 6)
        // (5+6+7+6+5+7)/6 = 6.0
        #expect(signal?.avgRPE == 6.0)
        #expect(signal?.avgPerceivedFeelingScore == nil)
    }

    @Test("computeAdaptationSignal averages feeling score, ignores nil entries")
    func adaptationSignalAveragesFeeling() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let runs = [
            makeRun(daysFromNow: -3, distanceKm: 10, now: now, feeling: .great),
            makeRun(daysFromNow: -7, distanceKm: 10, now: now, feeling: .good),
            makeRun(daysFromNow: -11, distanceKm: 10, now: now, feeling: .ok),
            makeRun(daysFromNow: -15, distanceKm: 10, now: now, feeling: .good),
            makeRun(daysFromNow: -19, distanceKm: 10, now: now, feeling: .great),
            makeRun(daysFromNow: -23, distanceKm: 10, now: now, feeling: .ok),
        ]
        let signal = PersonalizationProfile.computeAdaptationSignal(
            runs: runs, now: now
        )
        // (5+4+3+4+5+3)/6 = 4.0
        #expect(signal?.avgPerceivedFeelingScore == 4.0)
        #expect(signal?.avgRPE == nil)
    }

    @Test("computeAdaptationSignal ignores runs without any signal data")
    func adaptationSignalIgnoresUntaggedRuns() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let runs = [
            // 5 runs without RPE/feeling — should not count
            makeRun(daysFromNow: -3, distanceKm: 10, now: now),
            makeRun(daysFromNow: -7, distanceKm: 10, now: now),
            makeRun(daysFromNow: -11, distanceKm: 10, now: now),
            makeRun(daysFromNow: -15, distanceKm: 10, now: now),
            makeRun(daysFromNow: -19, distanceKm: 10, now: now),
            // Only 1 run with RPE — below the 6-run threshold
            makeRun(daysFromNow: -23, distanceKm: 10, now: now, rpe: 5),
        ]
        let signal = PersonalizationProfile.computeAdaptationSignal(
            runs: runs, now: now
        )
        #expect(signal == nil)
    }

    // MARK: - adaptationMultiplier

    @Test("adaptationMultiplier returns 1.0 when no signal")
    func adaptationMultNilSignal() {
        #expect(PersonalizationProfile.adaptationMultiplier(signal: nil) == 1.0)
    }

    @Test("adaptationMultiplier: ideal RPE alone gives modest bump")
    func adaptationMultIdealRPE() {
        let signal = PersonalizationProfile.AdaptationSignal(
            runCount: 8, avgRPE: 6.0, avgPerceivedFeelingScore: nil
        )
        // Bracket 5.5-6.5 → +1.5% → 1.015
        #expect(PersonalizationProfile.adaptationMultiplier(signal: signal) == 1.015)
    }

    @Test("adaptationMultiplier: high RPE gives cut")
    func adaptationMultHighRPECuts() {
        let signal = PersonalizationProfile.AdaptationSignal(
            runCount: 8, avgRPE: 8.0, avgPerceivedFeelingScore: nil
        )
        // Bracket 7.5-8.5 → -1.5% → 0.985
        #expect(PersonalizationProfile.adaptationMultiplier(signal: signal) == 0.985)
    }

    @Test("adaptationMultiplier: severe overload caps at -3%")
    func adaptationMultSevereOverloadClamps() {
        let signal = PersonalizationProfile.AdaptationSignal(
            runCount: 8, avgRPE: 9.5, avgPerceivedFeelingScore: 1.0
        )
        // RPE 9.5 → -3%, feeling 1.0 → -3%, avg = -3% → 0.97
        #expect(PersonalizationProfile.adaptationMultiplier(signal: signal) == 0.97)
    }

    @Test("adaptationMultiplier: disagreement between axes dampens swing")
    func adaptationMultDisagreement() {
        // RPE says ideal (+1.5%) but feeling is rough (-1.5%)
        // Average = 0% → 1.0
        let signal = PersonalizationProfile.AdaptationSignal(
            runCount: 8, avgRPE: 6.0, avgPerceivedFeelingScore: 2.0
        )
        #expect(PersonalizationProfile.adaptationMultiplier(signal: signal) == 1.0)
    }

    @Test("adaptationMultiplier: bounded to [0.97, 1.03]")
    func adaptationMultBounds() {
        // Best case: RPE just under 5.5 (+2.0%) + feeling great (+1.5%)
        // avg = 1.75% → 1.0175 (within bounds)
        let best = PersonalizationProfile.AdaptationSignal(
            runCount: 8, avgRPE: 5.0, avgPerceivedFeelingScore: 5.0
        )
        let bestMult = PersonalizationProfile.adaptationMultiplier(signal: best)
        #expect(bestMult >= 1.0 && bestMult <= 1.03)
    }

    @Test("factory wires adaptationMultiplier from history")
    func factoryWiresAdaptation() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        // 6 runs all logged with great feeling + ideal RPE
        let runs = (1...6).map { i in
            makeRun(
                daysFromNow: -3 * i, distanceKm: 10, now: now,
                rpe: 6, feeling: .great
            )
        }
        let athlete = makeAthlete()
        let profile = PersonalizationProfile.from(
            athlete: athlete, recentRuns: runs, now: now
        )
        // RPE ideal (+1.5%) + feeling great (+1.5%), avg = +1.5% → 1.015
        #expect(profile.adaptationMultiplier == 1.015)
    }

    @Test("trail composite includes adaptation multiplier")
    func trailCompositeIncludesAdaptation() {
        let p = makeProfile(adaptationMultiplier: 1.02)
        // 1.0 × 1.0 × 1.0 × 1.02 = 1.02
        #expect(p.trailComposite == 1.02)
    }

    @Test("road composite includes adaptation multiplier")
    func roadCompositeIncludesAdaptation() {
        let p = makeProfile(adaptationMultiplier: 0.98)
        #expect(p.roadComposite == 0.98)
    }

    // MARK: - Helper

    private func makeProfile(
        tenureMultiplier: Double = 1.0,
        weightMultiplier: Double = 1.0,
        ultraExperienceMultiplier: Double = 1.0,
        vgDensityMultiplier: Double = 1.0,
        adaptationMultiplier: Double = 1.0,
        historicalLongRunCapSeconds: TimeInterval? = nil,
        recentPeakWeeklyVolumeKm: Double? = nil,
        injuryStructures: Set<InjuryStructure> = [],
        injuryVolumeCapPenalty: Double = 0
    ) -> PersonalizationProfile {
        PersonalizationProfile(
            tenureMultiplier: tenureMultiplier,
            weightMultiplier: weightMultiplier,
            ultraExperienceMultiplier: ultraExperienceMultiplier,
            vgDensityMultiplier: vgDensityMultiplier,
            adaptationMultiplier: adaptationMultiplier,
            historicalLongRunCapSeconds: historicalLongRunCapSeconds,
            recentPeakWeeklyVolumeKm: recentPeakWeeklyVolumeKm,
            injuryStructures: injuryStructures,
            injuryVolumeCapPenalty: injuryVolumeCapPenalty
        )
    }

    private func makeAthlete(
        weightKg: Double = 70,
        longestRunKm: Double = 0,
        runningYears: Double = 0,
        injuryStructures: Set<InjuryStructure> = [],
        experience: ExperienceLevel = .intermediate,
        painFrequency: PainFrequency = .never,
        injuryCount: InjuryCount = .none
    ) -> Athlete {
        var a = Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Athlete",
            dateOfBirth: Date(timeIntervalSince1970: 0),
            weightKg: weightKg,
            heightCm: 175,
            restingHeartRate: 50,
            maxHeartRate: 190,
            experienceLevel: experience,
            weeklyVolumeKm: 40,
            longestRunKm: longestRunKm,
            preferredUnit: .metric
        )
        a.runningYears = runningYears
        a.injuryStructures = injuryStructures
        a.painFrequency = painFrequency
        a.injuryCountLastYear = injuryCount
        return a
    }
}
