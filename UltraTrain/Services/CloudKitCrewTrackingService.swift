import Foundation
import CloudKit
import os

actor CloudKitCrewTrackingService: CrewTrackingServiceProtocol {

    private let accountManager: CloudKitAccountManager

    init(accountManager: CloudKitAccountManager) {
        self.accountManager = accountManager
    }

    // MARK: - Start Session

    func startSession() async throws -> CrewTrackingSession {
        let db = await accountManager.publicDatabase
        let myId = try await accountManager.fetchMyRecordName()

        let session = CrewTrackingSession(
            id: UUID(),
            hostProfileId: myId,
            hostDisplayName: "Host",
            startedAt: Date(),
            status: .active,
            participants: [
                CrewParticipant(
                    id: myId, displayName: "Host",
                    latitude: 0, longitude: 0,
                    distanceKm: 0, currentPaceSecondsPerKm: 0,
                    lastUpdated: Date()
                )
            ]
        )
        let sessionRecord = CloudKitRecordConverter.toRecord(session)
        let participantRecord = CloudKitRecordConverter.toRecord(
            session.participants[0], sessionId: session.id, role: "host"
        )
        do {
            _ = try await db.save(sessionRecord)
            _ = try await db.save(participantRecord)
            Logger.cloudKit.info("Started crew session \(session.id)")
            return session
        } catch {
            Logger.cloudKit.error("Failed to start crew session: \(error)")
            throw mapError(error)
        }
    }

    // MARK: - Join Session

    func joinSession(_ sessionId: UUID) async throws {
        let db = await accountManager.publicDatabase
        let myId = try await accountManager.fetchMyRecordName()
        let sessionRecordID = CKRecord.ID(recordName: sessionId.uuidString)

        do {
            let sessionRecord = try await db.record(for: sessionRecordID)
            guard let statusRaw = sessionRecord["statusRaw"] as? String,
                  statusRaw == CrewTrackingStatus.active.rawValue else {
                throw SocialError.recordNotFound
            }
        } catch let error as SocialError {
            throw error
        } catch {
            Logger.cloudKit.error("Failed to verify session: \(error)")
            throw mapError(error)
        }

        let participant = CrewParticipant(
            id: myId, displayName: "Participant",
            latitude: 0, longitude: 0,
            distanceKm: 0, currentPaceSecondsPerKm: 0,
            lastUpdated: Date()
        )
        let record = CloudKitRecordConverter.toRecord(participant, sessionId: sessionId, role: "runner")
        do {
            _ = try await db.save(record)
            Logger.cloudKit.info("Joined crew session \(sessionId)")
        } catch {
            Logger.cloudKit.error("Failed to join session: \(error)")
            throw mapError(error)
        }
    }

    // MARK: - Update Location

    func updateLocation(
        sessionId: UUID, latitude: Double, longitude: Double,
        distanceKm: Double, paceSecondsPerKm: Double
    ) async throws {
        let db = await accountManager.publicDatabase
        let myId = try await accountManager.fetchMyRecordName()
        let recordID = CKRecord.ID(recordName: "\(sessionId.uuidString)_\(myId)")
        do {
            let record = try await db.record(for: recordID)
            record["latitude"] = latitude
            record["longitude"] = longitude
            record["distanceKm"] = distanceKm
            record["currentPaceSecondsPerKm"] = paceSecondsPerKm
            record["lastUpdated"] = Date()
            _ = try await db.save(record)
        } catch {
            Logger.cloudKit.error("Failed to update location: \(error)")
            throw mapError(error)
        }
    }

    // MARK: - Fetch Session

    func fetchSession(_ sessionId: UUID) async throws -> CrewTrackingSession? {
        let db = await accountManager.publicDatabase
        let sessionRecordID = CKRecord.ID(recordName: sessionId.uuidString)
        do {
            let sessionRecord = try await db.record(for: sessionRecordID)
            let predicate = NSPredicate(format: "sessionId == %@", sessionId.uuidString)
            let query = CKQuery(
                recordType: CloudKitRecordConverter.crewParticipantType,
                predicate: predicate
            )
            let (results, _) = try await db.records(matching: query, resultsLimit: 50)
            let participants = results.compactMap { try? $0.1.get() }
                .compactMap { CloudKitRecordConverter.toCrewParticipant($0)?.participant }
            return CloudKitRecordConverter.toCrewTrackingSession(sessionRecord, participants: participants)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        } catch {
            Logger.cloudKit.error("Failed to fetch crew session: \(error)")
            throw mapError(error)
        }
    }

    // MARK: - End Session

    func endSession(_ sessionId: UUID) async throws {
        let db = await accountManager.publicDatabase
        let recordID = CKRecord.ID(recordName: sessionId.uuidString)
        do {
            let record = try await db.record(for: recordID)
            record["statusRaw"] = CrewTrackingStatus.ended.rawValue
            _ = try await db.save(record)
            Logger.cloudKit.info("Ended crew session \(sessionId)")
        } catch {
            Logger.cloudKit.error("Failed to end crew session: \(error)")
            throw mapError(error)
        }
    }

    // MARK: - Leave Session

    func leaveSession(_ sessionId: UUID) async throws {
        let db = await accountManager.publicDatabase
        let myId = try await accountManager.fetchMyRecordName()
        let recordID = CKRecord.ID(recordName: "\(sessionId.uuidString)_\(myId)")
        do {
            try await db.deleteRecord(withID: recordID)
            Logger.cloudKit.info("Left crew session \(sessionId)")
        } catch {
            Logger.cloudKit.error("Failed to leave session: \(error)")
            throw mapError(error)
        }
    }

    // MARK: - Error Mapping

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
        default: return .cloudKitUnavailable
        }
    }
}
