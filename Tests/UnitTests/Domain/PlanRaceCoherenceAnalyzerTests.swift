import Foundation
import Testing
@testable import UltraTrain

@Suite("PlanRaceCoherenceAnalyzer Tests")
struct PlanRaceCoherenceAnalyzerTests {

    // MARK: - The headline case

    @Test("CCC 5 weeks before Marathon de Lyon — fires bRaceMismatch")
    func cccBeforeMarathonFires() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let marathonLyon = makeRace(
            name: "Marathon de Lyon",
            distanceKm: 42, elevationGainM: 50,
            daysFromNow: 100, priority: .aRace, now: now
        )
        let ccc = makeRace(
            name: "CCC",
            distanceKm: 101, elevationGainM: 6050,
            daysFromNow: 65, priority: .bRace, now: now
        )
        let recs = PlanRaceCoherenceAnalyzer.detectIntermediateRaceMismatch(
            targetRace: marathonLyon,
            intermediateRaces: [ccc],
            now: now
        )
        #expect(recs.count == 1)
        #expect(recs.first?.type == .bRaceMismatch)
        #expect(recs.first?.severity == .recommended)
        #expect(recs.first?.message.contains("CCC") == true)
        #expect(recs.first?.message.contains("Marathon de Lyon") == true)
    }

    // MARK: - Threshold non-trips

    @Test("HM B-race before marathon — same-discipline normal prep, no flag")
    func hmBeforeMarathonNoFlag() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let marathon = makeRace(
            name: "Marathon",
            distanceKm: 42, elevationGainM: 50,
            daysFromNow: 60, priority: .aRace, now: now
        )
        let hm = makeRace(
            name: "Half Marathon",
            distanceKm: 21.1, elevationGainM: 30,
            daysFromNow: 30, priority: .bRace, now: now
        )
        let recs = PlanRaceCoherenceAnalyzer.detectIntermediateRaceMismatch(
            targetRace: marathon,
            intermediateRaces: [hm],
            now: now
        )
        #expect(recs.isEmpty)
    }

    @Test("Bigger B-race far enough out — no flag")
    func biggerBRaceFarEnoughOut() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let marathon = makeRace(
            name: "Marathon",
            distanceKm: 42, elevationGainM: 50,
            daysFromNow: 200, priority: .aRace, now: now
        )
        // 100K ultra 12 weeks (84 days) before A-race — enough recovery time
        let ultra = makeRace(
            name: "Big Ultra",
            distanceKm: 100, elevationGainM: 5000,
            daysFromNow: 116, priority: .bRace, now: now
        )
        let recs = PlanRaceCoherenceAnalyzer.detectIntermediateRaceMismatch(
            targetRace: marathon,
            intermediateRaces: [ultra],
            now: now
        )
        #expect(recs.isEmpty)
    }

    @Test("Same-size B-race close to A — no flag (only mismatch matters)")
    func sameSizeNoFlag() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let m1 = makeRace(
            name: "M1",
            distanceKm: 42, elevationGainM: 50,
            daysFromNow: 60, priority: .aRace, now: now
        )
        let m2 = makeRace(
            name: "M2",
            distanceKm: 42, elevationGainM: 50,
            daysFromNow: 30, priority: .bRace, now: now
        )
        let recs = PlanRaceCoherenceAnalyzer.detectIntermediateRaceMismatch(
            targetRace: m1,
            intermediateRaces: [m2],
            now: now
        )
        #expect(recs.isEmpty)
    }

    // MARK: - C-race / past-race / multi exclusion

    @Test("C-race is skipped (training races are accepted hard efforts)")
    func cRaceSkipped() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let marathon = makeRace(
            name: "Marathon",
            distanceKm: 42, elevationGainM: 50,
            daysFromNow: 60, priority: .aRace, now: now
        )
        let trainingUltra = makeRace(
            name: "Training Ultra",
            distanceKm: 100, elevationGainM: 5000,
            daysFromNow: 30, priority: .cRace, now: now
        )
        let recs = PlanRaceCoherenceAnalyzer.detectIntermediateRaceMismatch(
            targetRace: marathon,
            intermediateRaces: [trainingUltra],
            now: now
        )
        #expect(recs.isEmpty)
    }

    @Test("Past races are skipped")
    func pastRacesSkipped() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let marathon = makeRace(
            name: "Marathon",
            distanceKm: 42, elevationGainM: 50,
            daysFromNow: 60, priority: .aRace, now: now
        )
        let pastUltra = makeRace(
            name: "Past Ultra",
            distanceKm: 100, elevationGainM: 5000,
            daysFromNow: -30, priority: .bRace, now: now
        )
        let recs = PlanRaceCoherenceAnalyzer.detectIntermediateRaceMismatch(
            targetRace: marathon,
            intermediateRaces: [pastUltra],
            now: now
        )
        #expect(recs.isEmpty)
    }

    @Test("Multiple matches each get their own recommendation")
    func multipleMatches() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let marathon = makeRace(
            name: "Marathon",
            distanceKm: 42, elevationGainM: 50,
            daysFromNow: 100, priority: .aRace, now: now
        )
        let ultra1 = makeRace(
            name: "Ultra1",
            distanceKm: 80, elevationGainM: 4000,
            daysFromNow: 70, priority: .bRace, now: now
        )
        let ultra2 = makeRace(
            name: "Ultra2",
            distanceKm: 100, elevationGainM: 5000,
            daysFromNow: 60, priority: .bRace, now: now
        )
        let recs = PlanRaceCoherenceAnalyzer.detectIntermediateRaceMismatch(
            targetRace: marathon,
            intermediateRaces: [ultra1, ultra2],
            now: now
        )
        #expect(recs.count == 2)
    }

    // MARK: - Helper

    private func makeRace(
        name: String,
        distanceKm: Double,
        elevationGainM: Double,
        daysFromNow: Int,
        priority: RacePriority,
        now: Date
    ) -> Race {
        let date = Calendar.current.date(byAdding: .day, value: daysFromNow, to: now)!
        return Race(
            id: UUID(),
            name: name,
            date: date,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: elevationGainM,
            priority: priority,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
        )
    }
}
