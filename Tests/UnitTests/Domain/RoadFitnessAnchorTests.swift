import Foundation
import Testing
@testable import UltraTrain

@Suite("Road fitness anchor + multi-distance projections")
struct RoadFitnessAnchorTests {

    private func makeAthlete(
        experience: ExperienceLevel = .advanced,
        personalBests: [PersonalBest] = [],
        vmaKmh: Double? = nil
    ) -> Athlete {
        var athlete = Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 65,
            heightCm: 175,
            restingHeartRate: 48,
            maxHeartRate: 190,
            experienceLevel: experience,
            weeklyVolumeKm: 60,
            longestRunKm: 25,
            preferredUnit: .metric
        )
        athlete.personalBests = personalBests
        athlete.vmaKmh = vmaKmh
        return athlete
    }

    private func pb(_ d: PersonalBestDistance, _ seconds: TimeInterval, daysAgo: Double = 0) -> PersonalBest {
        PersonalBest(
            id: UUID(), distance: d, timeSeconds: seconds,
            date: Date.now.addingTimeInterval(-daysAgo * 86400)
        )
    }

    // MARK: - Anchor selection

    @Test("A stronger 10K overrides a stale, slower-equivalent 5K")
    func betterTenKOverridesFiveK() {
        // 5K 17:45 (1065s) vs 10K 35:00 (2100s, ~16:47 5K-equivalent).
        let fiveKOnly = RoadPaceCalculator.bestFitness5KTime(
            personalBests: [pb(.fiveK, 1065)]
        )!
        let withBetterTenK = RoadPaceCalculator.bestFitness5KTime(
            personalBests: [pb(.fiveK, 1065), pb(.tenK, 2100)]
        )!
        // Adding the superior 10K must speed up the 5K-equivalent anchor,
        // landing below the lone 5K's 1065s.
        #expect(withBetterTenK < fiveKOnly)
        #expect(withBetterTenK < 1065)
    }

    @Test("A lone 5K PR anchors to itself (no behavior change)")
    func loneFiveKUnchanged() {
        let anchor = RoadPaceCalculator.bestFitness5KTime(personalBests: [pb(.fiveK, 1065)])!
        // Riegel 5K->5K is the identity, recency ~1.0, so ~1065s.
        #expect(abs(anchor - 1065) < 2.0)
    }

    @Test("No road PRs returns nil")
    func noPRsNil() {
        #expect(RoadPaceCalculator.bestFitness5KTime(personalBests: []) == nil)
    }

    // MARK: - Profile responds to a better PR (the Part-2 bug)

    @Test("Logging a faster 10K speeds up the derived pace profile")
    func betterPRSpeedsUpProfile() {
        // Same stale 5K both times; only the 10K improves 37:00 -> 35:00.
        let before = makeAthlete(personalBests: [pb(.fiveK, 1065), pb(.tenK, 2220)])
        let after = makeAthlete(personalBests: [pb(.fiveK, 1065), pb(.tenK, 2100)])

        let p1 = RoadPaceCalculator.paceProfile(
            goalTime: nil, raceDistanceKm: 42.195,
            personalBests: before.personalBests, vmaKmh: nil, experience: .advanced
        )
        let p2 = RoadPaceCalculator.paceProfile(
            goalTime: nil, raceDistanceKm: 42.195,
            personalBests: after.personalBests, vmaKmh: nil, experience: .advanced
        )

        // A better 10K must tighten every derived training pace. Previously
        // the profile stayed pinned to the unchanged 5K and nothing moved.
        #expect(p2.thresholdPacePerKm < p1.thresholdPacePerKm)
        #expect(p2.intervalPacePerKm < p1.intervalPacePerKm)
        #expect(p2.easyPacePerKm.lowerBound < p1.easyPacePerKm.lowerBound)
    }

    // MARK: - Consistent projections (the Part-1 redesign)

    @Test("Fitness projections are monotonic across distances")
    func projectionsMonotonic() {
        // Inconsistent official PRs (great 10K, weak 5K) must still yield a
        // monotonic fitness estimate: pace per km grows with distance.
        let athlete = makeAthlete(personalBests: [pb(.fiveK, 1065), pb(.tenK, 2100)])
        let proj = MultiDistanceEstimator.fitnessProjections(for: athlete)!
        let pace = Dictionary(uniqueKeysWithValues: proj.map { ($0.distance, $0.pacePerKm ?? 0) })
        #expect(pace[.fiveK]! < pace[.tenK]!)
        #expect(pace[.tenK]! < pace[.halfMarathon]!)
        #expect(pace[.halfMarathon]! < pace[.marathon]!)
    }

    @Test("Fitness projections fall back to VMA, else nil")
    func projectionsVMAFallback() {
        #expect(MultiDistanceEstimator.fitnessProjections(for: makeAthlete(vmaKmh: 18.0)) != nil)
        #expect(MultiDistanceEstimator.fitnessProjections(for: makeAthlete()) == nil)
    }
}
