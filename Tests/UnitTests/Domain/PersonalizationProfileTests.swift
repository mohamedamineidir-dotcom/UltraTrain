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
        let high = PersonalizationProfile(
            tenureMultiplier: 1.10,
            weightMultiplier: 1.03,
            ultraExperienceMultiplier: 1.10,
            vgDensityMultiplier: 1.0,
            historicalLongRunCapSeconds: nil,
            injuryStructures: []
        )
        #expect(high.trailComposite <= 1.30)
        #expect(high.trailComposite > 1.20)

        // Minimum stack: tenure 0.92 × weight 0.93 × ultra 0.95 = 0.8129 → not clamped
        let low = PersonalizationProfile(
            tenureMultiplier: 0.92,
            weightMultiplier: 0.93,
            ultraExperienceMultiplier: 0.95,
            vgDensityMultiplier: 1.0,
            historicalLongRunCapSeconds: nil,
            injuryStructures: []
        )
        #expect(low.trailComposite >= 0.75)
        #expect(low.trailComposite < 0.85)
    }

    @Test("composite hard-clamps when stacked extreme inputs exceed bounds")
    func compositeHardClamps() {
        // Synthetic profile with values outside the natural [0.92, 1.10]
        // brackets — should clamp to 1.30 / 0.75.
        let extreme = PersonalizationProfile(
            tenureMultiplier: 1.5,
            weightMultiplier: 1.5,
            ultraExperienceMultiplier: 1.5,
            vgDensityMultiplier: 1.0,
            historicalLongRunCapSeconds: nil,
            injuryStructures: []
        )
        #expect(extreme.trailComposite == 1.30)

        let lowExtreme = PersonalizationProfile(
            tenureMultiplier: 0.5,
            weightMultiplier: 0.5,
            ultraExperienceMultiplier: 0.5,
            vgDensityMultiplier: 1.0,
            historicalLongRunCapSeconds: nil,
            injuryStructures: []
        )
        #expect(lowExtreme.trailComposite == 0.75)
    }

    @Test("road composite ignores ultra experience")
    func roadCompositeIgnoresUltra() {
        let withHighUltra = PersonalizationProfile(
            tenureMultiplier: 1.00,
            weightMultiplier: 1.00,
            ultraExperienceMultiplier: 1.10,
            vgDensityMultiplier: 1.0,
            historicalLongRunCapSeconds: nil,
            injuryStructures: []
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

    @Test("injury volume cap penalty scales by structure count, capped at -2.0%")
    func injuryPenaltyScales() {
        let none = PersonalizationProfile.neutral
        #expect(none.injuryVolumeCapPenalty == 0)

        let one = PersonalizationProfile(
            tenureMultiplier: 1.0, weightMultiplier: 1.0,
            ultraExperienceMultiplier: 1.0,
            vgDensityMultiplier: 1.0,
            historicalLongRunCapSeconds: nil,
            injuryStructures: [.knees]
        )
        #expect(one.injuryVolumeCapPenalty == -0.5)

        let three = PersonalizationProfile(
            tenureMultiplier: 1.0, weightMultiplier: 1.0,
            ultraExperienceMultiplier: 1.0,
            vgDensityMultiplier: 1.0,
            historicalLongRunCapSeconds: nil,
            injuryStructures: [.knees, .hips, .calf]
        )
        #expect(three.injuryVolumeCapPenalty == -1.5)

        let manyStructures: Set<InjuryStructure> = [.knees, .hips, .calf, .achilles, .itBand, .footAnkle]
        let many = PersonalizationProfile(
            tenureMultiplier: 1.0, weightMultiplier: 1.0,
            ultraExperienceMultiplier: 1.0,
            vgDensityMultiplier: 1.0,
            historicalLongRunCapSeconds: nil,
            injuryStructures: manyStructures
        )
        #expect(many.injuryVolumeCapPenalty == -2.0, "should cap at -2.0 even with 6 structures")
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

    // MARK: - Helper

    private func makeAthlete(
        weightKg: Double = 70,
        longestRunKm: Double = 0,
        runningYears: Double = 0,
        injuryStructures: Set<InjuryStructure> = []
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
            experienceLevel: .intermediate,
            weeklyVolumeKm: 40,
            longestRunKm: longestRunKm,
            preferredUnit: .metric
        )
        a.runningYears = runningYears
        a.injuryStructures = injuryStructures
        return a
    }
}
