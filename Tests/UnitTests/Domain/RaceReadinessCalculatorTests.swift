import Foundation
import Testing
@testable import UltraTrain

@Suite("Race Readiness Calculator Tests")
struct RaceReadinessCalculatorTests {

    // MARK: - Helpers

    private func makeRace(daysFromNow: Int, name: String = "UTMB") -> Race {
        Race(
            id: UUID(),
            name: name,
            date: Date.now.adding(days: daysFromNow),
            distanceKm: 171,
            elevationGainM: 10000,
            elevationLossM: 10000,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .technical
        )
    }

    private func makeWeeks(count: Int, startDaysFromNow: Int) -> [TrainingWeek] {
        (0..<count).map { i in
            let start = Date.now.adding(days: startDaysFromNow + i * 7)
            let phase: TrainingPhase = i < count - 2 ? .build : .taper
            return TrainingWeek(
                id: UUID(),
                weekNumber: i + 1,
                startDate: start,
                endDate: start.adding(days: 6),
                phase: phase,
                sessions: [],
                isRecoveryWeek: false,
                targetVolumeKm: phase == .taper ? 30 : 60,
                targetElevationGainM: phase == .taper ? 500 : 1500
            )
        }
    }

    // MARK: - Tests

    @Test("Race in past returns nil")
    func raceInPast() {
        let race = makeRace(daysFromNow: -7)
        let result = RaceReadinessCalculator.forecast(
            currentFitness: 50,
            currentFatigue: 40,
            plannedWeeks: makeWeeks(count: 4, startDaysFromNow: -28),
            race: race
        )
        #expect(result == nil)
    }

    @Test("Future race produces forecast with projection points")
    func futureRace() {
        let race = makeRace(daysFromNow: 42)
        let weeks = makeWeeks(count: 6, startDaysFromNow: 0)
        let result = RaceReadinessCalculator.forecast(
            currentFitness: 50,
            currentFatigue: 40,
            plannedWeeks: weeks,
            race: race
        )

        #expect(result != nil)
        #expect(result!.raceName == "UTMB")
        #expect(result!.daysUntilRace >= 41 && result!.daysUntilRace <= 42)
        #expect(!result!.fitnessProjectionPoints.isEmpty)
        #expect(result!.projectedFitnessAtRace > 0)
    }

    @Test("Days until race is calculated correctly")
    func daysUntilRace() {
        let race = makeRace(daysFromNow: 30)
        let result = RaceReadinessCalculator.forecast(
            currentFitness: 50,
            currentFatigue: 40,
            plannedWeeks: makeWeeks(count: 4, startDaysFromNow: 0),
            race: race
        )

        #expect(result!.daysUntilRace >= 29 && result!.daysUntilRace <= 30)
    }

    @Test("Taper phase improves projected form")
    func taperImprovesForm() {
        let race = makeRace(daysFromNow: 21)
        let weeks = [
            TrainingWeek(
                id: UUID(), weekNumber: 1,
                startDate: Date.now, endDate: Date.now.adding(days: 6),
                phase: .taper, sessions: [], isRecoveryWeek: false,
                targetVolumeKm: 20, targetElevationGainM: 300
            ),
            TrainingWeek(
                id: UUID(), weekNumber: 2,
                startDate: Date.now.adding(days: 7), endDate: Date.now.adding(days: 13),
                phase: .taper, sessions: [], isRecoveryWeek: false,
                targetVolumeKm: 15, targetElevationGainM: 200
            ),
            TrainingWeek(
                id: UUID(), weekNumber: 3,
                startDate: Date.now.adding(days: 14), endDate: Date.now.adding(days: 20),
                phase: .taper, sessions: [], isRecoveryWeek: false,
                targetVolumeKm: 10, targetElevationGainM: 100
            ),
        ]

        let result = RaceReadinessCalculator.forecast(
            currentFitness: 60,
            currentFatigue: 55,
            plannedWeeks: weeks,
            race: race
        )

        #expect(result != nil)
        #expect(result!.projectedFormAtRace > (60 - 55))
    }

    @Test("Form status classified correctly")
    func formStatusClassification() {
        let race = makeRace(daysFromNow: 14)
        let weeks = [
            TrainingWeek(
                id: UUID(), weekNumber: 1,
                startDate: Date.now, endDate: Date.now.adding(days: 6),
                phase: .taper, sessions: [], isRecoveryWeek: false,
                targetVolumeKm: 10, targetElevationGainM: 100
            ),
            TrainingWeek(
                id: UUID(), weekNumber: 2,
                startDate: Date.now.adding(days: 7), endDate: Date.now.adding(days: 13),
                phase: .taper, sessions: [], isRecoveryWeek: false,
                targetVolumeKm: 5, targetElevationGainM: 50
            ),
        ]

        let result = RaceReadinessCalculator.forecast(
            currentFitness: 60,
            currentFatigue: 50,
            plannedWeeks: weeks,
            race: race
        )

        #expect(result != nil)
        let status = result!.projectedFormStatus
        #expect(status == .fresh || status == .raceReady || status == .building)
    }
}
