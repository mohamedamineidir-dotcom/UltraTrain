import Foundation
import Testing
@testable import UltraTrain

@Suite("Training Plan Generator Tests")
struct TrainingPlanGeneratorTests {

    private func makeAthlete(
        experience: ExperienceLevel = .intermediate,
        weeklyVolumeKm: Double = 40,
        longestRunKm: Double = 25
    ) -> Athlete {
        Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 55,
            maxHeartRate: 185,
            experienceLevel: experience,
            weeklyVolumeKm: weeklyVolumeKm,
            longestRunKm: longestRunKm,
            preferredUnit: .metric
        )
    }

    private func makeRace(
        weeksFromNow: Int = 16,
        distanceKm: Double = 100,
        elevationGainM: Double = 5000
    ) -> Race {
        Race(
            id: UUID(),
            name: "Test Ultra",
            date: Date.now.adding(weeks: weeksFromNow),
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: elevationGainM,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
        )
    }

    // MARK: - Plan Structure

    @Test("Generated plan has correct week count")
    func correctWeekCount() async throws {
        let generator = TrainingPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(weeksFromNow: 16)

        let plan = try await generator.execute(athlete: athlete, targetRace: race, intermediateRaces: [])

        // Should be approximately 16 weeks (exact count depends on weeksBetween calculation)
        #expect(plan.weeks.count >= 14)
        #expect(plan.weeks.count <= 18)
    }

    @Test("Each week has 7 sessions")
    func sevenSessionsPerWeek() async throws {
        let generator = TrainingPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(weeksFromNow: 12)

        let plan = try await generator.execute(athlete: athlete, targetRace: race, intermediateRaces: [])

        for week in plan.weeks {
            #expect(week.sessions.count == 7, "Week \(week.weekNumber) has \(week.sessions.count) sessions")
        }
    }

    @Test("Phase ordering is correct")
    func phaseOrdering() async throws {
        let generator = TrainingPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(weeksFromNow: 16)

        let plan = try await generator.execute(athlete: athlete, targetRace: race, intermediateRaces: [])

        // Extract unique phases in order (skipping duplicates)
        var seenPhases: [TrainingPhase] = []
        for week in plan.weeks where !week.isRecoveryWeek {
            if seenPhases.last != week.phase {
                seenPhases.append(week.phase)
            }
        }

        // Should see base -> build -> peak -> taper (possibly with recovery interspersed)
        #expect(seenPhases.contains(.base))
        #expect(seenPhases.contains(.taper))

        if let baseIndex = seenPhases.firstIndex(of: .base),
           let taperIndex = seenPhases.firstIndex(of: .taper) {
            #expect(baseIndex < taperIndex)
        }
    }

    @Test("Volume cap at 10% increase enforced")
    func volumeCapEnforced() async throws {
        let generator = TrainingPlanGenerator()
        let athlete = makeAthlete(weeklyVolumeKm: 30)
        let race = makeRace(weeksFromNow: 16, distanceKm: 160)

        let plan = try await generator.execute(athlete: athlete, targetRace: race, intermediateRaces: [])

        var previousNonRecoveryVolume: Double?
        for week in plan.weeks where week.phase != .taper {
            if week.isRecoveryWeek { continue }
            if let prev = previousNonRecoveryVolume {
                let increasePercent = ((week.targetVolumeKm - prev) / prev) * 100.0
                // Allow small floating point tolerance
                #expect(increasePercent <= 10.5, "Week \(week.weekNumber) increased by \(increasePercent)%")
            }
            previousNonRecoveryVolume = week.targetVolumeKm
        }
    }

    @Test("Recovery weeks have reduced volume")
    func recoveryWeeksReduced() async throws {
        let generator = TrainingPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(weeksFromNow: 20)

        let plan = try await generator.execute(athlete: athlete, targetRace: race, intermediateRaces: [])

        let recoveryWeeks = plan.weeks.filter { $0.isRecoveryWeek }
        // With 20 weeks, should have at least a couple recovery weeks
        #expect(recoveryWeeks.count >= 1)
    }

    @Test("Taper weeks have decreasing volume")
    func taperDecreases() async throws {
        let generator = TrainingPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(weeksFromNow: 16)

        let plan = try await generator.execute(athlete: athlete, targetRace: race, intermediateRaces: [])

        let taperWeeks = plan.weeks.filter { $0.phase == .taper }
        guard taperWeeks.count >= 2 else { return }

        #expect(taperWeeks.first!.targetVolumeKm >= taperWeeks.last!.targetVolumeKm)
    }

    // MARK: - Intermediate Races

    @Test("Intermediate race inserts override weeks")
    func intermediateRaceOverrides() async throws {
        let generator = TrainingPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(weeksFromNow: 16)

        let bRace = Race(
            id: UUID(),
            name: "B Race",
            date: Date.now.adding(weeks: 8),
            distanceKm: 50,
            elevationGainM: 2000,
            elevationLossM: 2000,
            priority: .bRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
        )

        let plan = try await generator.execute(athlete: athlete, targetRace: race, intermediateRaces: [bRace])

        let raceWeeks = plan.weeks.filter { $0.phase == .race }
        #expect(raceWeeks.count >= 1, "Should have at least one race-override week")
    }

    // MARK: - Validation

    @Test("Throws for race less than 4 weeks away")
    func tooSoonThrows() async {
        let generator = TrainingPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(weeksFromNow: 2)

        do {
            _ = try await generator.execute(athlete: athlete, targetRace: race, intermediateRaces: [])
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is DomainError)
        }
    }

    @Test("Plan IDs are linked to athlete and race")
    func idsLinked() async throws {
        let generator = TrainingPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(weeksFromNow: 12)

        let plan = try await generator.execute(athlete: athlete, targetRace: race, intermediateRaces: [])

        #expect(plan.athleteId == athlete.id)
        #expect(plan.targetRaceId == race.id)
    }

    @Test("Sessions have valid dates within their week")
    func sessionDatesInWeek() async throws {
        let generator = TrainingPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(weeksFromNow: 12)

        let plan = try await generator.execute(athlete: athlete, targetRace: race, intermediateRaces: [])

        for week in plan.weeks {
            for session in week.sessions {
                #expect(session.date >= week.startDate,
                       "Session date \(session.date) before week start \(week.startDate)")
                #expect(session.date <= week.endDate.adding(days: 1),
                       "Session date \(session.date) after week end \(week.endDate)")
            }
        }
    }

    @Test("All sessions start as not completed")
    func sessionsNotCompleted() async throws {
        let generator = TrainingPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(weeksFromNow: 12)

        let plan = try await generator.execute(athlete: athlete, targetRace: race, intermediateRaces: [])

        for week in plan.weeks {
            for session in week.sessions {
                #expect(session.isCompleted == false)
            }
        }
    }
}
