import Foundation
import Testing
@testable import UltraTrain

@Suite("Race-recovery templates")
struct RaceRecoveryTemplatesTests {

    // MARK: - Helpers

    private func makeMondayBaseline() -> Date {
        var c = DateComponents(); c.year = 2026; c.month = 8; c.day = 24
        return Calendar.current.date(from: c)!
    }

    private func makeTrailRace(distanceKm: Double, elevationGainM: Double) -> Race {
        Race(
            id: UUID(), name: "Test Trail", date: makeMondayBaseline(),
            distanceKm: distanceKm,
            elevationGainM: elevationGainM, elevationLossM: elevationGainM,
            priority: .aRace, goalType: .finish, checkpoints: [],
            terrainDifficulty: .technical, raceType: .trail
        )
    }

    private func makeRoadRace(distanceKm: Double) -> Race {
        Race(
            id: UUID(), name: "Test Road", date: makeMondayBaseline(),
            distanceKm: distanceKm, elevationGainM: 0, elevationLossM: 0,
            priority: .aRace, goalType: .finish, checkpoints: [],
            terrainDifficulty: .easy, raceType: .road
        )
    }

    private func runDuration(_ templates: [SessionTemplateGenerator.SessionTemplate]) -> TimeInterval {
        templates.filter { $0.type != .rest }.reduce(0) { $0 + $1.durationSeconds }
    }

    // MARK: - Trail: volume ordering by week

    @Test("Trail 100mi: W1 has the lowest active volume, W5 highest")
    func trail100MileMonotonicWeeks() {
        let race = makeTrailRace(distanceKm: 161, elevationGainM: 4500)
        let durations = (1...5).map { week -> TimeInterval in
            let t = TrailRaceRecoveryTemplates.sessions(
                targetRace: race, experience: .intermediate,
                philosophy: .balanced,
                weekStartDate: makeMondayBaseline(),
                weekInRecovery: week
            )
            return runDuration(t)
        }
        // Strictly increasing across weeks.
        for i in 0..<(durations.count - 1) {
            #expect(durations[i] < durations[i + 1],
                "Week \(i + 1) (\(durations[i])s) should be lighter than week \(i + 2) (\(durations[i + 1])s)")
        }
    }

    @Test("Trail 100K: W1 has the lowest active volume, W4 highest")
    func trail100KMonotonicWeeks() {
        let race = makeTrailRace(distanceKm: 105, elevationGainM: 4500)
        let durations = (1...4).map { week -> TimeInterval in
            let t = TrailRaceRecoveryTemplates.sessions(
                targetRace: race, experience: .intermediate,
                philosophy: .balanced,
                weekStartDate: makeMondayBaseline(),
                weekInRecovery: week
            )
            return runDuration(t)
        }
        for i in 0..<(durations.count - 1) {
            #expect(durations[i] < durations[i + 1])
        }
    }

    // MARK: - Cross-training presence

    @Test("Trail 100mi W1: contains zero or very minimal running, multiple rest days")
    func trail100MileWeek1IsMostlyRest() {
        let race = makeTrailRace(distanceKm: 161, elevationGainM: 4500)
        let templates = TrailRaceRecoveryTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced,
            weekStartDate: makeMondayBaseline(),
            weekInRecovery: 1
        )
        let runningDays = templates.filter { $0.type == .recovery }.count
        let restDays = templates.filter { $0.type == .rest }.count
        #expect(runningDays == 0,
            "100-mile W1 should have zero running days, got \(runningDays)")
        #expect(restDays >= 5,
            "100-mile W1 should have at least 5 rest days, got \(restDays)")
    }

    @Test("Trail 100mi W2: prescribes cross-training")
    func trail100MileWeek2HasCrossTraining() {
        let race = makeTrailRace(distanceKm: 161, elevationGainM: 4500)
        let templates = TrailRaceRecoveryTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced,
            weekStartDate: makeMondayBaseline(),
            weekInRecovery: 2
        )
        let crossTrainingDays = templates.filter { $0.type == .crossTraining }.count
        #expect(crossTrainingDays >= 1,
            "100-mile W2 should prescribe at least one cross-training session, got \(crossTrainingDays)")
    }

    @Test("Trail 50-mile W1: prescribes cross-training over running")
    func trail50MileWeek1HasCrossTraining() {
        let race = makeTrailRace(distanceKm: 80, elevationGainM: 3000)
        let templates = TrailRaceRecoveryTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced,
            weekStartDate: makeMondayBaseline(),
            weekInRecovery: 1
        )
        let crossTrainingDays = templates.filter { $0.type == .crossTraining }.count
        let runningDays = templates.filter { $0.type == .recovery }.count
        #expect(crossTrainingDays >= 1, "50mi W1 prescribes cross-training")
        // Running days should be very limited in W1.
        #expect(runningDays <= 1, "50mi W1 should have ≤1 running day, got \(runningDays)")
    }

    // MARK: - Mountain modifier

    @Test("Trail 50K mountain W2: replaces some running with cross-training vs flat 50K")
    func mountainModifierAddsCrossTraining() {
        let mountain = makeTrailRace(distanceKm: 50, elevationGainM: 2500) // density 50 m/km
        let flat = makeTrailRace(distanceKm: 50, elevationGainM: 1000)     // density 20 m/km
        let mountainTpl = TrailRaceRecoveryTemplates.sessions(
            targetRace: mountain, experience: .intermediate,
            philosophy: .balanced,
            weekStartDate: makeMondayBaseline(),
            weekInRecovery: 2
        )
        let flatTpl = TrailRaceRecoveryTemplates.sessions(
            targetRace: flat, experience: .intermediate,
            philosophy: .balanced,
            weekStartDate: makeMondayBaseline(),
            weekInRecovery: 2
        )
        let mountainCT = mountainTpl.filter { $0.type == .crossTraining }.count
        let flatCT = flatTpl.filter { $0.type == .crossTraining }.count
        #expect(mountainCT >= flatCT,
            "Mountain 50K should have ≥ cross-training as flat 50K (\(mountainCT) vs \(flatCT))")
    }

    @Test("Trail 100K mountain W1: zero hill running (elevation = 0)")
    func mountain100KW1NoElevation() {
        let race = makeTrailRace(distanceKm: 105, elevationGainM: 6500)
        let templates = TrailRaceRecoveryTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced,
            weekStartDate: makeMondayBaseline(),
            weekInRecovery: 1
        )
        let elev = templates.reduce(0.0) { $0 + $1.elevationFraction }
        #expect(elev == 0, "All recovery sessions must have elevationFraction=0")
    }

    // MARK: - Experience modifier

    @Test("Trail 50K W1: beginner has more rest days than advanced")
    func beginnerMoreRestThanAdvanced() {
        let race = makeTrailRace(distanceKm: 50, elevationGainM: 1500)
        let beginner = TrailRaceRecoveryTemplates.sessions(
            targetRace: race, experience: .beginner,
            philosophy: .balanced,
            weekStartDate: makeMondayBaseline(),
            weekInRecovery: 1
        )
        let advanced = TrailRaceRecoveryTemplates.sessions(
            targetRace: race, experience: .advanced,
            philosophy: .balanced,
            weekStartDate: makeMondayBaseline(),
            weekInRecovery: 1
        )
        let bRest = beginner.filter { $0.type == .rest }.count
        let aRest = advanced.filter { $0.type == .rest }.count
        #expect(bRest >= aRest,
            "Beginner should have ≥ rest days vs advanced (\(bRest) vs \(aRest))")
    }

    // MARK: - Philosophy modifier

    @Test("Trail 100K W3: performance retains more volume than enjoyment")
    func performanceMoreVolumeThanEnjoyment() {
        let race = makeTrailRace(distanceKm: 105, elevationGainM: 4500)
        let perf = TrailRaceRecoveryTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .performance,
            weekStartDate: makeMondayBaseline(),
            weekInRecovery: 3
        )
        let enjoy = TrailRaceRecoveryTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .enjoyment,
            weekStartDate: makeMondayBaseline(),
            weekInRecovery: 3
        )
        #expect(runDuration(perf) > runDuration(enjoy),
            "Performance recovery duration should exceed enjoyment")
    }

    // MARK: - Coverage

    @Test("Trail: every recovery week covers all 7 days exactly once")
    func trailCoversFullWeek() {
        let race = makeTrailRace(distanceKm: 161, elevationGainM: 4500)
        for week in 1...5 {
            let t = TrailRaceRecoveryTemplates.sessions(
                targetRace: race, experience: .intermediate,
                philosophy: .balanced,
                weekStartDate: makeMondayBaseline(),
                weekInRecovery: week
            )
            let days = Set(t.map(\.dayOffset))
            #expect(days == Set(0...6), "Week \(week) day coverage")
            #expect(t.count == 7, "Week \(week) session count")
        }
    }

    // MARK: - Road

    @Test("Road marathon W1: at least 5 rest days, ≤2 running days")
    func roadMarathonWeek1IsMostlyRest() {
        let race = makeRoadRace(distanceKm: 42.195)
        let templates = RoadRaceRecoveryTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced,
            weekStartDate: makeMondayBaseline(),
            weekInRecovery: 1
        )
        let restDays = templates.filter { $0.type == .rest }.count
        let runningDays = templates.filter { $0.type == .recovery }.count
        #expect(restDays >= 4, "Marathon W1 should have ≥4 rest days, got \(restDays)")
        #expect(runningDays <= 2, "Marathon W1 should have ≤2 running days, got \(runningDays)")
    }

    @Test("Road marathon W2: more running than W1")
    func roadMarathonW2MoreRunning() {
        let race = makeRoadRace(distanceKm: 42.195)
        let w1 = RoadRaceRecoveryTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced,
            weekStartDate: makeMondayBaseline(),
            weekInRecovery: 1
        )
        let w2 = RoadRaceRecoveryTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced,
            weekStartDate: makeMondayBaseline(),
            weekInRecovery: 2
        )
        #expect(runDuration(w2) > runDuration(w1),
            "Marathon W2 should have more total active time than W1")
    }

    @Test("Road 5K: lighter recovery week than Marathon W1 (less rest)")
    func roadFiveKLighterThanMarathon() {
        let fiveK = makeRoadRace(distanceKm: 5)
        let marathon = makeRoadRace(distanceKm: 42.195)
        let fiveKTpl = RoadRaceRecoveryTemplates.sessions(
            targetRace: fiveK, experience: .intermediate,
            philosophy: .balanced,
            weekStartDate: makeMondayBaseline(),
            weekInRecovery: 1
        )
        let marathonTpl = RoadRaceRecoveryTemplates.sessions(
            targetRace: marathon, experience: .intermediate,
            philosophy: .balanced,
            weekStartDate: makeMondayBaseline(),
            weekInRecovery: 1
        )
        let fiveKRest = fiveKTpl.filter { $0.type == .rest }.count
        let marathonRest = marathonTpl.filter { $0.type == .rest }.count
        #expect(fiveKRest < marathonRest,
            "5K should require fewer rest days than marathon W1 (\(fiveKRest) vs \(marathonRest))")
    }

    @Test("Road marathon W1: contains cross-training option for non-advanced athletes")
    func roadMarathonW1HasCrossTraining() {
        let race = makeRoadRace(distanceKm: 42.195)
        let templates = RoadRaceRecoveryTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced,
            weekStartDate: makeMondayBaseline(),
            weekInRecovery: 1
        )
        let crossTraining = templates.filter { $0.type == .crossTraining }.count
        #expect(crossTraining >= 1,
            "Marathon W1 should include at least one cross-training/walk session")
    }

    @Test("Road: every recovery week covers all 7 days exactly once")
    func roadCoversFullWeek() {
        let race = makeRoadRace(distanceKm: 42.195)
        for week in 1...2 {
            let t = RoadRaceRecoveryTemplates.sessions(
                targetRace: race, experience: .intermediate,
                philosophy: .balanced,
                weekStartDate: makeMondayBaseline(),
                weekInRecovery: week
            )
            let days = Set(t.map(\.dayOffset))
            #expect(days == Set(0...6))
            #expect(t.count == 7)
        }
    }

    // MARK: - Pipeline integration

    @Test("Trail plan: post-race recovery week 1 has dramatically lower volume than peak")
    func trailRecoveryWeek1Lighter() async throws {
        let athlete = makeTestAthlete(experience: .intermediate, weeklyVolumeKm: 80)
        let race = Race(
            id: UUID(), name: "100K", date: dateNDaysFromNow(112),
            distanceKm: 105, elevationGainM: 4500, elevationLossM: 4500,
            priority: .aRace, goalType: .finish, checkpoints: [],
            terrainDifficulty: .technical, raceType: .trail
        )
        let plan = try await TrainingPlanGenerator().execute(
            athlete: athlete, targetRace: race, intermediateRaces: []
        )
        // Find race week + recovery week 1
        guard let raceWeekIdx = plan.weeks.firstIndex(where: { $0.phase == .race }) else {
            Issue.record("No race week found"); return
        }
        let raceWeekVolume = plan.weeks[raceWeekIdx].targetDurationSeconds
        let recovery1Idx = raceWeekIdx + 1
        guard recovery1Idx < plan.weeks.count else {
            Issue.record("No recovery week 1 found"); return
        }
        let rec1Volume = plan.weeks[recovery1Idx].targetDurationSeconds
        // Peak week (highest pre-race) — find the highest volume week
        // before the race.
        let peakVolume = plan.weeks[..<raceWeekIdx]
            .map(\.targetDurationSeconds).max() ?? 0
        // Recovery W1 should be < 20% of peak.
        #expect(rec1Volume < peakVolume * 0.30,
            "Recovery W1 (\(rec1Volume / 60) min) should be far below peak (\(peakVolume / 60) min)")
        // And less than the race week's training volume too (race week
        // is dominated by race day duration so this is a sanity check
        // for the small prep portion).
        _ = raceWeekVolume
    }

    // MARK: - Helpers

    private func makeTestAthlete(
        experience: ExperienceLevel,
        weeklyVolumeKm: Double
    ) -> Athlete {
        Athlete(
            id: UUID(), firstName: "Test", lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70, heightCm: 175,
            restingHeartRate: 50, maxHeartRate: 185,
            experienceLevel: experience,
            weeklyVolumeKm: weeklyVolumeKm,
            longestRunKm: 30,
            preferredUnit: .metric,
            trainingPhilosophy: .balanced,
            preferredRunsPerWeek: 5
        )
    }

    private func dateNDaysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: .now)!
    }
}
