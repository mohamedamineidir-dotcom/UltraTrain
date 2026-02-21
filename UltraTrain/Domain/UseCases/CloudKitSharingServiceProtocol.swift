import Foundation

protocol CloudKitSharingServiceProtocol: Sendable {
    // Profile
    func publishSocialProfile(_ profile: SocialProfile) async throws
    func fetchSocialProfile(byId profileId: String) async throws -> SocialProfile?
    func fetchMyProfileId() async throws -> String

    // Friends
    func sendFriendRequest(toProfileId: String, displayName: String) async throws -> FriendConnection
    func acceptFriendRequest(_ connectionId: UUID) async throws
    func removeFriend(_ connectionId: UUID) async throws
    func fetchFriends() async throws -> [FriendConnection]
    func fetchPendingRequests() async throws -> [FriendConnection]

    // Run sharing
    func shareRun(_ run: SharedRun, withFriendIds: [String]) async throws
    func fetchSharedRuns() async throws -> [SharedRun]
    func revokeShare(_ runId: UUID) async throws

    // Activity feed
    func publishActivity(_ item: ActivityFeedItem) async throws
    func fetchActivityFeed(limit: Int) async throws -> [ActivityFeedItem]

    // Crew tracking
    func startCrewSession() async throws -> CrewTrackingSession
    func updateMyLocation(sessionId: UUID, latitude: Double, longitude: Double, distanceKm: Double, paceSecondsPerKm: Double) async throws
    func fetchCrewSession(_ sessionId: UUID) async throws -> CrewTrackingSession?
    func endCrewSession(_ sessionId: UUID) async throws
}
