import Testing
import Foundation
import CloudKit
@testable import UltraTrain

@Suite("CloudKitRecordConverter Tests")
struct CloudKitRecordConverterTests {
    private let date1 = Date(timeIntervalSince1970: 1_700_000_000)
    private let date2 = Date(timeIntervalSince1970: 1_700_100_000)

    // MARK: - SocialProfile

    @Test("SocialProfile roundtrips through CKRecord preserving all fields")
    func testSocialProfileRoundtrip() {
        let profile = SocialProfile(
            id: "athlete-42", displayName: "Kilian J", bio: "Mountain runner",
            profilePhotoData: nil, experienceLevel: .elite, totalDistanceKm: 12345.6,
            totalElevationGainM: 890_000, totalRuns: 2100, joinedDate: date1, isPublicProfile: true
        )
        let record = CloudKitRecordConverter.toRecord(profile)
        let r = CloudKitRecordConverter.toSocialProfile(record)
        #expect(r != nil)
        #expect(r?.id == "athlete-42")
        #expect(r?.displayName == "Kilian J")
        #expect(r?.bio == "Mountain runner")
        #expect(r?.experienceLevel == .elite)
        #expect(r?.totalDistanceKm == 12345.6)
        #expect(r?.totalElevationGainM == 890_000)
        #expect(r?.totalRuns == 2100)
        #expect(r?.joinedDate == date1)
        #expect(r?.isPublicProfile == true)
    }

    // MARK: - FriendConnection

    @Test("FriendConnection roundtrips when I am the requester")
    func testFriendConnectionRoundtripAsRequester() {
        let connId = UUID(uuidString: "AABBCCDD-1122-3344-5566-778899AABBCC")!
        let connection = FriendConnection(
            id: connId, friendProfileId: "friend-456", friendDisplayName: "Trail Buddy",
            friendPhotoData: nil, status: .accepted, createdDate: date1, acceptedDate: date2
        )
        let record = CloudKitRecordConverter.toRecord(connection, myProfileId: "me-123")
        let r = CloudKitRecordConverter.toFriendConnection(record, myProfileId: "me-123")
        #expect(r != nil)
        #expect(r?.id == connId)
        #expect(r?.friendProfileId == "friend-456")
        #expect(r?.friendDisplayName == "Trail Buddy")
        #expect(r?.status == .accepted)
        #expect(r?.createdDate == date1)
        #expect(r?.acceptedDate == date2)
    }

    @Test("FriendConnection perspective flips when read as the target")
    func testFriendConnectionRoundtripAsTarget() {
        let connection = FriendConnection(
            id: UUID(uuidString: "11223344-5566-7788-99AA-BBCCDDEEFF00")!,
            friendProfileId: "target-222", friendDisplayName: "Target Name",
            friendPhotoData: nil, status: .pending, createdDate: date1, acceptedDate: nil
        )
        let record = CloudKitRecordConverter.toRecord(connection, myProfileId: "requester-111")
        let r = CloudKitRecordConverter.toFriendConnection(record, myProfileId: "target-222")
        #expect(r != nil)
        #expect(r?.friendProfileId == "requester-111")
        #expect(r?.status == .pending)
        #expect(r?.acceptedDate == nil)
    }

    // MARK: - SharedRun

    @Test("SharedRun roundtrips with GPS track points and splits")
    func testSharedRunRoundtrip() {
        let trackPoints = [
            TrackPoint(latitude: 45.8326, longitude: 6.8652, altitudeM: 1035,
                       timestamp: date1, heartRate: 145),
            TrackPoint(latitude: 45.8330, longitude: 6.8660, altitudeM: 1042,
                       timestamp: date2, heartRate: 150)
        ]
        let splitId = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let splits = [Split(id: splitId, kilometerNumber: 1, duration: 360,
                            elevationChangeM: 50, averageHeartRate: 148)]
        let runId = UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!
        let run = SharedRun(
            id: runId, sharedByProfileId: "runner-99", sharedByDisplayName: "Ultra Runner",
            date: date1, distanceKm: 42.5, elevationGainM: 2800, elevationLossM: 2750,
            duration: 18000, averagePaceSecondsPerKm: 423.5, gpsTrack: trackPoints,
            splits: splits, notes: "Great UTMB training run", sharedAt: date2,
            likeCount: 12, commentCount: 3
        )
        let record = CloudKitRecordConverter.toRecord(run)
        let r = CloudKitRecordConverter.toSharedRun(record)
        #expect(r != nil)
        #expect(r?.id == runId)
        #expect(r?.sharedByProfileId == "runner-99")
        #expect(r?.sharedByDisplayName == "Ultra Runner")
        #expect(r?.date == date1)
        #expect(r?.distanceKm == 42.5)
        #expect(r?.elevationGainM == 2800)
        #expect(r?.elevationLossM == 2750)
        #expect(r?.duration == 18000)
        #expect(r?.averagePaceSecondsPerKm == 423.5)
        #expect(r?.notes == "Great UTMB training run")
        #expect(r?.sharedAt == date2)
        #expect(r?.likeCount == 12)
        #expect(r?.commentCount == 3)
        #expect(r?.gpsTrack.count == 2)
        #expect(r?.gpsTrack[0].latitude == 45.8326)
        #expect(r?.gpsTrack[0].heartRate == 145)
        #expect(r?.gpsTrack[1].altitudeM == 1042)
        #expect(r?.splits.count == 1)
        #expect(r?.splits[0].id == splitId)
        #expect(r?.splits[0].kilometerNumber == 1)
        #expect(r?.splits[0].duration == 360)
        #expect(r?.splits[0].elevationChangeM == 50)
        #expect(r?.splits[0].averageHeartRate == 148)
    }

    // MARK: - ActivityFeedItem

    @Test("ActivityFeedItem roundtrips with stats")
    func testActivityFeedItemRoundtrip() {
        let stats = ActivityStats(distanceKm: 25.3, elevationGainM: 1500,
                                  duration: 10800, averagePace: 426.9)
        let itemId = UUID(uuidString: "FEDCBA98-7654-3210-FEDC-BA9876543210")!
        let item = ActivityFeedItem(
            id: itemId, athleteProfileId: "athlete-7", athleteDisplayName: "Mountain Goat",
            athletePhotoData: nil, activityType: .completedRun, title: "Morning Trail Run",
            subtitle: "Chamonix Valley", stats: stats, timestamp: date1,
            likeCount: 5, isLikedByMe: true
        )
        let record = CloudKitRecordConverter.toRecord(item)
        let r = CloudKitRecordConverter.toActivityFeedItem(record)
        #expect(r != nil)
        #expect(r?.id == itemId)
        #expect(r?.athleteProfileId == "athlete-7")
        #expect(r?.athleteDisplayName == "Mountain Goat")
        #expect(r?.activityType == .completedRun)
        #expect(r?.title == "Morning Trail Run")
        #expect(r?.subtitle == "Chamonix Valley")
        #expect(r?.timestamp == date1)
        #expect(r?.likeCount == 5)
        #expect(r?.stats?.distanceKm == 25.3)
        #expect(r?.stats?.elevationGainM == 1500)
        #expect(r?.stats?.duration == 10800)
        #expect(r?.stats?.averagePace == 426.9)
        // isLikedByMe and athletePhotoData are not stored in CKRecord
        #expect(r?.isLikedByMe == false)
        #expect(r?.athletePhotoData == nil)
    }

    @Test("ActivityFeedItem roundtrips with nil stats")
    func testActivityFeedItemWithoutStats() {
        let item = ActivityFeedItem(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
            athleteProfileId: "athlete-8", athleteDisplayName: "Trail Newbie",
            athletePhotoData: nil, activityType: .friendJoined, title: "Joined UltraTrain",
            subtitle: nil, stats: nil, timestamp: date1, likeCount: 0, isLikedByMe: false
        )
        let record = CloudKitRecordConverter.toRecord(item)
        let r = CloudKitRecordConverter.toActivityFeedItem(record)
        #expect(r != nil)
        #expect(r?.stats == nil)
        #expect(r?.subtitle == nil)
        #expect(r?.activityType == .friendJoined)
        #expect(r?.title == "Joined UltraTrain")
    }

    // MARK: - CrewTrackingSession

    @Test("CrewTrackingSession roundtrips with separate participants")
    func testCrewSessionRoundtrip() {
        let sessionId = UUID(uuidString: "CCCCCCCC-DDDD-EEEE-FFFF-000000000000")!
        let participants = [
            CrewParticipant(id: "crew-1", displayName: "Pacer", latitude: 45.9,
                            longitude: 6.87, distanceKm: 15.2,
                            currentPaceSecondsPerKm: 390, lastUpdated: date1),
            CrewParticipant(id: "crew-2", displayName: "Support", latitude: 45.91,
                            longitude: 6.88, distanceKm: 0,
                            currentPaceSecondsPerKm: 0, lastUpdated: date2)
        ]
        let session = CrewTrackingSession(
            id: sessionId, hostProfileId: "host-1", hostDisplayName: "Race Director",
            startedAt: date1, status: .active, participants: participants
        )
        let record = CloudKitRecordConverter.toRecord(session)
        let r = CloudKitRecordConverter.toCrewTrackingSession(record, participants: participants)
        #expect(r != nil)
        #expect(r?.id == sessionId)
        #expect(r?.hostProfileId == "host-1")
        #expect(r?.hostDisplayName == "Race Director")
        #expect(r?.startedAt == date1)
        #expect(r?.status == .active)
        #expect(r?.participants.count == 2)
        #expect(r?.participants[0].displayName == "Pacer")
        #expect(r?.participants[1].displayName == "Support")
    }

    // MARK: - CrewParticipant

    @Test("CrewParticipant roundtrips preserving role")
    func testCrewParticipantRoundtrip() {
        let sessionId = UUID(uuidString: "DDDDDDDD-EEEE-FFFF-0000-111111111111")!
        let participant = CrewParticipant(
            id: "pacer-42", displayName: "Elite Pacer", latitude: 45.832,
            longitude: 6.865, distanceKm: 30.7,
            currentPaceSecondsPerKm: 350, lastUpdated: date1
        )
        let record = CloudKitRecordConverter.toRecord(
            participant, sessionId: sessionId, role: "pacer"
        )
        let result = CloudKitRecordConverter.toCrewParticipant(record)
        #expect(result != nil)
        let (restored, role) = result!
        #expect(role == "pacer")
        #expect(restored.id == "pacer-42")
        #expect(restored.displayName == "Elite Pacer")
        #expect(restored.latitude == 45.832)
        #expect(restored.longitude == 6.865)
        #expect(restored.distanceKm == 30.7)
        #expect(restored.currentPaceSecondsPerKm == 350)
        #expect(restored.lastUpdated == date1)
    }

    // MARK: - GroupChallenge

    @Test("GroupChallenge roundtrips with participants via CKAsset")
    func testGroupChallengeRoundtrip() {
        let challengeId = UUID(uuidString: "EEEEEEEE-FFFF-0000-1111-222222222222")!
        let participants = [
            GroupChallengeParticipant(id: "p-1", displayName: "Runner A",
                                     photoData: nil, currentValue: 120.5, joinedDate: date1),
            GroupChallengeParticipant(id: "p-2", displayName: "Runner B",
                                     photoData: nil, currentValue: 95.0, joinedDate: date2)
        ]
        let challenge = GroupChallenge(
            id: challengeId, creatorProfileId: "creator-1",
            creatorDisplayName: "Challenge Creator", name: "Monthly Distance",
            descriptionText: "Run 200km this month", type: .distance, targetValue: 200,
            startDate: date1, endDate: date2, status: .active, participants: participants
        )
        let record = CloudKitRecordConverter.toRecord(challenge)
        let r = CloudKitRecordConverter.toGroupChallenge(record)
        #expect(r != nil)
        #expect(r?.id == challengeId)
        #expect(r?.creatorProfileId == "creator-1")
        #expect(r?.creatorDisplayName == "Challenge Creator")
        #expect(r?.name == "Monthly Distance")
        #expect(r?.descriptionText == "Run 200km this month")
        #expect(r?.type == .distance)
        #expect(r?.targetValue == 200)
        #expect(r?.startDate == date1)
        #expect(r?.endDate == date2)
        #expect(r?.status == .active)
        #expect(r?.participants.count == 2)
        #expect(r?.participants[0].id == "p-1")
        #expect(r?.participants[0].displayName == "Runner A")
        #expect(r?.participants[0].currentValue == 120.5)
        #expect(r?.participants[1].id == "p-2")
        #expect(r?.participants[1].displayName == "Runner B")
        #expect(r?.participants[1].currentValue == 95.0)
        #expect(r?.participants[0].photoData == nil)
    }

    // MARK: - Invalid Record

    @Test("Converter returns nil for wrong record type")
    func testInvalidRecordReturnsNil() {
        let wrongRecord = CKRecord(recordType: "WrongType")
        #expect(CloudKitRecordConverter.toSocialProfile(wrongRecord) == nil)
        #expect(CloudKitRecordConverter.toFriendConnection(wrongRecord, myProfileId: "x") == nil)
        #expect(CloudKitRecordConverter.toSharedRun(wrongRecord) == nil)
        #expect(CloudKitRecordConverter.toActivityFeedItem(wrongRecord) == nil)
        #expect(CloudKitRecordConverter.toCrewTrackingSession(wrongRecord, participants: []) == nil)
        #expect(CloudKitRecordConverter.toCrewParticipant(wrongRecord) == nil)
        #expect(CloudKitRecordConverter.toGroupChallenge(wrongRecord) == nil)
    }
}
