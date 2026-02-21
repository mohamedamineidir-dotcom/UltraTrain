import Foundation
import CloudKit
import os

enum CloudKitRecordConverter {

    // MARK: - Record Type Constants

    static let socialProfileType = "SocialProfile"
    static let friendConnectionType = "FriendConnection"
    static let sharedRunType = "SharedRun"
    static let activityFeedItemType = "ActivityFeedItem"
    static let crewSessionType = "CrewTrackingSession"
    static let crewParticipantType = "CrewParticipant"
    static let groupChallengeType = "GroupChallenge"

    // MARK: - SocialProfile

    static func toRecord(_ profile: SocialProfile) -> CKRecord {
        let record = CKRecord(recordType: socialProfileType, recordID: .init(recordName: profile.id))
        record["displayName"] = profile.displayName
        record["bio"] = profile.bio
        if let photoData = profile.profilePhotoData {
            record["profilePhoto"] = createAsset(from: photoData, filename: "profile_\(profile.id).jpg")
        }
        record["experienceLevel"] = profile.experienceLevel.rawValue
        record["totalDistanceKm"] = profile.totalDistanceKm
        record["totalElevationGainM"] = profile.totalElevationGainM
        record["totalRuns"] = profile.totalRuns
        record["joinedDate"] = profile.joinedDate
        record["isPublicProfile"] = profile.isPublicProfile ? 1 : 0
        return record
    }

    static func toSocialProfile(_ record: CKRecord) -> SocialProfile? {
        guard record.recordType == socialProfileType,
              let displayName = record["displayName"] as? String,
              let levelRaw = record["experienceLevel"] as? String,
              let level = ExperienceLevel(rawValue: levelRaw) else { return nil }

        return SocialProfile(
            id: record.recordID.recordName,
            displayName: displayName,
            bio: record["bio"] as? String,
            profilePhotoData: readAsset(record["profilePhoto"] as? CKAsset),
            experienceLevel: level,
            totalDistanceKm: record["totalDistanceKm"] as? Double ?? 0,
            totalElevationGainM: record["totalElevationGainM"] as? Double ?? 0,
            totalRuns: record["totalRuns"] as? Int ?? 0,
            joinedDate: record["joinedDate"] as? Date ?? Date.distantPast,
            isPublicProfile: (record["isPublicProfile"] as? Int64 ?? 0) == 1
        )
    }

    // MARK: - FriendConnection

    static func toRecord(_ connection: FriendConnection, myProfileId: String) -> CKRecord {
        let record = CKRecord(
            recordType: friendConnectionType,
            recordID: .init(recordName: connection.id.uuidString)
        )
        record["requesterProfileId"] = myProfileId
        record["targetProfileId"] = connection.friendProfileId
        record["requesterDisplayName"] = ""
        record["targetDisplayName"] = connection.friendDisplayName
        record["statusRaw"] = connection.status.rawValue
        record["createdDate"] = connection.createdDate
        record["acceptedDate"] = connection.acceptedDate
        return record
    }

    static func toFriendConnection(_ record: CKRecord, myProfileId: String) -> FriendConnection? {
        guard record.recordType == friendConnectionType,
              let idString = record.recordID.recordName as String?,
              let uuid = UUID(uuidString: idString),
              let requester = record["requesterProfileId"] as? String,
              let target = record["targetProfileId"] as? String,
              let statusRaw = record["statusRaw"] as? String,
              let status = FriendStatus(rawValue: statusRaw) else { return nil }

        let iAmRequester = requester == myProfileId
        let friendId = iAmRequester ? target : requester
        let friendName = iAmRequester
            ? (record["targetDisplayName"] as? String ?? "")
            : (record["requesterDisplayName"] as? String ?? "")

        return FriendConnection(
            id: uuid,
            friendProfileId: friendId,
            friendDisplayName: friendName,
            friendPhotoData: nil,
            status: status,
            createdDate: record["createdDate"] as? Date ?? Date.distantPast,
            acceptedDate: record["acceptedDate"] as? Date
        )
    }

    // MARK: - SharedRun

    static func toRecord(_ run: SharedRun) -> CKRecord {
        let record = CKRecord(
            recordType: sharedRunType,
            recordID: .init(recordName: run.id.uuidString)
        )
        record["sharedByProfileId"] = run.sharedByProfileId
        record["sharedByDisplayName"] = run.sharedByDisplayName
        record["date"] = run.date
        record["distanceKm"] = run.distanceKm
        record["elevationGainM"] = run.elevationGainM
        record["elevationLossM"] = run.elevationLossM
        record["duration"] = run.duration
        record["averagePaceSecondsPerKm"] = run.averagePaceSecondsPerKm
        record["notes"] = run.notes
        record["sharedAt"] = run.sharedAt
        record["likeCount"] = run.likeCount
        record["commentCount"] = run.commentCount

        let trackData = encodeTrackPoints(run.gpsTrack)
        if !trackData.isEmpty {
            record["gpsTrack"] = createAsset(from: trackData, filename: "track_\(run.id).json")
        }
        let splitsData = encodeSplits(run.splits)
        if !splitsData.isEmpty {
            record["splits"] = createAsset(from: splitsData, filename: "splits_\(run.id).json")
        }
        return record
    }

    static func toSharedRun(_ record: CKRecord) -> SharedRun? {
        guard record.recordType == sharedRunType,
              let uuid = UUID(uuidString: record.recordID.recordName),
              let profileId = record["sharedByProfileId"] as? String,
              let displayName = record["sharedByDisplayName"] as? String else { return nil }

        return SharedRun(
            id: uuid,
            sharedByProfileId: profileId,
            sharedByDisplayName: displayName,
            date: record["date"] as? Date ?? Date.distantPast,
            distanceKm: record["distanceKm"] as? Double ?? 0,
            elevationGainM: record["elevationGainM"] as? Double ?? 0,
            elevationLossM: record["elevationLossM"] as? Double ?? 0,
            duration: record["duration"] as? Double ?? 0,
            averagePaceSecondsPerKm: record["averagePaceSecondsPerKm"] as? Double ?? 0,
            gpsTrack: decodeTrackPoints(readAsset(record["gpsTrack"] as? CKAsset)),
            splits: decodeSplits(readAsset(record["splits"] as? CKAsset)),
            notes: record["notes"] as? String,
            sharedAt: record["sharedAt"] as? Date ?? Date.distantPast,
            likeCount: record["likeCount"] as? Int ?? 0,
            commentCount: record["commentCount"] as? Int ?? 0
        )
    }

    // MARK: - ActivityFeedItem

    static func toRecord(_ item: ActivityFeedItem) -> CKRecord {
        let record = CKRecord(
            recordType: activityFeedItemType,
            recordID: .init(recordName: item.id.uuidString)
        )
        record["athleteProfileId"] = item.athleteProfileId
        record["athleteDisplayName"] = item.athleteDisplayName
        record["activityTypeRaw"] = item.activityType.rawValue
        record["title"] = item.title
        record["subtitle"] = item.subtitle
        record["statsDistanceKm"] = item.stats?.distanceKm
        record["statsElevationGainM"] = item.stats?.elevationGainM
        record["statsDuration"] = item.stats?.duration
        record["statsAveragePace"] = item.stats?.averagePace
        record["timestamp"] = item.timestamp
        record["likeCount"] = item.likeCount
        return record
    }

    static func toActivityFeedItem(_ record: CKRecord) -> ActivityFeedItem? {
        guard record.recordType == activityFeedItemType,
              let uuid = UUID(uuidString: record.recordID.recordName),
              let profileId = record["athleteProfileId"] as? String,
              let displayName = record["athleteDisplayName"] as? String,
              let typeRaw = record["activityTypeRaw"] as? String,
              let activityType = ActivityType(rawValue: typeRaw),
              let title = record["title"] as? String else { return nil }

        let stats: ActivityStats? = {
            let d = record["statsDistanceKm"] as? Double
            let e = record["statsElevationGainM"] as? Double
            let dur = record["statsDuration"] as? Double
            let p = record["statsAveragePace"] as? Double
            guard d != nil || e != nil || dur != nil || p != nil else { return nil }
            return ActivityStats(distanceKm: d, elevationGainM: e, duration: dur, averagePace: p)
        }()

        return ActivityFeedItem(
            id: uuid,
            athleteProfileId: profileId,
            athleteDisplayName: displayName,
            athletePhotoData: nil,
            activityType: activityType,
            title: title,
            subtitle: record["subtitle"] as? String,
            stats: stats,
            timestamp: record["timestamp"] as? Date ?? Date.distantPast,
            likeCount: record["likeCount"] as? Int ?? 0,
            isLikedByMe: false
        )
    }
}
