import Foundation
import Testing
@testable import UltraTrain

@Suite("FitnessTestScheduler")
struct FitnessTestSchedulerTests {

    // MARK: - Helpers

    private func makeAthlete(
        experience: ExperienceLevel = .intermediate,
        philosophy: TrainingPhilosophy = .balanced,
        env: VerticalGainEnvironment = .mountain,
        uphill: UphillDuration = .over8Min,
        vmaKmh: Double? = 14.0
    ) -> Athlete {
        Athlete(
            id: UUID(), firstName: "Test", lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70, heightCm: 175,
            restingHeartRate: 50, maxHeartRate: 185,
            experienceLevel: experience,
            weeklyVolumeKm: 50, longestRunKm: 25,
            preferredUnit: .metric,
            trainingPhilosophy: philosophy,
            preferredRunsPerWeek: 5,
            verticalGainEnvironment: env,
            uphillDuration: uphill,
            vmaKmh: vmaKmh
        )
    }

    private func makeRace(
        type: RaceType = .road,
        distanceKm: Double = 42.195,
        elevationGainM: Double = 0
    ) -> Race {
        Race(
            id: UUID(), name: "Test", date: .now.addingTimeInterval(86400 * 7 * 16),
            distanceKm: distanceKm,
            elevationGainM: elevationGainM, elevationLossM: elevationGainM,
            priority: .aRace, goalType: .finish, checkpoints: [],
            terrainDifficulty: type == .road ? .easy : .moderate,
            raceType: type
        )
    }

    private func makeSkeletons(
        weeks: Int,
        recoveryEvery: Int = 4
    ) -> [WeekSkeletonBuilder.WeekSkeleton] {
        (0..<weeks).map { i in
            let phase: TrainingPhase
            if i < Int(Double(weeks) * 0.4) { phase = .base }
            else if i < Int(Double(weeks) * 0.7) { phase = .build }
            else if i < weeks - 2 { phase = .peak }
            else { phase = .taper }
            let isRecovery = (i + 1) % recoveryEvery == 0 && phase != .taper
            return WeekSkeletonBuilder.WeekSkeleton(
                weekNumber: i + 1,
                startDate: Date.now.addingTimeInterval(TimeInterval(i * 7 * 86400)),
                endDate: Date.now.addingTimeInterval(TimeInterval((i * 7 + 6) * 86400)),
                phase: phase,
                isRecoveryWeek: isRecovery,
                phaseFocus: phase.defaultFocus
            )
        }
    }

    // MARK: - Opt-in gate

    @Test("Returns nil when athlete didn't opt in")
    func returnsNilWhenNotOptedIn() {
        let race = makeRace(type: .road, distanceKm: 21.1)
        let athlete = makeAthlete()
        let skeletons = makeSkeletons(weeks: 16)
        let result = FitnessTestScheduler.schedule(
            skeletons: skeletons, targetRace: race, athlete: athlete,
            userOptIn: false
        )
        #expect(result == nil)
    }

    // MARK: - Race-distance gates

    @Test("Skips test for trail races ≥ 100K")
    func skipsTrail100KPlus() {
        let race = makeRace(type: .trail, distanceKm: 100, elevationGainM: 5000)
        let athlete = makeAthlete()
        let skeletons = makeSkeletons(weeks: 20)
        let result = FitnessTestScheduler.schedule(
            skeletons: skeletons, targetRace: race, athlete: athlete,
            userOptIn: true
        )
        #expect(result == nil, "100K ultra should skip the test")
    }

    @Test("Schedules test for trail races < 100K")
    func schedulesShortTrail() {
        let race = makeRace(type: .trail, distanceKm: 50, elevationGainM: 2500)
        let athlete = makeAthlete()
        let skeletons = makeSkeletons(weeks: 16)
        let result = FitnessTestScheduler.schedule(
            skeletons: skeletons, targetRace: race, athlete: athlete,
            userOptIn: true
        )
        #expect(result != nil, "50K trail should schedule a test")
    }

    @Test("Skips test for plans < 8 weeks")
    func skipsShortPlans() {
        let race = makeRace(type: .road, distanceKm: 21.1)
        let athlete = makeAthlete()
        let skeletons = makeSkeletons(weeks: 6)
        let result = FitnessTestScheduler.schedule(
            skeletons: skeletons, targetRace: race, athlete: athlete,
            userOptIn: true
        )
        #expect(result == nil)
    }

    // MARK: - Variant dispatch

    @Test("Road 10K → VMA flat 6-min")
    func roadTenKVariant() {
        let v = FitnessTestScheduler.pickVariant(
            targetRace: makeRace(type: .road, distanceKm: 10),
            athlete: makeAthlete()
        )
        #expect(v == .vmaFlat6Min)
    }

    @Test("Road marathon → 5K TT")
    func roadMarathonVariant() {
        let v = FitnessTestScheduler.pickVariant(
            targetRace: makeRace(type: .road, distanceKm: 42.195),
            athlete: makeAthlete()
        )
        #expect(v == .fiveKTT)
    }

    @Test("Trail mountain athlete with 8+ min hills → 30-min sustained uphill")
    func trailMountainSustained() {
        let v = FitnessTestScheduler.pickVariant(
            targetRace: makeRace(type: .trail, distanceKm: 50, elevationGainM: 2500),
            athlete: makeAthlete(env: .mountain, uphill: .over8Min)
        )
        #expect(v == .uphillSustained30Min)
    }

    @Test("Trail athlete with hill env + 8min hills → 4×8 repeats")
    func trailMidLengthRepeats() {
        let v = FitnessTestScheduler.pickVariant(
            targetRace: makeRace(type: .trail, distanceKm: 50, elevationGainM: 2500),
            athlete: makeAthlete(env: .hill, uphill: .upTo8Min)
        )
        #expect(v == .uphillRepeats4x8)
    }

    @Test("Trail athlete with 4-min hills → 5×4 repeats")
    func trailShortHillRepeats() {
        let v = FitnessTestScheduler.pickVariant(
            targetRace: makeRace(type: .trail, distanceKm: 50, elevationGainM: 2500),
            athlete: makeAthlete(env: .hill, uphill: .upTo4Min)
        )
        #expect(v == .uphillRepeats6x4)
    }

    @Test("Trail athlete with no hills → VMA flat fallback")
    func trailFlatFallback() {
        let v = FitnessTestScheduler.pickVariant(
            targetRace: makeRace(type: .trail, distanceKm: 50, elevationGainM: 1500),
            athlete: makeAthlete(env: .mixed, uphill: .none)
        )
        #expect(v == .vmaFlat6Min)
    }

    @Test("Treadmill athlete → treadmill incline test")
    func trailTreadmill() {
        let v = FitnessTestScheduler.pickVariant(
            targetRace: makeRace(type: .trail, distanceKm: 50, elevationGainM: 2500),
            athlete: makeAthlete(env: .treadmill, uphill: .none)
        )
        #expect(v == .treadmillIncline30Min)
    }

    // MARK: - Default opt-in

    @Test("Default ON for intermediate balanced athlete on standard plan")
    func defaultOptInIntermediate() {
        let race = makeRace(type: .road, distanceKm: 42.195)
        let athlete = makeAthlete(experience: .intermediate, philosophy: .balanced)
        #expect(FitnessTestScheduler.defaultOptIn(targetRace: race, athlete: athlete, planTotalWeeks: 16) == true)
    }

    @Test("Default OFF for beginner")
    func defaultOptInBeginner() {
        let race = makeRace(type: .road, distanceKm: 42.195)
        let athlete = makeAthlete(experience: .beginner)
        #expect(FitnessTestScheduler.defaultOptIn(targetRace: race, athlete: athlete, planTotalWeeks: 16) == false)
    }

    @Test("Default OFF for enjoyment philosophy")
    func defaultOptInEnjoyment() {
        let race = makeRace(type: .road, distanceKm: 42.195)
        let athlete = makeAthlete(philosophy: .enjoyment)
        #expect(FitnessTestScheduler.defaultOptIn(targetRace: race, athlete: athlete, planTotalWeeks: 16) == false)
    }

    @Test("Default OFF for 100K+ ultra")
    func defaultOptIn100K() {
        let race = makeRace(type: .trail, distanceKm: 161, elevationGainM: 4500)
        let athlete = makeAthlete()
        #expect(FitnessTestScheduler.defaultOptIn(targetRace: race, athlete: athlete, planTotalWeeks: 20) == false)
    }

    // MARK: - Test placement

    @Test("Test lands in base or build phase, never recovery week")
    func testNeverInRecoveryOrTaper() {
        let race = makeRace(type: .road, distanceKm: 21.1)
        let athlete = makeAthlete()
        let skeletons = makeSkeletons(weeks: 16)
        guard let s = FitnessTestScheduler.schedule(
            skeletons: skeletons, targetRace: race, athlete: athlete,
            userOptIn: true
        ) else { Issue.record("Expected test to be scheduled"); return }
        let week = skeletons.first { $0.weekNumber == s.weekNumber }!
        #expect(week.phase == .base || week.phase == .build)
        #expect(!week.isRecoveryWeek)
    }

    @Test("Test placed near week 5 for ≥12-week plans")
    func testNearWeek5() {
        let race = makeRace(type: .road, distanceKm: 21.1)
        let athlete = makeAthlete()
        let skeletons = makeSkeletons(weeks: 16)
        guard let s = FitnessTestScheduler.schedule(
            skeletons: skeletons, targetRace: race, athlete: athlete,
            userOptIn: true
        ) else { Issue.record("Expected schedule"); return }
        // Should land within ±3 of week 5 (offsets searched outward)
        #expect(abs(s.weekNumber - 5) <= 3, "Test landed at week \(s.weekNumber)")
    }
}
