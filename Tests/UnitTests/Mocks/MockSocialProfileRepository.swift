import Foundation
@testable import UltraTrain

final class MockSocialProfileRepository: SocialProfileRepository, @unchecked Sendable {
    var myProfile: SocialProfile?
    var profilesById: [String: SocialProfile] = [:]
    var savedProfile: SocialProfile?
    var deleteProfileCalled = false

    func fetchMyProfile() async throws -> SocialProfile? { myProfile }
    func saveMyProfile(_ profile: SocialProfile) async throws { savedProfile = profile; myProfile = profile }
    func fetchProfile(byId profileId: String) async throws -> SocialProfile? { profilesById[profileId] }
    func deleteMyProfile() async throws { deleteProfileCalled = true; myProfile = nil }
}
