import Foundation
import Testing
@testable import UltraTrain

@Suite("Profile ViewModel Tests")
struct ProfileViewModelTests {

    private func makeAthlete() -> Athlete {
        Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 55,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 40,
            longestRunKm: 25,
            preferredUnit: .metric
        )
    }

    private func makeRace(
        name: String = "Test Ultra",
        date: Date? = nil,
        priority: RacePriority = .aRace
    ) -> Race {
        Race(
            id: UUID(),
            name: name,
            date: date ?? Date.now.adding(weeks: 16),
            distanceKm: 100,
            elevationGainM: 5000,
            elevationLossM: 5000,
            priority: priority,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
        )
    }

    @MainActor
    private func makeViewModel(
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        raceRepo: MockRaceRepository = MockRaceRepository()
    ) -> ProfileViewModel {
        ProfileViewModel(
            athleteRepository: athleteRepo,
            raceRepository: raceRepo
        )
    }

    // MARK: - Load

    @Test("Load fetches athlete and races")
    @MainActor
    func loadFetchesData() async {
        let athlete = makeAthlete()
        let race = makeRace()

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]

        let vm = makeViewModel(athleteRepo: athleteRepo, raceRepo: raceRepo)
        await vm.load()

        #expect(vm.athlete != nil)
        #expect(vm.athlete?.id == athlete.id)
        #expect(vm.races.count == 1)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load handles nil athlete")
    @MainActor
    func loadHandlesNilAthlete() async {
        let vm = makeViewModel()
        await vm.load()

        #expect(vm.athlete == nil)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load handles repository error")
    @MainActor
    func loadHandlesError() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.shouldThrow = true

        let vm = makeViewModel(athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.athlete == nil)
        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    // MARK: - Update Athlete

    @Test("Update athlete persists and updates state")
    @MainActor
    func updateAthlete() async {
        let athlete = makeAthlete()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete

        let vm = makeViewModel(athleteRepo: athleteRepo)
        vm.athlete = athlete

        var updated = athlete
        updated.weightKg = 75

        await vm.updateAthlete(updated)

        #expect(vm.athlete?.weightKg == 75)
        #expect(athleteRepo.savedAthlete?.weightKg == 75)
        #expect(vm.error == nil)
    }

    @Test("Update athlete handles error")
    @MainActor
    func updateAthleteError() async {
        let athlete = makeAthlete()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.shouldThrow = true

        let vm = makeViewModel(athleteRepo: athleteRepo)
        vm.athlete = athlete

        var updated = athlete
        updated.weightKg = 75

        await vm.updateAthlete(updated)

        #expect(vm.error != nil)
    }

    // MARK: - Add Race

    @Test("Add race appends to list")
    @MainActor
    func addRace() async {
        let race = makeRace(name: "New Race", priority: .bRace)
        let raceRepo = MockRaceRepository()

        let vm = makeViewModel(raceRepo: raceRepo)
        await vm.addRace(race)

        #expect(vm.races.count == 1)
        #expect(vm.races.first?.name == "New Race")
        #expect(raceRepo.savedRace?.name == "New Race")
        #expect(vm.error == nil)
    }

    @Test("Add race handles error")
    @MainActor
    func addRaceError() async {
        let race = makeRace(priority: .bRace)
        let raceRepo = MockRaceRepository()
        raceRepo.shouldThrow = true

        let vm = makeViewModel(raceRepo: raceRepo)
        await vm.addRace(race)

        #expect(vm.races.isEmpty)
        #expect(vm.error != nil)
    }

    // MARK: - Update Race

    @Test("Update race replaces in list")
    @MainActor
    func updateRace() async {
        let race = makeRace()
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]

        let vm = makeViewModel(raceRepo: raceRepo)
        vm.races = [race]

        var updated = race
        updated.distanceKm = 80

        await vm.updateRace(updated)

        #expect(vm.races.first?.distanceKm == 80)
        #expect(vm.error == nil)
    }

    @Test("Update race handles error")
    @MainActor
    func updateRaceError() async {
        let race = makeRace()
        let raceRepo = MockRaceRepository()
        raceRepo.shouldThrow = true

        let vm = makeViewModel(raceRepo: raceRepo)
        vm.races = [race]

        var updated = race
        updated.distanceKm = 80

        await vm.updateRace(updated)

        #expect(vm.error != nil)
        #expect(vm.races.first?.distanceKm == 100)
    }

    // MARK: - Delete Race

    @Test("Delete race removes from list")
    @MainActor
    func deleteRace() async {
        let race = makeRace()
        let raceRepo = MockRaceRepository()

        let vm = makeViewModel(raceRepo: raceRepo)
        vm.races = [race]

        await vm.deleteRace(id: race.id)

        #expect(vm.races.isEmpty)
        #expect(vm.error == nil)
    }

    @Test("Delete race handles error")
    @MainActor
    func deleteRaceError() async {
        let race = makeRace()
        let raceRepo = MockRaceRepository()
        raceRepo.shouldThrow = true

        let vm = makeViewModel(raceRepo: raceRepo)
        vm.races = [race]

        await vm.deleteRace(id: race.id)

        #expect(vm.error != nil)
        #expect(vm.races.count == 1)
    }

    // MARK: - Computed Properties

    @Test("Sorted races returns by date ascending")
    @MainActor
    func sortedRaces() {
        let early = makeRace(name: "Early", date: Date.now.adding(weeks: 4))
        let mid = makeRace(name: "Mid", date: Date.now.adding(weeks: 12))
        let late = makeRace(name: "Late", date: Date.now.adding(weeks: 20))

        let vm = makeViewModel()
        vm.races = [late, early, mid]

        let sorted = vm.sortedRaces
        #expect(sorted[0].name == "Early")
        #expect(sorted[1].name == "Mid")
        #expect(sorted[2].name == "Late")
    }

    @Test("aRace returns the A priority race")
    @MainActor
    func aRaceReturnsCorrect() {
        let bRace = makeRace(name: "B Race", priority: .bRace)
        let aRace = makeRace(name: "A Race", priority: .aRace)

        let vm = makeViewModel()
        vm.races = [bRace, aRace]

        #expect(vm.aRace?.name == "A Race")
    }

    @Test("aRace returns nil when none")
    @MainActor
    func aRaceReturnsNil() {
        let vm = makeViewModel()
        #expect(vm.aRace == nil)
    }
}
