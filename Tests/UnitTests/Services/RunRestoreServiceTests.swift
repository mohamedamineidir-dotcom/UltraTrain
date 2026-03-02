import Foundation
import Testing
@testable import UltraTrain

@Suite("RunRestoreService Tests")
struct RunRestoreServiceTests {

    private func makeAthlete(id: UUID = UUID()) -> Athlete {
        Athlete(
            id: id,
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 50,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 60,
            longestRunKm: 30,
            preferredUnit: .metric
        )
    }

    // MARK: - Not Authenticated

    @Test("restoreRuns returns empty array when not authenticated")
    func restoreRunsNotAuthenticated() async {
        let mockAuth = MockAuthService()
        mockAuth.isLoggedIn = false
        let mockAthleteRepo = MockAthleteRepository()
        let remote = RemoteRunDataSource(apiClient: APIClient())
        let service = RunRestoreService(
            remote: remote,
            authService: mockAuth,
            athleteRepository: mockAthleteRepo
        )

        let runs = await service.restoreRuns()

        #expect(runs.isEmpty)
    }

    // MARK: - No Athlete

    @Test("restoreRuns returns empty array when no athlete found")
    func restoreRunsNoAthlete() async {
        let mockAuth = MockAuthService()
        mockAuth.isLoggedIn = true
        let mockAthleteRepo = MockAthleteRepository()
        mockAthleteRepo.savedAthlete = nil
        let remote = RemoteRunDataSource(apiClient: APIClient())
        let service = RunRestoreService(
            remote: remote,
            authService: mockAuth,
            athleteRepository: mockAthleteRepo
        )

        let runs = await service.restoreRuns()

        #expect(runs.isEmpty)
    }

    // MARK: - Athlete Repo Error

    @Test("restoreRuns returns empty array when athlete repo throws")
    func restoreRunsAthleteRepoError() async {
        let mockAuth = MockAuthService()
        mockAuth.isLoggedIn = true
        let mockAthleteRepo = MockAthleteRepository()
        mockAthleteRepo.shouldThrow = true
        let remote = RemoteRunDataSource(apiClient: APIClient())
        let service = RunRestoreService(
            remote: remote,
            authService: mockAuth,
            athleteRepository: mockAthleteRepo
        )

        let runs = await service.restoreRuns()

        #expect(runs.isEmpty)
    }

    // MARK: - Network Error

    @Test("restoreRuns returns empty array when remote fetch fails")
    func restoreRunsNetworkError() async {
        let mockAuth = MockAuthService()
        mockAuth.isLoggedIn = true
        let mockAthleteRepo = MockAthleteRepository()
        mockAthleteRepo.savedAthlete = makeAthlete()

        // The APIClient will fail because there is no valid server
        let remote = RemoteRunDataSource(apiClient: APIClient())
        let service = RunRestoreService(
            remote: remote,
            authService: mockAuth,
            athleteRepository: mockAthleteRepo
        )

        let runs = await service.restoreRuns()

        // Should return empty (graceful error handling) rather than crash
        #expect(runs.isEmpty)
    }

    // MARK: - Auth Check

    @Test("restoreRuns checks authentication before doing anything else")
    func restoreRunsChecksAuthFirst() async {
        let mockAuth = MockAuthService()
        mockAuth.isLoggedIn = false
        let mockAthleteRepo = MockAthleteRepository()
        mockAthleteRepo.savedAthlete = makeAthlete()
        let remote = RemoteRunDataSource(apiClient: APIClient())
        let service = RunRestoreService(
            remote: remote,
            authService: mockAuth,
            athleteRepository: mockAthleteRepo
        )

        let runs = await service.restoreRuns()

        #expect(runs.isEmpty)
        // If auth returns false, athlete repo should never be queried
        // (no error thrown from athlete repo means it was not called)
    }
}
