import Foundation
import Testing
@testable import UltraTrain

@Suite("ChallengesViewModel Tests")
struct ChallengesViewModelTests {

    // MARK: - Helpers

    private let athleteId = UUID()

    private func makeAthlete() -> Athlete {
        Athlete(
            id: athleteId,
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 50,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 50,
            longestRunKm: 30,
            preferredUnit: .metric
        )
    }

    private func makeRun(date: Date = .now, distanceKm: Double = 15, elevationGainM: Double = 500) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: date,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 500,
            duration: 5400,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    private func makeEnrollment(
        definitionId: String,
        status: ChallengeStatus = .active,
        startDate: Date = Calendar.current.date(byAdding: .day, value: -5, to: .now)!
    ) -> ChallengeEnrollment {
        ChallengeEnrollment(
            id: UUID(),
            challengeDefinitionId: definitionId,
            startDate: startDate,
            status: status
        )
    }

    @MainActor
    private func makeSUT(
        challengeRepo: MockChallengeRepository = MockChallengeRepository(),
        runRepo: MockRunRepository = MockRunRepository(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository()
    ) -> (ChallengesViewModel, MockChallengeRepository, MockRunRepository, MockAthleteRepository) {
        athleteRepo.savedAthlete = makeAthlete()
        let vm = ChallengesViewModel(
            challengeRepository: challengeRepo,
            runRepository: runRepo,
            athleteRepository: athleteRepo
        )
        return (vm, challengeRepo, runRepo, athleteRepo)
    }

    // MARK: - Tests

    @Test("Load computes active challenge progress")
    @MainActor
    func loadComputesProgress() async {
        let challengeRepo = MockChallengeRepository()
        let runRepo = MockRunRepository()
        let enrollment = makeEnrollment(definitionId: "dist_100km_month")
        challengeRepo.enrollments = [enrollment]
        runRepo.runs = [makeRun(distanceKm: 30), makeRun(distanceKm: 25)]

        let (vm, _, _, _) = makeSUT(challengeRepo: challengeRepo, runRepo: runRepo)
        await vm.load()

        #expect(vm.activeProgress.count == 1)
        #expect(vm.activeProgress.first?.currentValue == 55)
        #expect(vm.activeProgress.first?.targetValue == 100)
    }

    @Test("Load auto-completes finished challenge")
    @MainActor
    func loadAutoCompletes() async {
        let challengeRepo = MockChallengeRepository()
        let runRepo = MockRunRepository()
        let enrollment = makeEnrollment(definitionId: "dist_50km_month")
        challengeRepo.enrollments = [enrollment]
        runRepo.runs = [makeRun(distanceKm: 30), makeRun(distanceKm: 25)]

        let (vm, repo, _, _) = makeSUT(challengeRepo: challengeRepo, runRepo: runRepo)
        await vm.load()

        #expect(repo.updateCallCount == 1)
        #expect(vm.completedEnrollments.count == 1)
        #expect(vm.activeProgress.isEmpty)
    }

    @Test("Load computes current streak")
    @MainActor
    func loadComputesStreak() async {
        let runRepo = MockRunRepository()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        runRepo.runs = [
            makeRun(date: today),
            makeRun(date: calendar.date(byAdding: .day, value: -1, to: today)!),
            makeRun(date: calendar.date(byAdding: .day, value: -2, to: today)!)
        ]

        let (vm, _, _, _) = makeSUT(runRepo: runRepo)
        await vm.load()

        #expect(vm.currentStreak == 3)
    }

    @Test("Available challenges exclude enrolled ones")
    @MainActor
    func availableExcludesEnrolled() async {
        let challengeRepo = MockChallengeRepository()
        challengeRepo.enrollments = [makeEnrollment(definitionId: "dist_100km_month")]

        let (vm, _, _, _) = makeSUT(challengeRepo: challengeRepo)
        await vm.load()

        let ids = vm.availableChallenges.map(\.id)
        #expect(!ids.contains("dist_100km_month"))
        #expect(vm.availableChallenges.count == ChallengeLibrary.all.count - 1)
    }

    @Test("Start challenge saves enrollment and reloads")
    @MainActor
    func startChallengeSaves() async {
        let (vm, repo, _, _) = makeSUT()
        let definition = ChallengeLibrary.all.first!

        await vm.startChallenge(definition)

        #expect(repo.saveCallCount == 1)
        #expect(repo.enrollments.count == 1)
    }

    @Test("Abandon challenge deletes enrollment")
    @MainActor
    func abandonChallengeDeletes() async {
        let challengeRepo = MockChallengeRepository()
        let enrollment = makeEnrollment(definitionId: "dist_50km_month")
        challengeRepo.enrollments = [enrollment]

        let (vm, repo, _, _) = makeSUT(challengeRepo: challengeRepo)
        await vm.abandonChallenge(enrollment.id)

        #expect(repo.deleteCallCount == 1)
    }

    @Test("Error sets error message")
    @MainActor
    func errorSetsMessage() async {
        let challengeRepo = MockChallengeRepository()
        challengeRepo.shouldThrow = true

        let (vm, _, _, _) = makeSUT(challengeRepo: challengeRepo)
        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }
}
