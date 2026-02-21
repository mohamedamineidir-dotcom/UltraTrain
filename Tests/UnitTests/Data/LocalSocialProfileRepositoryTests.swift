import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("Local Social Profile Repository Tests")
@MainActor
struct LocalSocialProfileRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            SocialProfileSwiftDataModel.self,
            FriendConnectionSwiftDataModel.self,
            SharedRunSwiftDataModel.self,
            ActivityFeedItemSwiftDataModel.self,
            GroupChallengeSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeProfile(
        id: String = "test-user-1",
        displayName: String = "Trail Runner",
        bio: String? = "Love the mountains",
        experienceLevel: ExperienceLevel = .intermediate,
        totalDistanceKm: Double = 500,
        totalElevationGainM: Double = 25000,
        totalRuns: Int = 50,
        isPublicProfile: Bool = true
    ) -> SocialProfile {
        SocialProfile(
            id: id,
            displayName: displayName,
            bio: bio,
            profilePhotoData: nil,
            experienceLevel: experienceLevel,
            totalDistanceKm: totalDistanceKm,
            totalElevationGainM: totalElevationGainM,
            totalRuns: totalRuns,
            joinedDate: Date.now,
            isPublicProfile: isPublicProfile
        )
    }

    @Test("Save and fetch my profile roundtrip")
    func saveAndFetchMyProfile() async throws {
        let container = try makeContainer()
        let repo = LocalSocialProfileRepository(modelContainer: container)

        let profile = makeProfile()

        try await repo.saveMyProfile(profile)
        let fetched = try await repo.fetchMyProfile()

        #expect(fetched != nil)
        #expect(fetched?.id == "test-user-1")
        #expect(fetched?.displayName == "Trail Runner")
        #expect(fetched?.bio == "Love the mountains")
        #expect(fetched?.experienceLevel == .intermediate)
        #expect(fetched?.totalDistanceKm == 500)
        #expect(fetched?.totalElevationGainM == 25000)
        #expect(fetched?.totalRuns == 50)
        #expect(fetched?.isPublicProfile == true)
    }

    @Test("Fetch profile by id")
    func fetchProfileById() async throws {
        let container = try makeContainer()
        let repo = LocalSocialProfileRepository(modelContainer: container)

        let profile = makeProfile(id: "specific-id", displayName: "Mountain Goat")

        try await repo.saveMyProfile(profile)
        let fetched = try await repo.fetchProfile(byId: "specific-id")

        #expect(fetched != nil)
        #expect(fetched?.id == "specific-id")
        #expect(fetched?.displayName == "Mountain Goat")
    }

    @Test("Update existing profile overwrites fields")
    func updateExistingProfile() async throws {
        let container = try makeContainer()
        let repo = LocalSocialProfileRepository(modelContainer: container)

        let original = makeProfile(
            id: "update-test",
            displayName: "Original Name",
            bio: "Original bio",
            experienceLevel: .beginner,
            totalDistanceKm: 100,
            totalRuns: 10
        )
        try await repo.saveMyProfile(original)

        let updated = makeProfile(
            id: "update-test",
            displayName: "Updated Name",
            bio: "Updated bio",
            experienceLevel: .advanced,
            totalDistanceKm: 800,
            totalRuns: 100
        )
        try await repo.saveMyProfile(updated)

        let fetched = try await repo.fetchProfile(byId: "update-test")

        #expect(fetched != nil)
        #expect(fetched?.displayName == "Updated Name")
        #expect(fetched?.bio == "Updated bio")
        #expect(fetched?.experienceLevel == .advanced)
        #expect(fetched?.totalDistanceKm == 800)
        #expect(fetched?.totalRuns == 100)
    }

    @Test("Delete profile removes it from store")
    func deleteProfile() async throws {
        let container = try makeContainer()
        let repo = LocalSocialProfileRepository(modelContainer: container)

        let profile = makeProfile(id: "delete-test")
        try await repo.saveMyProfile(profile)

        let beforeDelete = try await repo.fetchMyProfile()
        #expect(beforeDelete != nil)

        try await repo.deleteMyProfile()

        let afterDelete = try await repo.fetchMyProfile()
        #expect(afterDelete == nil)
    }

    @Test("Fetch returns nil when store is empty")
    func fetchReturnsNilWhenEmpty() async throws {
        let container = try makeContainer()
        let repo = LocalSocialProfileRepository(modelContainer: container)

        let fetched = try await repo.fetchMyProfile()
        #expect(fetched == nil)
    }
}
