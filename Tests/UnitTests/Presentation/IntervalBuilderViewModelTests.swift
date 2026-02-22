import Foundation
import Testing
@testable import UltraTrain

@Suite("IntervalBuilderViewModel Tests")
@MainActor
struct IntervalBuilderViewModelTests {

    // MARK: - Helpers

    private func makePhase(
        phaseType: IntervalPhaseType = .work,
        trigger: IntervalTrigger = .duration(seconds: 180),
        repeatCount: Int = 1
    ) -> IntervalPhase {
        IntervalPhase(
            id: UUID(),
            phaseType: phaseType,
            trigger: trigger,
            targetIntensity: .hard,
            repeatCount: repeatCount
        )
    }

    private func makeSUT(
        repo: MockIntervalWorkoutRepository = MockIntervalWorkoutRepository()
    ) -> (IntervalBuilderViewModel, MockIntervalWorkoutRepository) {
        let vm = IntervalBuilderViewModel(repository: repo)
        return (vm, repo)
    }

    // MARK: - addPhase

    @Test("addPhase increases phase count")
    func addPhaseIncreasesCount() {
        let (vm, _) = makeSUT()

        vm.addPhase(makePhase())

        #expect(vm.phases.count == 1)
    }

    @Test("addPhase appends multiple phases")
    func addPhaseAppendsMultiple() {
        let (vm, _) = makeSUT()

        vm.addPhase(makePhase(phaseType: .warmUp, trigger: .duration(seconds: 600)))
        vm.addPhase(makePhase(phaseType: .work, trigger: .duration(seconds: 180)))
        vm.addPhase(makePhase(phaseType: .recovery, trigger: .duration(seconds: 90)))

        #expect(vm.phases.count == 3)
        #expect(vm.phases[0].phaseType == .warmUp)
        #expect(vm.phases[1].phaseType == .work)
        #expect(vm.phases[2].phaseType == .recovery)
    }

    // MARK: - removePhase

    @Test("removePhases decreases phase count")
    func removePhaseDecreasesCount() {
        let (vm, _) = makeSUT()

        vm.addPhase(makePhase())
        vm.addPhase(makePhase())
        vm.addPhase(makePhase())
        #expect(vm.phases.count == 3)

        vm.removePhases(at: IndexSet(integer: 1))

        #expect(vm.phases.count == 2)
    }

    // MARK: - movePhase

    @Test("movePhases reorders phases correctly")
    func movePhasesReordersCorrectly() {
        let (vm, _) = makeSUT()

        let warmUp = makePhase(phaseType: .warmUp)
        let work = makePhase(phaseType: .work)
        let coolDown = makePhase(phaseType: .coolDown)

        vm.addPhase(warmUp)
        vm.addPhase(work)
        vm.addPhase(coolDown)

        // Move coolDown (index 2) to position 0
        vm.movePhases(from: IndexSet(integer: 2), to: 0)

        #expect(vm.phases[0].phaseType == .coolDown)
        #expect(vm.phases[1].phaseType == .warmUp)
        #expect(vm.phases[2].phaseType == .work)
    }

    // MARK: - Validation

    @Test("Validation fails with empty name")
    func validationFailsWithEmptyName() {
        let (vm, _) = makeSUT()

        vm.name = ""
        vm.addPhase(makePhase(phaseType: .work))

        #expect(vm.isValid == false)
    }

    @Test("Validation fails with whitespace-only name")
    func validationFailsWithWhitespaceName() {
        let (vm, _) = makeSUT()

        vm.name = "   "
        vm.addPhase(makePhase(phaseType: .work))

        #expect(vm.isValid == false)
    }

    @Test("Validation fails with no phases")
    func validationFailsWithNoPhases() {
        let (vm, _) = makeSUT()

        vm.name = "My Workout"

        #expect(vm.isValid == false)
    }

    @Test("Validation fails with no work phases")
    func validationFailsWithNoWorkPhases() {
        let (vm, _) = makeSUT()

        vm.name = "My Workout"
        vm.addPhase(makePhase(phaseType: .warmUp))
        vm.addPhase(makePhase(phaseType: .recovery))

        #expect(vm.isValid == false)
    }

    @Test("Validation passes with name and work phase")
    func validationPassesWithNameAndWorkPhase() {
        let (vm, _) = makeSUT()

        vm.name = "Good Workout"
        vm.addPhase(makePhase(phaseType: .work))

        #expect(vm.isValid == true)
    }

    // MARK: - Save

    @Test("Save calls repository when valid")
    func saveCallsRepository() async {
        let (vm, repo) = makeSUT()

        vm.name = "Test Workout"
        vm.addPhase(makePhase(phaseType: .work))

        await vm.save()

        #expect(repo.saveCallCount == 1)
        #expect(vm.didSave == true)
        #expect(vm.error == nil)
        #expect(vm.isSaving == false)
    }

    @Test("Save does not call repository when invalid")
    func saveDoesNotCallRepositoryWhenInvalid() async {
        let (vm, repo) = makeSUT()

        vm.name = ""

        await vm.save()

        #expect(repo.saveCallCount == 0)
        #expect(vm.didSave == false)
        #expect(vm.error != nil)
    }

    @Test("Save sets error when repository throws")
    func saveSetsErrorWhenRepositoryThrows() async {
        let repo = MockIntervalWorkoutRepository()
        repo.shouldThrow = true
        let (vm, _) = makeSUT(repo: repo)

        vm.name = "Error Workout"
        vm.addPhase(makePhase(phaseType: .work))

        await vm.save()

        #expect(vm.didSave == false)
        #expect(vm.error != nil)
        #expect(vm.isSaving == false)
    }

    @Test("Save trims whitespace from name")
    func saveTrimsWhitespace() async {
        let (vm, repo) = makeSUT()

        vm.name = "  Trimmed Name  "
        vm.addPhase(makePhase(phaseType: .work))

        await vm.save()

        #expect(repo.lastSavedWorkout?.name == "Trimmed Name")
    }

    @Test("Save marks workout as user-created")
    func saveMarksUserCreated() async {
        let (vm, repo) = makeSUT()

        vm.name = "User Workout"
        vm.addPhase(makePhase(phaseType: .work))

        await vm.save()

        #expect(repo.lastSavedWorkout?.isUserCreated == true)
    }

    // MARK: - Computed Properties

    @Test("workIntervalCount sums work phase repeats")
    func workIntervalCountSumsRepeats() {
        let (vm, _) = makeSUT()

        vm.addPhase(makePhase(phaseType: .work, repeatCount: 4))
        vm.addPhase(makePhase(phaseType: .recovery))
        vm.addPhase(makePhase(phaseType: .work, repeatCount: 2))

        #expect(vm.workIntervalCount == 6)
    }

    @Test("loadPreset populates name, phases, and category")
    func loadPresetPopulatesFields() {
        let (vm, _) = makeSUT()
        let preset = IntervalWorkoutLibrary.fourByOneKm

        vm.loadPreset(preset)

        #expect(vm.name == preset.name)
        #expect(vm.phases.count == preset.phases.count)
        #expect(vm.category == preset.category)
    }
}
