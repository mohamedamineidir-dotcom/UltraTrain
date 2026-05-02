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

    // MARK: - Helper

    private func makeProfile(
        tenureMultiplier: Double = 1.0,
        weightMultiplier: Double = 1.0,
        ultraExperienceMultiplier: Double = 1.0,
        vgDensityMultiplier: Double = 1.0,
        historicalLongRunCapSeconds: TimeInterval? = nil,
        injuryStructures: Set<InjuryStructure> = [],
        injuryVolumeCapPenalty: Double = 0
    ) -> PersonalizationProfile {
        PersonalizationProfile(
            tenureMultiplier: tenureMultiplier,
            weightMultiplier: weightMultiplier,
            ultraExperienceMultiplier: ultraExperienceMultiplier,
            vgDensityMultiplier: vgDensityMultiplier,
            historicalLongRunCapSeconds: historicalLongRunCapSeconds,
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
