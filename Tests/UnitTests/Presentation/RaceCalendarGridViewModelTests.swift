import Foundation
import Testing
@testable import UltraTrain

@Suite("RaceCalendarGridViewModel Tests")
@MainActor
struct RaceCalendarGridViewModelTests {

    private func makeRace(
        id: UUID = UUID(),
        name: String = "Test Race",
        date: Date = .now.adding(days: 30),
        priority: RacePriority = .aRace
    ) -> Race {
        Race(
            id: id,
            name: name,
            date: date,
            distanceKm: 80,
            elevationGainM: 4000,
            elevationLossM: 4000,
            priority: priority,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
        )
    }

    private func makePlan(
        weekStart: Date = .now.startOfWeek,
        phase: TrainingPhase = .build,
        sessionDate: Date = .now
    ) -> TrainingPlan {
        let session = TrainingSession(
            id: UUID(),
            date: sessionDate,
            type: .longRun,
            plannedDistanceKm: 25,
            plannedElevationGainM: 800,
            plannedDuration: 7200,
            intensity: .moderate,
            description: "Long run",
            nutritionNotes: nil,
            isCompleted: false,
            isSkipped: false,
            linkedRunId: nil
        )
        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: weekStart,
            endDate: weekStart.adding(days: 6),
            phase: phase,
            sessions: [session],
            isRecoveryWeek: false,
            targetVolumeKm: 60,
            targetElevationGainM: 1500
        )
        return TrainingPlan(
            id: UUID(),
            athleteId: UUID(),
            targetRaceId: UUID(),
            createdAt: .now,
            weeks: [week],
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
    }

    @Test("load populates races and plan")
    func loadPopulatesData() async {
        let raceRepo = MockRaceRepository()
        let planRepo = MockTrainingPlanRepository()
        let race = makeRace()
        raceRepo.races = [race]
        planRepo.activePlan = makePlan()

        let vm = RaceCalendarGridViewModel(
            raceRepository: raceRepo,
            planRepository: planRepo
        )

        await vm.load()

        #expect(vm.races.count == 1)
        #expect(vm.plan != nil)
        #expect(!vm.isLoading)
    }

    @Test("load handles error")
    func loadHandlesError() async {
        let raceRepo = MockRaceRepository()
        raceRepo.shouldThrow = true
        let planRepo = MockTrainingPlanRepository()

        let vm = RaceCalendarGridViewModel(
            raceRepository: raceRepo,
            planRepository: planRepo
        )

        await vm.load()

        #expect(vm.error != nil)
    }

    @Test("addRace saves and updates state")
    func addRaceSaves() async {
        let raceRepo = MockRaceRepository()
        let planRepo = MockTrainingPlanRepository()
        let vm = RaceCalendarGridViewModel(
            raceRepository: raceRepo,
            planRepository: planRepo
        )

        let race = makeRace()
        await vm.addRace(race)

        #expect(vm.races.count == 1)
        #expect(raceRepo.savedRace?.id == race.id)
    }

    @Test("deleteRace removes from state")
    func deleteRaceRemoves() async {
        let raceRepo = MockRaceRepository()
        let planRepo = MockTrainingPlanRepository()
        let race = makeRace()
        raceRepo.races = [race]

        let vm = RaceCalendarGridViewModel(
            raceRepository: raceRepo,
            planRepository: planRepo
        )
        await vm.load()

        await vm.deleteRace(id: race.id)

        #expect(vm.races.isEmpty)
    }

    @Test("phaseForDate returns correct phase")
    func phaseForDateReturnsPhase() async {
        let raceRepo = MockRaceRepository()
        let planRepo = MockTrainingPlanRepository()
        let weekStart = Date.now.startOfWeek
        planRepo.activePlan = makePlan(weekStart: weekStart, phase: .build)

        let vm = RaceCalendarGridViewModel(
            raceRepository: raceRepo,
            planRepository: planRepo
        )
        await vm.load()

        let midWeek = weekStart.adding(days: 3)
        let phase = vm.phaseForDate(midWeek)
        #expect(phase == .build)
    }

    @Test("phaseForDate returns nil outside plan")
    func phaseForDateReturnsNil() async {
        let raceRepo = MockRaceRepository()
        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = makePlan()

        let vm = RaceCalendarGridViewModel(
            raceRepository: raceRepo,
            planRepository: planRepo
        )
        await vm.load()

        let farFuture = Date.now.adding(days: 365)
        let phase = vm.phaseForDate(farFuture)
        #expect(phase == nil)
    }

    @Test("raceForDate returns matching race")
    func raceForDateReturns() async {
        let raceRepo = MockRaceRepository()
        let planRepo = MockTrainingPlanRepository()
        let raceDate = Date.now.adding(days: 30)
        let race = makeRace(date: raceDate)
        raceRepo.races = [race]

        let vm = RaceCalendarGridViewModel(
            raceRepository: raceRepo,
            planRepository: planRepo
        )
        await vm.load()

        let found = vm.raceForDate(raceDate)
        #expect(found?.id == race.id)
    }

    @Test("sessionsForDate returns matching sessions")
    func sessionsForDateReturns() async {
        let raceRepo = MockRaceRepository()
        let planRepo = MockTrainingPlanRepository()
        let today = Date.now
        planRepo.activePlan = makePlan(
            weekStart: today.startOfWeek,
            sessionDate: today
        )

        let vm = RaceCalendarGridViewModel(
            raceRepository: raceRepo,
            planRepository: planRepo
        )
        await vm.load()

        let sessions = vm.sessionsForDate(today)
        #expect(sessions.count == 1)
    }

    @Test("upcomingRaces sorted and filters past")
    func upcomingRacesSorted() async {
        let raceRepo = MockRaceRepository()
        let planRepo = MockTrainingPlanRepository()
        let pastRace = makeRace(name: "Past", date: .now.adding(days: -10))
        let soonRace = makeRace(name: "Soon", date: .now.adding(days: 10))
        let laterRace = makeRace(name: "Later", date: .now.adding(days: 60))
        raceRepo.races = [laterRace, pastRace, soonRace]

        let vm = RaceCalendarGridViewModel(
            raceRepository: raceRepo,
            planRepository: planRepo
        )
        await vm.load()

        let upcoming = vm.upcomingRaces
        #expect(upcoming.count == 2)
        #expect(upcoming.first?.name == "Soon")
        #expect(upcoming.last?.name == "Later")
    }

    @Test("daysInMonth has correct leading blanks")
    func daysInMonthLeadingBlanks() {
        let raceRepo = MockRaceRepository()
        let planRepo = MockTrainingPlanRepository()
        let vm = RaceCalendarGridViewModel(
            raceRepository: raceRepo,
            planRepository: planRepo
        )

        // February 2026 starts on Sunday (weekdayIndex 0) → 0 leading blanks
        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 1
        let feb2026 = Calendar.current.date(from: components)!

        let days = vm.daysInMonth(for: feb2026)
        let nilCount = days.prefix(while: { $0 == nil }).count
        #expect(nilCount == feb2026.startOfMonth.weekdayIndex)
        let nonNilCount = days.compactMap({ $0 }).count
        #expect(nonNilCount == 28)
    }
}
