import Foundation
import Testing
@testable import UltraTrain

@Suite("SocialProfileViewModel Tests")
struct SocialProfileViewModelTests {

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

    private func makeProfile() -> SocialProfile {
        SocialProfile(
            id: "profile-123",
            displayName: "Trail Runner",
            bio: "Love the mountains",
            profilePhotoData: nil,
            experienceLevel: .intermediate,
            totalDistanceKm: 1500,
            totalElevationGainM: 50000,
            totalRuns: 200,
            joinedDate: Date.now.addingTimeInterval(-86400 * 365),
            isPublicProfile: true
        )
    }

    private func makeCompletedRun(distanceKm: Double = 10, elevationGainM: Double = 300) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: Date.now,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 280,
            duration: 3600,
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

    @MainActor
    private func makeSUT(
        profileRepo: MockSocialProfileRepository = MockSocialProfileRepository(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        runRepo: MockRunRepository = MockRunRepository()
    ) -> (SocialProfileViewModel, MockSocialProfileRepository, MockAthleteRepository, MockRunRepository) {
        let vm = SocialProfileViewModel(
            profileRepository: profileRepo,
            athleteRepository: athleteRepo,
            runRepository: runRepo
        )
        return (vm, profileRepo, athleteRepo, runRepo)
    }

    // MARK: - Tests

    @Test("Load populates profile and editable fields from existing profile")
    @MainActor
    func loadExistingProfile() async {
        let profileRepo = MockSocialProfileRepository()
        profileRepo.myProfile = makeProfile()
        let (vm, _, _, _) = makeSUT(profileRepo: profileRepo)

        await vm.load()

        #expect(vm.profile != nil)
        #expect(vm.displayName == "Trail Runner")
        #expect(vm.bio == "Love the mountains")
        #expect(vm.isPublicProfile == true)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load falls back to athlete name when no profile exists")
    @MainActor
    func loadFallbackToAthlete() async {
        let profileRepo = MockSocialProfileRepository()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let (vm, _, _, _) = makeSUT(profileRepo: profileRepo, athleteRepo: athleteRepo)

        await vm.load()

        #expect(vm.profile == nil)
        #expect(vm.displayName == "Test R.")
        #expect(vm.isLoading == false)
    }

    @Test("Load sets error on failure")
    @MainActor
    func loadSetsError() async {
        let profileRepo = MockSocialProfileRepository()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.shouldThrow = true
        // When profile is nil, it tries athlete, which throws
        let (vm, _, _, _) = makeSUT(profileRepo: profileRepo, athleteRepo: athleteRepo)

        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    @Test("Save persists updated profile with computed stats")
    @MainActor
    func saveUpdatesProfile() async {
        let profileRepo = MockSocialProfileRepository()
        profileRepo.myProfile = makeProfile()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [
            makeCompletedRun(distanceKm: 15, elevationGainM: 500),
            makeCompletedRun(distanceKm: 20, elevationGainM: 800)
        ]
        let (vm, _, _, _) = makeSUT(profileRepo: profileRepo, athleteRepo: athleteRepo, runRepo: runRepo)
        await vm.load()

        vm.displayName = "Ultra Runner"
        vm.bio = "Trail enthusiast"
        vm.isPublicProfile = false

        await vm.save()

        #expect(profileRepo.savedProfile != nil)
        #expect(profileRepo.savedProfile?.displayName == "Ultra Runner")
        #expect(profileRepo.savedProfile?.bio == "Trail enthusiast")
        #expect(profileRepo.savedProfile?.isPublicProfile == false)
        #expect(profileRepo.savedProfile?.totalDistanceKm == 35)
        #expect(profileRepo.savedProfile?.totalElevationGainM == 1300)
        #expect(profileRepo.savedProfile?.totalRuns == 2)
        #expect(vm.isSaving == false)
        #expect(vm.error == nil)
    }

    @Test("Save sets empty bio to nil")
    @MainActor
    func saveEmptyBioIsNil() async {
        let profileRepo = MockSocialProfileRepository()
        profileRepo.myProfile = makeProfile()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let (vm, _, _, _) = makeSUT(profileRepo: profileRepo, athleteRepo: athleteRepo)
        await vm.load()

        vm.bio = ""
        await vm.save()

        #expect(profileRepo.savedProfile?.bio == nil)
    }

    @Test("Save sets error on failure")
    @MainActor
    func saveSetsError() async {
        let profileRepo = MockSocialProfileRepository()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.shouldThrow = true
        let (vm, _, _, _) = makeSUT(profileRepo: profileRepo, athleteRepo: athleteRepo)

        await vm.save()

        #expect(vm.error != nil)
        #expect(vm.isSaving == false)
    }
}
