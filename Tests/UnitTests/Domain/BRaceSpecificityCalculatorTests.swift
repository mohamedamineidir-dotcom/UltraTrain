import Foundation
import Testing
@testable import UltraTrain

@Suite("BRaceSpecificityCalculator")
struct BRaceSpecificityCalculatorTests {

    // MARK: - Helpers

    private func makeAthlete(
        experience: ExperienceLevel = .intermediate,
        philosophy: TrainingPhilosophy = .balanced
    ) -> Athlete {
        Athlete(
            id: UUID(), firstName: "Test", lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70, heightCm: 175,
            restingHeartRate: 50, maxHeartRate: 185,
            experienceLevel: experience,
            weeklyVolumeKm: 60, longestRunKm: 30,
            preferredUnit: .metric,
            trainingPhilosophy: philosophy,
            preferredRunsPerWeek: 5
        )
    }

    /// Shared baseline so race dates and skeleton dates share the
    /// same time reference. Without this, microsecond drift between
    /// `Date.now` calls can push a race's date a fraction past the
    /// containing skeleton week's endDate, breaking the lookup.
    private let anchor: Date = {
        let cal = Calendar.current
        return cal.date(from: DateComponents(year: 2026, month: 6, day: 1))!
    }()

    private func makeARace(weeksFromNow: Int = 16) -> Race {
        Race(
            id: UUID(), name: "UTMB",
            date: dateNWeeks(weeksFromNow),
            distanceKm: 170, elevationGainM: 10000, elevationLossM: 10000,
            priority: .aRace, goalType: .finish, checkpoints: [],
            terrainDifficulty: .technical, raceType: .trail
        )
    }

    private func makeBRace(
        weeksFromNow: Int,
        distanceKm: Double,
        goalSeconds: TimeInterval = 5400,
        priority: RacePriority = .bRace,
        raceType: RaceType = .road,
        includesSpecificPrep: Bool = true
    ) -> Race {
        var r = Race(
            id: UUID(), name: "B-race \(distanceKm)K",
            date: dateNWeeks(weeksFromNow),
            distanceKm: distanceKm, elevationGainM: 0, elevationLossM: 0,
            priority: priority,
            goalType: .targetTime(goalSeconds),
            checkpoints: [], terrainDifficulty: .easy,
            raceType: raceType
        )
        r.includesSpecificPrep = includesSpecificPrep
        return r
    }

    private func dateNWeeks(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: n * 7, to: anchor)!
    }

    private func makeSkeletons(weeks: Int, raceWeekDate: Date) -> [WeekSkeletonBuilder.WeekSkeleton] {
        (0..<weeks).map { i in
            let phase: TrainingPhase
            if i < Int(Double(weeks) * 0.4) { phase = .base }
            else if i < Int(Double(weeks) * 0.7) { phase = .build }
            else if i < weeks - 2 { phase = .peak }
            else { phase = .taper }
            let isRecovery = (i + 1) % 4 == 0 && phase != .taper
            let start = Calendar.current.date(byAdding: .day, value: i * 7, to: anchor)!
            let end = Calendar.current.date(byAdding: .day, value: i * 7 + 6, to: anchor)!
            return WeekSkeletonBuilder.WeekSkeleton(
                weekNumber: i + 1,
                startDate: start,
                endDate: end,
                phase: phase,
                isRecoveryWeek: isRecovery,
                phaseFocus: phase.defaultFocus
            )
        }
    }

    // MARK: - Eligibility

    @Test("Skips races without opt-in")
    func skipsNonOptedIn() {
        let athlete = makeAthlete()
        let aRace = makeARace()
        let bRace = makeBRace(
            weeksFromNow: 8, distanceKm: 21.1, includesSpecificPrep: false
        )
        let skeletons = makeSkeletons(weeks: 16, raceWeekDate: aRace.date)
        let injections = BRaceSpecificityCalculator.injections(
            skeletons: skeletons, intermediateRaces: [bRace],
            targetRace: aRace, athlete: athlete
        )
        #expect(injections.isEmpty)
    }

    @Test("Skips trail/ultra B-races even with opt-in")
    func skipsUltraBRaces() {
        let athlete = makeAthlete()
        let aRace = makeARace()
        let bRace = makeBRace(
            weeksFromNow: 8, distanceKm: 50,
            raceType: .trail, includesSpecificPrep: true
        )
        let skeletons = makeSkeletons(weeks: 16, raceWeekDate: aRace.date)
        let injections = BRaceSpecificityCalculator.injections(
            skeletons: skeletons, intermediateRaces: [bRace],
            targetRace: aRace, athlete: athlete
        )
        #expect(injections.isEmpty,
            "Trail B-races shouldn't get road specificity even with opt-in")
    }

    @Test("Skips B-races without targetTime goal")
    func skipsFinishGoal() {
        let athlete = makeAthlete()
        let aRace = makeARace()
        var bRace = makeBRace(weeksFromNow: 8, distanceKm: 21.1)
        bRace.goalType = .finish
        let skeletons = makeSkeletons(weeks: 16, raceWeekDate: aRace.date)
        let injections = BRaceSpecificityCalculator.injections(
            skeletons: skeletons, intermediateRaces: [bRace],
            targetRace: aRace, athlete: athlete
        )
        #expect(injections.isEmpty)
    }

    @Test("Skips when A-race is road (road plans handle specifics already)")
    func skipsRoadAraces() {
        let athlete = makeAthlete()
        var aRace = makeARace()
        aRace.raceType = .road
        let bRace = makeBRace(weeksFromNow: 8, distanceKm: 10, goalSeconds: 2400)
        let skeletons = makeSkeletons(weeks: 16, raceWeekDate: aRace.date)
        let injections = BRaceSpecificityCalculator.injections(
            skeletons: skeletons, intermediateRaces: [bRace],
            targetRace: aRace, athlete: athlete
        )
        #expect(injections.isEmpty)
    }

    // MARK: - Distance-class scaling

    @Test("HM B-race produces 3 injections (full prescription)")
    func halfMarathonInjections() {
        let athlete = makeAthlete()
        let aRace = makeARace(weeksFromNow: 16)
        let bRace = makeBRace(weeksFromNow: 8, distanceKm: 21.1, goalSeconds: 5400)
        let skeletons = makeSkeletons(weeks: 16, raceWeekDate: aRace.date)
        let injections = BRaceSpecificityCalculator.injections(
            skeletons: skeletons, intermediateRaces: [bRace],
            targetRace: aRace, athlete: athlete
        )
        #expect(injections.count == 3,
            "HM with full prescription should have 3 injections, got \(injections.count)")
    }

    @Test("10K B-race produces 2 injections")
    func tenKInjections() {
        let athlete = makeAthlete()
        let aRace = makeARace(weeksFromNow: 16)
        let bRace = makeBRace(weeksFromNow: 8, distanceKm: 10, goalSeconds: 2400)
        let skeletons = makeSkeletons(weeks: 16, raceWeekDate: aRace.date)
        let injections = BRaceSpecificityCalculator.injections(
            skeletons: skeletons, intermediateRaces: [bRace],
            targetRace: aRace, athlete: athlete
        )
        #expect(injections.count == 2)
    }

    @Test("C-race gets half prescription")
    func cRaceHalfPrescription() {
        let athlete = makeAthlete()
        let aRace = makeARace(weeksFromNow: 16)
        let bRace = makeBRace(
            weeksFromNow: 8, distanceKm: 21.1,
            goalSeconds: 5400, priority: .cRace
        )
        let skeletons = makeSkeletons(weeks: 16, raceWeekDate: aRace.date)
        let injections = BRaceSpecificityCalculator.injections(
            skeletons: skeletons, intermediateRaces: [bRace],
            targetRace: aRace, athlete: athlete
        )
        #expect(injections.count <= 2,
            "C-race HM should get reduced prescription, got \(injections.count)")
    }

    // MARK: - Gap modifiers

    @Test("Gap-to-A-race < 4 weeks: only 1 injection")
    func closeBRaceReducedInjections() {
        let athlete = makeAthlete()
        let aRace = makeARace(weeksFromNow: 12)
        // B-race at week 9 (3 weeks before A-race) — well within build phase
        let bRace = makeBRace(weeksFromNow: 9, distanceKm: 21.1, goalSeconds: 5400)
        let skeletons = makeSkeletons(weeks: 12, raceWeekDate: aRace.date)
        let injections = BRaceSpecificityCalculator.injections(
            skeletons: skeletons, intermediateRaces: [bRace],
            targetRace: aRace, athlete: athlete
        )
        // Within 4 weeks of A-race → 1 injection only
        #expect(injections.count <= 1,
            "Close B-race should have ≤1 injection, got \(injections.count)")
    }

    @Test("Beginner athlete gets 1 less injection")
    func beginnerReducedPrescription() {
        let aRace = makeARace(weeksFromNow: 16)
        let bRace = makeBRace(weeksFromNow: 8, distanceKm: 21.1, goalSeconds: 5400)
        let skeletons = makeSkeletons(weeks: 16, raceWeekDate: aRace.date)
        let beginner = makeAthlete(experience: .beginner)
        let intermediate = makeAthlete(experience: .intermediate)
        let bI = BRaceSpecificityCalculator.injections(
            skeletons: skeletons, intermediateRaces: [bRace],
            targetRace: aRace, athlete: beginner
        )
        let iI = BRaceSpecificityCalculator.injections(
            skeletons: skeletons, intermediateRaces: [bRace],
            targetRace: aRace, athlete: intermediate
        )
        #expect(bI.count < iI.count,
            "Beginner should have fewer injections (\(bI.count)) than intermediate (\(iI.count))")
    }

    @Test("Enjoyment philosophy gets 1 less injection")
    func enjoymentReducedPrescription() {
        let aRace = makeARace(weeksFromNow: 16)
        let bRace = makeBRace(weeksFromNow: 8, distanceKm: 21.1, goalSeconds: 5400)
        let skeletons = makeSkeletons(weeks: 16, raceWeekDate: aRace.date)
        let enjoy = makeAthlete(philosophy: .enjoyment)
        let balanced = makeAthlete(philosophy: .balanced)
        let eI = BRaceSpecificityCalculator.injections(
            skeletons: skeletons, intermediateRaces: [bRace],
            targetRace: aRace, athlete: enjoy
        )
        let bI = BRaceSpecificityCalculator.injections(
            skeletons: skeletons, intermediateRaces: [bRace],
            targetRace: aRace, athlete: balanced
        )
        #expect(eI.count < bI.count)
    }

    @Test("Injection weeks are in W-2/W-3/W-4 of B-race (not in mini-taper)")
    func injectionWeekPlacement() {
        let athlete = makeAthlete()
        let aRace = makeARace(weeksFromNow: 16)
        let bRace = makeBRace(weeksFromNow: 8, distanceKm: 21.1, goalSeconds: 5400)
        let skeletons = makeSkeletons(weeks: 16, raceWeekDate: aRace.date)
        let injections = BRaceSpecificityCalculator.injections(
            skeletons: skeletons, intermediateRaces: [bRace],
            targetRace: aRace, athlete: athlete
        )
        // B-race lands at week 9 (weeksFromNow:8 with anchor → 9th
        // skeleton week). Mini-taper = week 8. Injections at 7, 6, 5
        // (W-2, W-3, W-4).
        for inj in injections {
            #expect(inj.weekNumber <= 7,
                "Injection should be ≥2 weeks before B-race (mini-taper), got week \(inj.weekNumber)")
            #expect(inj.weekNumber >= 5,
                "Injection should not be too early (>4 weeks back), got week \(inj.weekNumber)")
        }
    }

    // MARK: - Variant kind

    @Test("HM injection W-2 uses interval slot, W-3 uses tempo slot")
    func halfMarathonSlotPlacement() {
        let athlete = makeAthlete()
        let aRace = makeARace(weeksFromNow: 16)
        let bRace = makeBRace(weeksFromNow: 8, distanceKm: 21.1, goalSeconds: 5400)
        let skeletons = makeSkeletons(weeks: 16, raceWeekDate: aRace.date)
        let injections = BRaceSpecificityCalculator.injections(
            skeletons: skeletons, intermediateRaces: [bRace],
            targetRace: aRace, athlete: athlete
        )
        // Find the W-2 and W-3 injections (count = 3 → W-4, W-3, W-2)
        let bRaceWeek = injections.first?.weekNumber.advanced(by: 0) ?? 8
        // Sort by week number; the closest to B-race is W-2.
        let sorted = injections.sorted { $0.weekNumber > $1.weekNumber }
        if sorted.count >= 2 {
            let wm2 = sorted[0]  // closest = W-2
            let wm3 = sorted[1]  // W-3
            #expect(wm2.slot == .intervals, "W-2 should be intervals (HMP-paced repeats)")
            #expect(wm3.slot == .tempo, "W-3 should be tempo (longer threshold)")
        }
        _ = bRaceWeek  // silence unused
    }

    @Test("Marathon B-race uses longRun slot for MP blocks")
    func marathonLongRunSlot() {
        let athlete = makeAthlete()
        let aRace = makeARace(weeksFromNow: 18)
        let bRace = makeBRace(weeksFromNow: 10, distanceKm: 42.195, goalSeconds: 13500)
        let skeletons = makeSkeletons(weeks: 18, raceWeekDate: aRace.date)
        let injections = BRaceSpecificityCalculator.injections(
            skeletons: skeletons, intermediateRaces: [bRace],
            targetRace: aRace, athlete: athlete
        )
        let hasLongRunMP = injections.contains {
            $0.slot == .longRun && $0.kind == .marathonPaceLongRun
        }
        #expect(hasLongRunMP,
            "Marathon B-race should include a MP-block long run injection")
    }
}
