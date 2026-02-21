import Foundation
import Testing
@testable import UltraTrain

@Suite("GoalSettingViewModel")
@MainActor
struct GoalSettingViewModelTests {

    // MARK: - Helpers

    private func makeViewModel(
        repo: MockGoalRepository = MockGoalRepository(),
        existingGoal: TrainingGoal? = nil
    ) -> (GoalSettingViewModel, MockGoalRepository) {
        let vm = GoalSettingViewModel(goalRepository: repo, existingGoal: existingGoal)
        return (vm, repo)
    }

    private func makeGoal(
        period: GoalPeriod = .weekly,
        targetDistanceKm: Double? = 50,
        targetElevationM: Double? = 1000,
        targetRunCount: Int? = 4,
        targetDurationSeconds: TimeInterval? = 18000,
        startDate: Date = Date.now.startOfWeek,
        endDate: Date = Date.now.startOfWeek.adding(days: 6)
    ) -> TrainingGoal {
        TrainingGoal(
            id: UUID(),
            period: period,
            targetDistanceKm: targetDistanceKm,
            targetElevationM: targetElevationM,
            targetRunCount: targetRunCount,
            targetDurationSeconds: targetDurationSeconds,
            startDate: startDate,
            endDate: endDate
        )
    }

    // MARK: - Init with Existing Goal

    @Test("Init with existing goal populates fields")
    func testInit_existingGoal_populatesFields() {
        let existing = makeGoal(
            period: .monthly,
            targetDistanceKm: 200,
            targetElevationM: 5000,
            targetRunCount: 16,
            targetDurationSeconds: 72000
        )
        let (vm, _) = makeViewModel(existingGoal: existing)

        #expect(vm.period == .monthly)
        #expect(vm.targetDistanceKm == 200)
        #expect(vm.targetElevationM == 5000)
        #expect(vm.targetRunCount == 16)
        #expect(vm.targetDurationMinutes == 1200) // 72000 / 60
        #expect(vm.didSave == false)
        #expect(vm.error == nil)
    }

    @Test("Init without existing goal uses defaults")
    func testInit_noExistingGoal_usesDefaults() {
        let (vm, _) = makeViewModel()

        #expect(vm.period == .weekly)
        #expect(vm.targetDistanceKm == nil)
        #expect(vm.targetElevationM == nil)
        #expect(vm.targetRunCount == nil)
        #expect(vm.targetDurationMinutes == nil)
        #expect(vm.didSave == false)
    }

    // MARK: - Save Weekly

    @Test("Save weekly goal computes correct date range")
    func testSave_weeklyGoal_computesCorrectDateRange() async {
        let (vm, repo) = makeViewModel()

        vm.period = .weekly
        vm.targetDistanceKm = 50

        await vm.save()

        let saved = repo.savedGoal
        #expect(saved != nil)
        #expect(saved?.period == .weekly)
        #expect(saved?.targetDistanceKm == 50)

        let expectedStart = Date.now.startOfWeek
        let expectedEnd = expectedStart.adding(days: 6)
        #expect(saved?.startDate == expectedStart)
        #expect(saved?.endDate == expectedEnd)
    }

    // MARK: - Save Monthly

    @Test("Save monthly goal computes correct date range")
    func testSave_monthlyGoal_computesCorrectDateRange() async {
        let (vm, repo) = makeViewModel()

        vm.period = .monthly
        vm.targetDistanceKm = 200

        await vm.save()

        let saved = repo.savedGoal
        #expect(saved != nil)
        #expect(saved?.period == .monthly)

        let expectedStart = Date.now.startOfMonth
        let expectedEnd = Date.now.endOfMonth
        #expect(saved?.startDate == expectedStart)
        #expect(saved?.endDate == expectedEnd)
    }

    // MARK: - Save Calls Repository

    @Test("Save calls repository with all targets")
    func testSave_callsRepositoryWithTargets() async {
        let (vm, repo) = makeViewModel()

        vm.period = .weekly
        vm.targetDistanceKm = 60
        vm.targetElevationM = 2000
        vm.targetRunCount = 5
        vm.targetDurationMinutes = 300

        await vm.save()

        let saved = repo.savedGoal
        #expect(saved != nil)
        #expect(saved?.targetDistanceKm == 60)
        #expect(saved?.targetElevationM == 2000)
        #expect(saved?.targetRunCount == 5)
        #expect(saved?.targetDurationSeconds == 18000) // 300 * 60
        #expect(vm.didSave == true)
        #expect(vm.error == nil)
    }

    @Test("Save with nil duration minutes stores nil duration seconds")
    func testSave_nilDurationMinutes_storesNilDurationSeconds() async {
        let (vm, repo) = makeViewModel()

        vm.targetDistanceKm = 30
        vm.targetDurationMinutes = nil

        await vm.save()

        #expect(repo.savedGoal?.targetDurationSeconds == nil)
    }

    // MARK: - Save Error Handling

    @Test("Save handles repository error")
    func testSave_handlesError() async {
        let repo = MockGoalRepository()
        repo.shouldThrow = true
        let (vm, _) = makeViewModel(repo: repo)

        vm.targetDistanceKm = 50

        await vm.save()

        #expect(vm.error != nil)
        #expect(vm.didSave == false)
    }

    @Test("Save resets isSaving after completion")
    func testSave_resetsIsSaving() async {
        let (vm, _) = makeViewModel()

        vm.targetDistanceKm = 30

        await vm.save()

        #expect(vm.isSaving == false)
    }

    @Test("Save resets isSaving after error")
    func testSave_resetsIsSavingAfterError() async {
        let repo = MockGoalRepository()
        repo.shouldThrow = true
        let (vm, _) = makeViewModel(repo: repo)

        vm.targetDistanceKm = 30

        await vm.save()

        #expect(vm.isSaving == false)
    }
}
