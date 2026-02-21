import Foundation
import CloudKit
import os

extension CloudKitRecordConverter {

    // MARK: - CrewTrackingSession

    static func toRecord(_ session: CrewTrackingSession) -> CKRecord {
        let record = CKRecord(
            recordType: crewSessionType,
            recordID: .init(recordName: session.id.uuidString)
        )
        record["hostProfileId"] = session.hostProfileId
        record["hostDisplayName"] = session.hostDisplayName
        record["startedAt"] = session.startedAt
        record["statusRaw"] = session.status.rawValue
        return record
    }

    static func toCrewTrackingSession(
        _ record: CKRecord,
        participants: [CrewParticipant]
    ) -> CrewTrackingSession? {
        guard record.recordType == crewSessionType,
              let uuid = UUID(uuidString: record.recordID.recordName),
              let hostId = record["hostProfileId"] as? String,
              let hostName = record["hostDisplayName"] as? String,
              let statusRaw = record["statusRaw"] as? String,
              let status = CrewTrackingStatus(rawValue: statusRaw) else { return nil }

        return CrewTrackingSession(
            id: uuid,
            hostProfileId: hostId,
            hostDisplayName: hostName,
            startedAt: record["startedAt"] as? Date ?? Date.distantPast,
            status: status,
            participants: participants
        )
    }

    // MARK: - CrewParticipant

    static func toRecord(_ participant: CrewParticipant, sessionId: UUID, role: String) -> CKRecord {
        let recordName = "\(sessionId.uuidString)_\(participant.id)"
        let record = CKRecord(
            recordType: crewParticipantType,
            recordID: .init(recordName: recordName)
        )
        record["participantId"] = participant.id
        record["sessionId"] = sessionId.uuidString
        record["displayName"] = participant.displayName
        record["role"] = role
        record["latitude"] = participant.latitude
        record["longitude"] = participant.longitude
        record["distanceKm"] = participant.distanceKm
        record["currentPaceSecondsPerKm"] = participant.currentPaceSecondsPerKm
        record["lastUpdated"] = participant.lastUpdated
        return record
    }

    static func toCrewParticipant(_ record: CKRecord) -> (participant: CrewParticipant, role: String)? {
        guard record.recordType == crewParticipantType,
              let participantId = record["participantId"] as? String,
              let displayName = record["displayName"] as? String,
              let role = record["role"] as? String else { return nil }

        let participant = CrewParticipant(
            id: participantId,
            displayName: displayName,
            latitude: record["latitude"] as? Double ?? 0,
            longitude: record["longitude"] as? Double ?? 0,
            distanceKm: record["distanceKm"] as? Double ?? 0,
            currentPaceSecondsPerKm: record["currentPaceSecondsPerKm"] as? Double ?? 0,
            lastUpdated: record["lastUpdated"] as? Date ?? Date.distantPast
        )
        return (participant, role)
    }

    // MARK: - GroupChallenge

    static func toRecord(_ challenge: GroupChallenge) -> CKRecord {
        let record = CKRecord(
            recordType: groupChallengeType,
            recordID: .init(recordName: challenge.id.uuidString)
        )
        record["creatorProfileId"] = challenge.creatorProfileId
        record["creatorDisplayName"] = challenge.creatorDisplayName
        record["name"] = challenge.name
        record["descriptionText"] = challenge.descriptionText
        record["typeRaw"] = challenge.type.rawValue
        record["targetValue"] = challenge.targetValue
        record["startDate"] = challenge.startDate
        record["endDate"] = challenge.endDate
        record["statusRaw"] = challenge.status.rawValue

        let participantsData = encodeParticipants(challenge.participants)
        if !participantsData.isEmpty {
            record["participants"] = createAsset(
                from: participantsData,
                filename: "participants_\(challenge.id).json"
            )
        }
        return record
    }

    static func toGroupChallenge(_ record: CKRecord) -> GroupChallenge? {
        guard record.recordType == groupChallengeType,
              let uuid = UUID(uuidString: record.recordID.recordName),
              let creatorId = record["creatorProfileId"] as? String,
              let creatorName = record["creatorDisplayName"] as? String,
              let name = record["name"] as? String,
              let typeRaw = record["typeRaw"] as? String,
              let type = ChallengeType(rawValue: typeRaw),
              let statusRaw = record["statusRaw"] as? String,
              let status = GroupChallengeStatus(rawValue: statusRaw) else { return nil }

        return GroupChallenge(
            id: uuid,
            creatorProfileId: creatorId,
            creatorDisplayName: creatorName,
            name: name,
            descriptionText: record["descriptionText"] as? String ?? "",
            type: type,
            targetValue: record["targetValue"] as? Double ?? 0,
            startDate: record["startDate"] as? Date ?? Date.distantPast,
            endDate: record["endDate"] as? Date ?? Date.distantFuture,
            status: status,
            participants: decodeParticipants(readAsset(record["participants"] as? CKAsset))
        )
    }

    // MARK: - CKAsset Helpers

    static func createAsset(from data: Data, filename: String) -> CKAsset? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: tempURL)
            return CKAsset(fileURL: tempURL)
        } catch {
            Logger.cloudKit.error("Failed to create CKAsset: \(error)")
            return nil
        }
    }

    static func readAsset(_ asset: CKAsset?) -> Data? {
        guard let fileURL = asset?.fileURL else { return nil }
        return try? Data(contentsOf: fileURL)
    }

    // MARK: - JSON Encoding Helpers

    private struct CodableTrackPoint: Codable {
        let latitude: Double
        let longitude: Double
        let altitudeM: Double
        let timestamp: Date
        let heartRate: Int?
    }

    private struct CodableSplit: Codable {
        let id: UUID
        let kilometerNumber: Int
        let duration: TimeInterval
        let elevationChangeM: Double
        let averageHeartRate: Int?
    }

    private struct CodableParticipant: Codable {
        let id: String
        let displayName: String
        let currentValue: Double
        let joinedDate: Date
    }

    static func encodeTrackPoints(_ points: [TrackPoint]) -> Data {
        let codable = points.map {
            CodableTrackPoint(
                latitude: $0.latitude, longitude: $0.longitude,
                altitudeM: $0.altitudeM, timestamp: $0.timestamp, heartRate: $0.heartRate
            )
        }
        return (try? JSONEncoder().encode(codable)) ?? Data()
    }

    static func decodeTrackPoints(_ data: Data?) -> [TrackPoint] {
        guard let data, let codable = try? JSONDecoder().decode([CodableTrackPoint].self, from: data) else {
            return []
        }
        return codable.map {
            TrackPoint(
                latitude: $0.latitude, longitude: $0.longitude,
                altitudeM: $0.altitudeM, timestamp: $0.timestamp, heartRate: $0.heartRate
            )
        }
    }

    static func encodeSplits(_ splits: [Split]) -> Data {
        let codable = splits.map {
            CodableSplit(
                id: $0.id, kilometerNumber: $0.kilometerNumber,
                duration: $0.duration, elevationChangeM: $0.elevationChangeM,
                averageHeartRate: $0.averageHeartRate
            )
        }
        return (try? JSONEncoder().encode(codable)) ?? Data()
    }

    static func decodeSplits(_ data: Data?) -> [Split] {
        guard let data, let codable = try? JSONDecoder().decode([CodableSplit].self, from: data) else {
            return []
        }
        return codable.map {
            Split(
                id: $0.id, kilometerNumber: $0.kilometerNumber,
                duration: $0.duration, elevationChangeM: $0.elevationChangeM,
                averageHeartRate: $0.averageHeartRate
            )
        }
    }

    private static func encodeParticipants(_ participants: [GroupChallengeParticipant]) -> Data {
        let codable = participants.map {
            CodableParticipant(
                id: $0.id, displayName: $0.displayName,
                currentValue: $0.currentValue, joinedDate: $0.joinedDate
            )
        }
        return (try? JSONEncoder().encode(codable)) ?? Data()
    }

    private static func decodeParticipants(_ data: Data?) -> [GroupChallengeParticipant] {
        guard let data,
              let codable = try? JSONDecoder().decode([CodableParticipant].self, from: data) else {
            return []
        }
        return codable.map {
            GroupChallengeParticipant(
                id: $0.id, displayName: $0.displayName,
                photoData: nil, currentValue: $0.currentValue, joinedDate: $0.joinedDate
            )
        }
    }
}
