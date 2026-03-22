import Foundation
import Testing
@testable import UltraTrain

@Suite("Plan Preference Reframer Tests")
struct PlanPreferenceReframerTests {

    private let reframer = PlanPreferenceReframer()
    private let calendar = Calendar.current

    // MARK: - Helpers

    private func makeAthlete(
        runsPerWeek: Int = 5,
        philosophy: TrainingPhilosophy = .balanced
    ) -> Athlete {
        Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: calendar.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 50,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 50,
            longestRunKm: 30,
            preferredUnit: .metric,
            trainingPhilosophy: philosophy,
            preferredRunsPerWeek: runsPerWeek
        )
    }

    private func makeRace(daysFromNow: Int = 70) -> Race {
        Race(
            id: UUID(),
            name: "Test Ultra",
            date: calendar.date(byAdding: .day, value: daysFromNow, to: .now)!,
            distanceKm: 50,
            elevationGainM: 3000,
            elevationLossM: 3000,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
        )
    }

    private func makeSession(
        date: Date,
        type: SessionType = .tempo,
        isCompleted: Bool = false,
        linkedRunId: UUID? = nil
    ) -> TrainingSession {
        TrainingSession(
            id: UUID(),
            date: date,
            type: type,
            plannedDistanceKm: 10,
            plannedElevationGainM: 200,
            plannedDuration: 3600,
            intensity: .moderate,
            description: "\(type.rawValue)",
            nutritionNotes: nil,
            isCompleted: isCompleted,
            isSkipped: false,
            linkedRunId: linkedRunId
        )
    }

    private func makeWeek(
        weekNumber: Int,
        startDaysFromNow: Int,
        sessions: [TrainingSession]? = nil,
        isRecoveryWeek: Bool = false,
        targetDuration: TimeInterval = 18000
    ) -> TrainingWeek {
        let start = calendar.date(byAdding: .day, value: startDaysFromNow, to: .now)!
        let end = calendar.date(byAdding: .day, value: startDaysFromNow + 6, to: .now)!
        let defaultSessions = sessions ?? [
            makeSession(date: calendar.date(byAdding: .day, value: startDaysFromNow + 1, to: .now)!),
            makeSession(date: calendar.date(byAdding: .day, value: startDaysFromNow + 3, to: .now)!, type: .longRun),
            makeSession(date: calendar.date(byAdding: .day, value: startDaysFromNow + 5, to: .now)!, type: .rest)
        ]
        return TrainingWeek(
            id: UUID(),
            weekNumber: weekNumber,
            startDate: start,
            endDate: end,
            phase: .build,
            sessions: defaultSessions,
            isRecoveryWeek: isRecoveryWeek,
            targetVolumeKm: 50,
            targetElevationGainM: 1000,
            targetDurationSeconds: targetDuration
        )
    }

    private func makePlan(weeks: [TrainingWeek], raceId: UUID) -> TrainingPlan {
        TrainingPlan(
            id: UUID(),
            athleteId: UUID(),
            targetRaceId: raceId,
            createdAt: Date.distantPast,
            weeks: weeks,
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
    }

    // MARK: - Tests

    @Test("Returns nil when no future weeks")
    func noFutureWeeksReturnsNil() async throws {
        let race = makeRace(daysFromNow: -1)
        let week = makeWeek(weekNumber: 1, startDaysFromNow: -14)
        let plan = makePlan(weeks: [week], raceId: race.id)
        let athlete = makeAthlete(runsPerWeek: 3)

        let result = try await reframer.execute(
            currentPlan: plan, updatedAthlete: athlete,
            targetRace: race, intermediateRaces: []
        )
        #expect(result == nil)
    }

    @Test("Regenerates all weeks when all are future")
    func allFutureWeeksRegenerated() async throws {
        let race = makeRace(daysFromNow: 70)
        let w1 = makeWeek(weekNumber: 1, startDaysFromNow: 1)
        let w2 = makeWeek(weekNumber: 2, startDaysFromNow: 8)
        let plan = makePlan(weeks: [w1, w2], raceId: race.id)
        let athlete = makeAthlete(runsPerWeek: 3)

        let result = try await reframer.execute(
            currentPlan: plan, updatedAthlete: athlete,
            targetRace: race, intermediateRaces: []
        )
        #expect(result != nil)
        #expect(result!.weeks.count > 0)
    }

    @Test("Past weeks preserved exactly")
    func pastWeeksPreserved() async throws {
        let race = makeRace(daysFromNow: 56)
        let runId = UUID()
        let pastSession = makeSession(
            date: calendar.date(byAdding: .day, value: -10, to: .now)!,
            type: .longRun,
            isCompleted: true,
            linkedRunId: runId
        )
        let pastWeek = makeWeek(weekNumber: 1, startDaysFromNow: -14, sessions: [pastSession])
        let futureWeek = makeWeek(weekNumber: 2, startDaysFromNow: 2)
        let plan = makePlan(weeks: [pastWeek, futureWeek], raceId: race.id)
        let athlete = makeAthlete(runsPerWeek: 3)

        let result = try await reframer.execute(
            currentPlan: plan, updatedAthlete: athlete,
            targetRace: race, intermediateRaces: []
        )
        #expect(result != nil)
        let preserved = result!.weeks.first!
        #expect(preserved.id == pastWeek.id)
        #expect(preserved.sessions.first!.isCompleted)
        #expect(preserved.sessions.first!.linkedRunId == runId)
    }

    @Test("Plan ID preserved after reframe")
    func planIdPreserved() async throws {
        let race = makeRace(daysFromNow: 56)
        let pastWeek = makeWeek(weekNumber: 1, startDaysFromNow: -14)
        let futureWeek = makeWeek(weekNumber: 2, startDaysFromNow: 2)
        let plan = makePlan(weeks: [pastWeek, futureWeek], raceId: race.id)
        let athlete = makeAthlete()

        let result = try await reframer.execute(
            currentPlan: plan, updatedAthlete: athlete,
            targetRace: race, intermediateRaces: []
        )
        #expect(result != nil)
        #expect(result!.id == plan.id)
        #expect(result!.athleteId == plan.athleteId)
        #expect(result!.targetRaceId == plan.targetRaceId)
    }

    @Test("Week numbers continue from past weeks")
    func weekNumbersContinue() async throws {
        let race = makeRace(daysFromNow: 56)
        let w1 = makeWeek(weekNumber: 1, startDaysFromNow: -21)
        let w2 = makeWeek(weekNumber: 2, startDaysFromNow: -14)
        let w3 = makeWeek(weekNumber: 3, startDaysFromNow: 2)
        let plan = makePlan(weeks: [w1, w2, w3], raceId: race.id)
        let athlete = makeAthlete()

        let result = try await reframer.execute(
            currentPlan: plan, updatedAthlete: athlete,
            targetRace: race, intermediateRaces: []
        )
        #expect(result != nil)
        // Past weeks have weekNumber 1, 2
        // Future weeks should start from 3+
        let futureWeeks = result!.weeks.dropFirst(2)
        for week in futureWeeks {
            #expect(week.weekNumber > 2)
        }
    }

    @Test("Volume bridging clamps when increase exceeds 10%")
    func volumeBridgingClampsIncrease() async throws {
        let race = makeRace(daysFromNow: 56)
        // Past week with low volume (5000s = ~83min)
        let pastWeek = makeWeek(weekNumber: 1, startDaysFromNow: -7, targetDuration: 5000)
        let futureWeek = makeWeek(weekNumber: 2, startDaysFromNow: 2)
        let plan = makePlan(weeks: [pastWeek, futureWeek], raceId: race.id)
        // Performance philosophy = higher volume, which should trigger clamping
        let athlete = makeAthlete(runsPerWeek: 6, philosophy: .performance)

        let result = try await reframer.execute(
            currentPlan: plan, updatedAthlete: athlete,
            targetRace: race, intermediateRaces: []
        )
        #expect(result != nil)
        let firstFutureWeek = result!.weeks[1]
        // First future week should not exceed anchor * 1.10
        let maxAllowed = 5000.0 * 1.10
        #expect(firstFutureWeek.targetDurationSeconds <= maxAllowed + 1)
    }

    @Test("Volume bridging clamps when decrease exceeds 10%")
    func volumeBridgingClampsDecrease() async throws {
        let race = makeRace(daysFromNow: 56)
        // Past week with high volume (25000s = ~416min)
        let pastWeek = makeWeek(weekNumber: 1, startDaysFromNow: -7, targetDuration: 25000)
        let futureWeek = makeWeek(weekNumber: 2, startDaysFromNow: 2)
        let plan = makePlan(weeks: [pastWeek, futureWeek], raceId: race.id)
        // Enjoyment philosophy + 3 runs = much lower volume
        let athlete = makeAthlete(runsPerWeek: 3, philosophy: .enjoyment)

        let result = try await reframer.execute(
            currentPlan: plan, updatedAthlete: athlete,
            targetRace: race, intermediateRaces: []
        )
        #expect(result != nil)
        let firstFutureWeek = result!.weeks[1]
        // First future week should not go below anchor * 0.90
        let minAllowed = 25000.0 * 0.90
        #expect(firstFutureWeek.targetDurationSeconds >= minAllowed - 1)
    }
}
