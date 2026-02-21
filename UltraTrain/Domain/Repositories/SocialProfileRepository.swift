import Foundation

protocol SocialProfileRepository: Sendable {
    func fetchMyProfile() async throws -> SocialProfile?
    func saveMyProfile(_ profile: SocialProfile) async throws
    func fetchProfile(byId profileId: String) async throws -> SocialProfile?
    func deleteMyProfile() async throws
}
