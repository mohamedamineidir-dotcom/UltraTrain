import Testing
import Foundation
@testable import UltraTrain

@Suite("AchievementsViewModel Tests")
@MainActor
struct AchievementsViewModelTests {

    private func makeSUT() -> (AchievementsViewModel, MockAchievementRepository) {
        let repo = MockAchievementRepository()
        let vm = AchievementsViewModel(
            achievementRepository: repo,
            runRepository: MockRunRepository(),
            challengeRepository: MockChallengeRepository(),
            raceRepository: MockRaceRepository()
        )
        return (vm, repo)
    }

    @Test("Initial state")
    func initialState() {
        let (vm, _) = makeSUT()
        #expect(vm.unlockedAchievements.isEmpty)
        #expect(vm.selectedCategory == nil)
        #expect(!vm.isLoading)
    }

    @Test("Loads unlocked achievements")
    func loadUnlocked() async {
        let (vm, repo) = makeSUT()
        repo.unlockedAchievements = [
            UnlockedAchievement(id: UUID(), achievementId: "first_run", unlockedDate: .now)
        ]

        await vm.load()

        #expect(vm.unlockedAchievements.count >= 1)
    }

    @Test("Filter by category returns matching achievements")
    func filterByCategory() async {
        let (vm, _) = makeSUT()

        await vm.load()
        vm.selectedCategory = .distance

        let filtered = vm.displayedAchievements
        #expect(filtered.allSatisfy { $0.category == .distance })
    }

    @Test("No filter returns all achievements")
    func noFilter() async {
        let (vm, _) = makeSUT()

        await vm.load()
        vm.selectedCategory = nil

        #expect(vm.displayedAchievements.count == AchievementLibrary.all.count)
    }

    @Test("Unlocked count tracks correctly")
    func unlockedCount() async {
        let (vm, repo) = makeSUT()
        repo.unlockedAchievements = [
            UnlockedAchievement(id: UUID(), achievementId: "first_run", unlockedDate: .now),
            UnlockedAchievement(id: UUID(), achievementId: "10_runs", unlockedDate: .now)
        ]

        await vm.load()

        #expect(vm.unlockedCount == 2)
    }
}
