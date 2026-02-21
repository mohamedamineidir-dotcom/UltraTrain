import Foundation
import Testing
@testable import UltraTrain

@Suite("SocialProfile Model Tests")
struct SocialProfileTests {

    private func makeProfile(
        isPublicProfile: Bool = false
    ) -> SocialProfile {
        SocialProfile(
            id: "profile-123",
            displayName: "Trail Runner",
            bio: "Ultra trail enthusiast",
            profilePhotoData: nil,
            experienceLevel: .intermediate,
            totalDistanceKm: 1500,
            totalElevationGainM: 85000,
            totalRuns: 200,
            joinedDate: Date.now,
            isPublicProfile: isPublicProfile
        )
    }

    @Test("SocialProfile creation with all fields")
    func creationWithAllFields() {
        let profile = makeProfile(isPublicProfile: true)

        #expect(profile.id == "profile-123")
        #expect(profile.displayName == "Trail Runner")
        #expect(profile.bio == "Ultra trail enthusiast")
        #expect(profile.profilePhotoData == nil)
        #expect(profile.experienceLevel == .intermediate)
        #expect(profile.totalDistanceKm == 1500)
        #expect(profile.totalElevationGainM == 85000)
        #expect(profile.totalRuns == 200)
        #expect(profile.isPublicProfile == true)
    }

    @Test("SocialProfile defaults to private when isPublicProfile is false")
    func defaultsToPrivate() {
        let profile = makeProfile(isPublicProfile: false)
        #expect(profile.isPublicProfile == false)
    }
}
