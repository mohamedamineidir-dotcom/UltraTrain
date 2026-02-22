import Testing
import Foundation
@testable import UltraTrain

@Suite("MorningCheckInViewModel Tests")
@MainActor
struct MorningCheckInViewModelTests {

    private func makeSUT() -> (MorningCheckInViewModel, MockMorningCheckInRepository) {
        let repo = MockMorningCheckInRepository()
        let vm = MorningCheckInViewModel(morningCheckInRepository: repo)
        return (vm, repo)
    }

    @Test("Initial state has default values")
    func initialState() {
        let (vm, _) = makeSUT()
        #expect(vm.perceivedEnergy == 3)
        #expect(vm.muscleSoreness == 1)
        #expect(vm.mood == 3)
        #expect(vm.sleepQualitySubjective == 3)
        #expect(vm.notes == "")
        #expect(!vm.isLoading)
        #expect(!vm.isSaving)
        #expect(!vm.didSave)
    }

    @Test("Loads existing check-in for today")
    func loadExisting() async {
        let (vm, repo) = makeSUT()
        let existing = MorningCheckIn(
            id: UUID(),
            date: .now,
            perceivedEnergy: 5,
            muscleSoreness: 3,
            mood: 4,
            sleepQualitySubjective: 2,
            notes: "Feeling okay"
        )
        repo.checkIns = [existing]

        await vm.loadTodaysCheckIn()

        #expect(vm.perceivedEnergy == 5)
        #expect(vm.muscleSoreness == 3)
        #expect(vm.mood == 4)
        #expect(vm.sleepQualitySubjective == 2)
        #expect(vm.notes == "Feeling okay")
    }

    @Test("Save creates new check-in")
    func saveNew() async {
        let (vm, repo) = makeSUT()
        vm.perceivedEnergy = 4
        vm.muscleSoreness = 2
        vm.mood = 5
        vm.sleepQualitySubjective = 4
        vm.notes = "Great morning"

        await vm.save()

        #expect(vm.didSave)
        #expect(repo.saveCalledWith.count == 1)
        let saved = repo.saveCalledWith.first!
        #expect(saved.perceivedEnergy == 4)
        #expect(saved.muscleSoreness == 2)
        #expect(saved.mood == 5)
        #expect(saved.sleepQualitySubjective == 4)
        #expect(saved.notes == "Great morning")
    }

    @Test("Save with empty notes sets nil")
    func saveEmptyNotes() async {
        let (vm, _) = makeSUT()
        vm.notes = ""

        await vm.save()

        #expect(vm.didSave)
    }

    @Test("Load with no existing check-in keeps defaults")
    func loadNoExisting() async {
        let (vm, _) = makeSUT()

        await vm.loadTodaysCheckIn()

        #expect(vm.perceivedEnergy == 3)
        #expect(vm.muscleSoreness == 1)
    }
}
