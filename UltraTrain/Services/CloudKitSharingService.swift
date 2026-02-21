import Foundation
import CloudKit
import os

actor CloudKitSharingService: CloudKitSharingServiceProtocol {

    private let accountManager: CloudKitAccountManager
    private var database: CKDatabase { get async { await accountManager.publicDatabase } }

    init(accountManager: CloudKitAccountManager) {
        self.accountManager = accountManager
    }

    // MARK: - Profile

    func publishSocialProfile(_ profile: SocialProfile) async throws {
        let record = CloudKitRecordConverter.toRecord(profile)
        do {
            let _ = try await database.save(record)
            Logger.cloudKit.info("Published social profile")
        } catch {
            Logger.cloudKit.error("Failed to publish profile: \(error)")
            throw mapError(error)
        }
    }

    func fetchSocialProfile(byId profileId: String) async throws -> SocialProfile? {
        let recordID = CKRecord.ID(recordName: profileId)
        do {
            let record = try await database.record(for: recordID)
            return CloudKitRecordConverter.toSocialProfile(record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        } catch {
            Logger.cloudKit.error("Failed to fetch profile \(profileId): \(error)")
            throw mapError(error)
        }
    }

    func fetchMyProfileId() async throws -> String {
        do { return try await accountManager.fetchMyRecordName() }
        catch {
            Logger.cloudKit.error("Failed to fetch my profile ID: \(error)")
            throw mapError(error)
        }
    }

    // MARK: - Friends

    func sendFriendRequest(toProfileId: String, displayName: String) async throws -> FriendConnection {
        let myProfileId = try await fetchMyProfileId()
        let connection = FriendConnection(
            id: UUID(), friendProfileId: toProfileId, friendDisplayName: displayName,
            friendPhotoData: nil, status: .pending, createdDate: Date(), acceptedDate: nil
        )
        let record = CloudKitRecordConverter.toRecord(connection, myProfileId: myProfileId)
        do {
            let _ = try await database.save(record)
            Logger.cloudKit.info("Sent friend request to \(toProfileId)")
            return connection
        } catch {
            Logger.cloudKit.error("Failed to send friend request: \(error)")
            throw mapError(error)
        }
    }

    func acceptFriendRequest(_ connectionId: UUID) async throws {
        let recordID = CKRecord.ID(recordName: connectionId.uuidString)
        do {
            let record = try await database.record(for: recordID)
            record["statusRaw"] = FriendStatus.accepted.rawValue
            record["acceptedDate"] = Date()
            let _ = try await database.save(record)
            Logger.cloudKit.info("Accepted friend request \(connectionId)")
        } catch {
            Logger.cloudKit.error("Failed to accept friend request: \(error)")
            throw mapError(error)
        }
    }

    func removeFriend(_ connectionId: UUID) async throws {
        let recordID = CKRecord.ID(recordName: connectionId.uuidString)
        do {
            try await database.deleteRecord(withID: recordID)
            Logger.cloudKit.info("Removed friend connection \(connectionId)")
        } catch {
            Logger.cloudKit.error("Failed to remove friend: \(error)")
            throw mapError(error)
        }
    }

    func fetchFriends() async throws -> [FriendConnection] {
        let myProfileId = try await fetchMyProfileId()
        let asRequester = try await queryConnections(field: "requesterProfileId", value: myProfileId, status: "accepted")
        let asTarget = try await queryConnections(field: "targetProfileId", value: myProfileId, status: "accepted")
        var seen = Set<String>()
        return (asRequester + asTarget).compactMap { record in
            guard let conn = CloudKitRecordConverter.toFriendConnection(record, myProfileId: myProfileId),
                  seen.insert(conn.id.uuidString).inserted else { return nil }
            return conn
        }
    }

    func fetchPendingRequests() async throws -> [FriendConnection] {
        let myProfileId = try await fetchMyProfileId()
        let records = try await queryConnections(field: "targetProfileId", value: myProfileId, status: "pending")
        return records.compactMap { CloudKitRecordConverter.toFriendConnection($0, myProfileId: myProfileId) }
    }

    // MARK: - Run Sharing

    func shareRun(_ run: SharedRun, withFriendIds: [String]) async throws {
        let record = CloudKitRecordConverter.toRecord(run)
        do {
            let _ = try await database.save(record)
            Logger.cloudKit.info("Shared run \(run.id) with \(withFriendIds.count) friend(s)")
        } catch {
            Logger.cloudKit.error("Failed to share run: \(error)")
            throw mapError(error)
        }
    }

    func fetchSharedRuns() async throws -> [SharedRun] {
        let friendIds = try await fetchFriends().map(\.friendProfileId)
        guard !friendIds.isEmpty else { return [] }
        let predicate = NSPredicate(format: "sharedByProfileId IN %@", friendIds)
        let query = CKQuery(recordType: CloudKitRecordConverter.sharedRunType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "sharedAt", ascending: false)]
        do {
            let (results, _) = try await database.records(matching: query, resultsLimit: 50)
            return results.compactMap { try? $0.1.get() }.compactMap { CloudKitRecordConverter.toSharedRun($0) }
        } catch {
            Logger.cloudKit.error("Failed to fetch shared runs: \(error)")
            throw mapError(error)
        }
    }

    func revokeShare(_ runId: UUID) async throws {
        let recordID = CKRecord.ID(recordName: runId.uuidString)
        do {
            try await database.deleteRecord(withID: recordID)
            Logger.cloudKit.info("Revoked shared run \(runId)")
        } catch {
            Logger.cloudKit.error("Failed to revoke share: \(error)")
            throw mapError(error)
        }
    }

    // MARK: - Activity Feed

    func publishActivity(_ item: ActivityFeedItem) async throws {
        let record = CloudKitRecordConverter.toRecord(item)
        do {
            let _ = try await database.save(record)
            Logger.cloudKit.info("Published activity \(item.id)")
        } catch {
            Logger.cloudKit.error("Failed to publish activity: \(error)")
            throw mapError(error)
        }
    }

    func fetchActivityFeed(limit: Int) async throws -> [ActivityFeedItem] {
        let friendIds = try await fetchFriends().map(\.friendProfileId)
        guard !friendIds.isEmpty else { return [] }
        let predicate = NSPredicate(format: "athleteProfileId IN %@", friendIds)
        let query = CKQuery(recordType: CloudKitRecordConverter.activityFeedItemType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        do {
            let (results, _) = try await database.records(matching: query, resultsLimit: limit)
            return results.compactMap { try? $0.1.get() }.compactMap { CloudKitRecordConverter.toActivityFeedItem($0) }
        } catch {
            Logger.cloudKit.error("Failed to fetch activity feed: \(error)")
            throw mapError(error)
        }
    }

    // MARK: - Crew Tracking

    func startCrewSession() async throws -> CrewTrackingSession {
        let myProfileId = try await fetchMyProfileId()
        let displayName = (try await fetchSocialProfile(byId: myProfileId))?.displayName ?? "Host"
        let session = CrewTrackingSession(
            id: UUID(), hostProfileId: myProfileId, hostDisplayName: displayName,
            startedAt: Date(), status: .active, participants: []
        )
        let sessionRecord = CloudKitRecordConverter.toRecord(session)
        let hostParticipant = CrewParticipant(
            id: myProfileId, displayName: displayName, latitude: 0, longitude: 0,
            distanceKm: 0, currentPaceSecondsPerKm: 0, lastUpdated: Date()
        )
        let participantRecord = CloudKitRecordConverter.toRecord(hostParticipant, sessionId: session.id, role: "host")
        do {
            let _ = try await database.save(sessionRecord)
            let _ = try await database.save(participantRecord)
            Logger.cloudKit.info("Started crew session \(session.id)")
            return session
        } catch {
            Logger.cloudKit.error("Failed to start crew session: \(error)")
            throw mapError(error)
        }
    }

    func updateMyLocation(
        sessionId: UUID, latitude: Double, longitude: Double,
        distanceKm: Double, paceSecondsPerKm: Double
    ) async throws {
        let myProfileId = try await fetchMyProfileId()
        let recordID = CKRecord.ID(recordName: "\(sessionId.uuidString)_\(myProfileId)")
        do {
            let record = try await database.record(for: recordID)
            record["latitude"] = latitude
            record["longitude"] = longitude
            record["distanceKm"] = distanceKm
            record["currentPaceSecondsPerKm"] = paceSecondsPerKm
            record["lastUpdated"] = Date()
            let _ = try await database.save(record)
        } catch {
            Logger.cloudKit.error("Failed to update location for session \(sessionId): \(error)")
            throw mapError(error)
        }
    }

    func fetchCrewSession(_ sessionId: UUID) async throws -> CrewTrackingSession? {
        let recordID = CKRecord.ID(recordName: sessionId.uuidString)
        do {
            let sessionRecord = try await database.record(for: recordID)
            let participants = try await fetchParticipants(sessionId: sessionId)
            return CloudKitRecordConverter.toCrewTrackingSession(sessionRecord, participants: participants)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        } catch {
            Logger.cloudKit.error("Failed to fetch crew session \(sessionId): \(error)")
            throw mapError(error)
        }
    }

    func endCrewSession(_ sessionId: UUID) async throws {
        let recordID = CKRecord.ID(recordName: sessionId.uuidString)
        do {
            let record = try await database.record(for: recordID)
            record["statusRaw"] = CrewTrackingStatus.ended.rawValue
            let _ = try await database.save(record)
            Logger.cloudKit.info("Ended crew session \(sessionId)")
        } catch {
            Logger.cloudKit.error("Failed to end crew session: \(error)")
            throw mapError(error)
        }
    }

    // MARK: - Private Helpers

    private func queryConnections(field: String, value: String, status: String) async throws -> [CKRecord] {
        let predicate = NSPredicate(format: "%K == %@ AND statusRaw == %@", field, value, status)
        let query = CKQuery(recordType: CloudKitRecordConverter.friendConnectionType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
        do {
            let (results, _) = try await database.records(matching: query, resultsLimit: 200)
            return results.compactMap { try? $0.1.get() }
        } catch {
            Logger.cloudKit.error("Failed to query connections (\(field)): \(error)")
            throw mapError(error)
        }
    }

    private func fetchParticipants(sessionId: UUID) async throws -> [CrewParticipant] {
        let predicate = NSPredicate(format: "sessionId == %@", sessionId.uuidString)
        let query = CKQuery(recordType: CloudKitRecordConverter.crewParticipantType, predicate: predicate)
        let (results, _) = try await database.records(matching: query, resultsLimit: 50)
        return results.compactMap { try? $0.1.get() }.compactMap { CloudKitRecordConverter.toCrewParticipant($0)?.participant }
    }

    private func mapError(_ error: Error) -> SocialError {
        guard let ckError = error as? CKError else {
            return .networkError(reason: error.localizedDescription)
        }
        switch ckError.code {
        case .notAuthenticated: return .notAuthenticated
        case .permissionFailure: return .cloudKitPermissionDenied
        case .networkUnavailable, .networkFailure: return .networkError(reason: ckError.localizedDescription)
        case .quotaExceeded: return .quotaExceeded
        case .unknownItem: return .recordNotFound
        case .zoneBusy, .serviceUnavailable: return .cloudKitUnavailable
        default: return .networkError(reason: ckError.localizedDescription)
        }
    }
}
