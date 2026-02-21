import Foundation
@testable import UltraTrain

final class MockCloudKitSharingService: CloudKitSharingServiceProtocol, @unchecked Sendable {

    var publishedProfile: SocialProfile?
    var profilesById: [String: SocialProfile] = [:]
    var myProfileId = "mock-profile-id"
    var friends: [FriendConnection] = []
    var pendingRequests: [FriendConnection] = []
    var sharedRuns: [SharedRun] = []
    var activityFeed: [ActivityFeedItem] = []
    var crewSessions: [UUID: CrewTrackingSession] = [:]
    var shouldThrowError: SocialError?

    // MARK: - Profile

    func publishSocialProfile(_ profile: SocialProfile) async throws {
        if let error = shouldThrowError { throw error }
        publishedProfile = profile
        profilesById[profile.id] = profile
    }

    func fetchSocialProfile(byId profileId: String) async throws -> SocialProfile? {
        if let error = shouldThrowError { throw error }
        return profilesById[profileId]
    }

    func fetchMyProfileId() async throws -> String {
        if let error = shouldThrowError { throw error }
        return myProfileId
    }

    // MARK: - Friends

    func sendFriendRequest(toProfileId: String, displayName: String) async throws -> FriendConnection {
        if let error = shouldThrowError { throw error }
        let connection = FriendConnection(
            id: UUID(), friendProfileId: toProfileId,
            friendDisplayName: displayName, friendPhotoData: nil,
            status: .pending, createdDate: Date(), acceptedDate: nil
        )
        pendingRequests.append(connection)
        return connection
    }

    func acceptFriendRequest(_ connectionId: UUID) async throws {
        if let error = shouldThrowError { throw error }
        if let index = pendingRequests.firstIndex(where: { $0.id == connectionId }) {
            var connection = pendingRequests.remove(at: index)
            connection.status = .accepted
            connection.acceptedDate = Date()
            friends.append(connection)
        }
    }

    func removeFriend(_ connectionId: UUID) async throws {
        if let error = shouldThrowError { throw error }
        friends.removeAll { $0.id == connectionId }
    }

    func fetchFriends() async throws -> [FriendConnection] {
        if let error = shouldThrowError { throw error }
        return friends
    }

    func fetchPendingRequests() async throws -> [FriendConnection] {
        if let error = shouldThrowError { throw error }
        return pendingRequests
    }

    // MARK: - Run Sharing

    func shareRun(_ run: SharedRun, withFriendIds: [String]) async throws {
        if let error = shouldThrowError { throw error }
        sharedRuns.append(run)
    }

    func fetchSharedRuns() async throws -> [SharedRun] {
        if let error = shouldThrowError { throw error }
        return sharedRuns
    }

    func revokeShare(_ runId: UUID) async throws {
        if let error = shouldThrowError { throw error }
        sharedRuns.removeAll { $0.id == runId }
    }

    // MARK: - Activity Feed

    func publishActivity(_ item: ActivityFeedItem) async throws {
        if let error = shouldThrowError { throw error }
        activityFeed.append(item)
    }

    func fetchActivityFeed(limit: Int) async throws -> [ActivityFeedItem] {
        if let error = shouldThrowError { throw error }
        return Array(activityFeed.prefix(limit))
    }

    // MARK: - Crew Tracking

    func startCrewSession() async throws -> CrewTrackingSession {
        if let error = shouldThrowError { throw error }
        let session = CrewTrackingSession(
            id: UUID(), hostProfileId: myProfileId,
            hostDisplayName: "Host", startedAt: Date(),
            status: .active, participants: []
        )
        crewSessions[session.id] = session
        return session
    }

    func updateMyLocation(
        sessionId: UUID, latitude: Double, longitude: Double,
        distanceKm: Double, paceSecondsPerKm: Double
    ) async throws {
        if let error = shouldThrowError { throw error }
    }

    func fetchCrewSession(_ sessionId: UUID) async throws -> CrewTrackingSession? {
        if let error = shouldThrowError { throw error }
        return crewSessions[sessionId]
    }

    func endCrewSession(_ sessionId: UUID) async throws {
        if let error = shouldThrowError { throw error }
        crewSessions[sessionId]?.status = .ended
    }
}
