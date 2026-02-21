import Foundation
import Testing
@testable import UltraTrain

@Suite("RunReflectionEditViewModel")
@MainActor
struct RunReflectionEditViewModelTests {

    // MARK: - Helpers

    private func makeRun(
        rpe: Int? = nil,
        feeling: PerceivedFeeling? = nil,
        terrain: TerrainType? = nil,
        notes: String? = nil
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: .now,
            distanceKm: 10,
            elevationGainM: 200,
            elevationLossM: 180,
            duration: 3600,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            notes: notes,
            pausedDuration: 0,
            rpe: rpe,
            perceivedFeeling: feeling,
            terrainType: terrain
        )
    }

    private func makeViewModel(
        run: CompletedRun,
        repo: MockRunRepository = MockRunRepository()
    ) -> (RunReflectionEditViewModel, MockRunRepository) {
        let vm = RunReflectionEditViewModel(run: run, runRepository: repo)
        return (vm, repo)
    }

    // MARK: - Initial State

    @Test("Initial state populates from existing run")
    func testInitialState_populatesFromExistingRun() {
        let run = makeRun(
            rpe: 7,
            feeling: .good,
            terrain: .trail,
            notes: "test"
        )
        let (vm, _) = makeViewModel(run: run)

        #expect(vm.rpe == 7)
        #expect(vm.perceivedFeeling == .good)
        #expect(vm.terrainType == .trail)
        #expect(vm.notes == "test")
        #expect(vm.didSave == false)
        #expect(vm.error == nil)
    }

    @Test("Initial state with nil fields defaults correctly")
    func testInitialState_nilFieldsDefaultCorrectly() {
        let run = makeRun()
        let (vm, _) = makeViewModel(run: run)

        #expect(vm.rpe == nil)
        #expect(vm.perceivedFeeling == nil)
        #expect(vm.terrainType == nil)
        #expect(vm.notes == "")
    }

    // MARK: - Save

    @Test("Save updates run with reflection fields")
    func testSave_updatesRunWithReflectionFields() async {
        let run = makeRun()
        let (vm, repo) = makeViewModel(run: run)

        vm.rpe = 8
        vm.perceivedFeeling = .great
        vm.terrainType = .mountain
        vm.notes = "learned a lot"

        await vm.save()

        #expect(repo.updatedRun?.rpe == 8)
        #expect(repo.updatedRun?.perceivedFeeling == .great)
        #expect(repo.updatedRun?.terrainType == .mountain)
        #expect(repo.updatedRun?.notes == "learned a lot")
    }

    @Test("Save sets didSave on success")
    func testSave_setsDidSaveOnSuccess() async {
        let run = makeRun()
        let (vm, _) = makeViewModel(run: run)

        vm.rpe = 5

        await vm.save()

        #expect(vm.didSave == true)
        #expect(vm.error == nil)
    }

    @Test("Save updates the local run property")
    func testSave_updatesLocalRunProperty() async {
        let run = makeRun()
        let (vm, _) = makeViewModel(run: run)

        vm.rpe = 6
        vm.perceivedFeeling = .tough
        vm.terrainType = .road
        vm.notes = "hard session"

        await vm.save()

        #expect(vm.run.rpe == 6)
        #expect(vm.run.perceivedFeeling == .tough)
        #expect(vm.run.terrainType == .road)
        #expect(vm.run.notes == "hard session")
    }

    @Test("Save with empty notes stores nil")
    func testSave_emptyNotesStoresNil() async {
        let run = makeRun(notes: "old notes")
        let (vm, repo) = makeViewModel(run: run)

        vm.notes = ""

        await vm.save()

        #expect(repo.updatedRun?.notes == nil)
    }

    @Test("Save handles repository error")
    func testSave_handlesRepositoryError() async {
        let run = makeRun()
        let repo = MockRunRepository()
        repo.shouldThrow = true
        let (vm, _) = makeViewModel(run: run, repo: repo)

        vm.rpe = 5

        await vm.save()

        #expect(vm.error != nil)
        #expect(vm.didSave == false)
    }
}
