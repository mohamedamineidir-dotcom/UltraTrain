import Foundation
import Testing
@testable import UltraTrain

@Suite("ActivityPublisher Tests")
struct ActivityPublisherTests {

    private func makeProfile() -> SocialProfile {
        SocialProfile(
            id: "athlete-1",
            displayName: "Trail Runner",
            bio: nil,
            profilePhotoData: nil,
            experienceLevel: .advanced,
            totalDistanceKm: 2000,
            totalElevationGainM: 100000,
            totalRuns: 300,
            joinedDate: Date.now,
            isPublicProfile: true
        )
    }

    private func makeRun(
        distanceKm: Double = 25.0,
        elevationGainM: Double = 1200,
        linkedRaceId: UUID? = nil,
        notes: String? = nil
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: Date.now,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 1100,
            duration: 7200,
            averageHeartRate: 145,
            maxHeartRate: 172,
            averagePaceSecondsPerKm: 288,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: linkedRaceId,
            notes: notes,
            pausedDuration: 0
        )
    }

    // MARK: - Activity Type

    @Test("Creates completedRun activity for regular run")
    func regularRunType() {
        let run = makeRun()
        let profile = makeProfile()
        let activity = ActivityPublisher.createActivity(from: run, athleteProfile: profile)

        #expect(activity.activityType == .completedRun)
    }

    @Test("Creates raceFinished activity when linkedRaceId is set")
    func raceFinishedType() {
        let run = makeRun(linkedRaceId: UUID())
        let profile = makeProfile()
        let activity = ActivityPublisher.createActivity(from: run, athleteProfile: profile)

        #expect(activity.activityType == .raceFinished)
    }

    // MARK: - Title Formatting

    @Test("Title includes distance for completed run")
    func titleIncludesDistance() {
        let run = makeRun(distanceKm: 42.2)
        let profile = makeProfile()
        let activity = ActivityPublisher.createActivity(from: run, athleteProfile: profile)

        #expect(activity.title.contains("42.2 km"))
        #expect(activity.title.contains("Completed"))
    }

    @Test("Title includes distance for race finish")
    func titleIncludesDistanceForRace() {
        let run = makeRun(distanceKm: 100.0, linkedRaceId: UUID())
        let profile = makeProfile()
        let activity = ActivityPublisher.createActivity(from: run, athleteProfile: profile)

        #expect(activity.title.contains("100.0 km"))
        #expect(activity.title.contains("race"))
    }

    // MARK: - Subtitle

    @Test("Subtitle includes elevation and notes")
    func subtitleWithElevationAndNotes() {
        let run = makeRun(elevationGainM: 1500, notes: "Great trail conditions")
        let profile = makeProfile()
        let activity = ActivityPublisher.createActivity(from: run, athleteProfile: profile)

        #expect(activity.subtitle != nil)
        #expect(activity.subtitle?.contains("1500 m D+") == true)
        #expect(activity.subtitle?.contains("Great trail conditions") == true)
    }

    @Test("Subtitle is nil when no elevation and no notes")
    func subtitleNilWithoutElevationOrNotes() {
        let run = makeRun(elevationGainM: 0, notes: nil)
        let profile = makeProfile()
        let activity = ActivityPublisher.createActivity(from: run, athleteProfile: profile)

        #expect(activity.subtitle == nil)
    }

    // MARK: - Stats & Metadata

    @Test("Activity includes correct stats from run")
    func activityStats() {
        let run = makeRun(distanceKm: 30.0, elevationGainM: 2000)
        let profile = makeProfile()
        let activity = ActivityPublisher.createActivity(from: run, athleteProfile: profile)

        #expect(activity.stats?.distanceKm == 30.0)
        #expect(activity.stats?.elevationGainM == 2000)
        #expect(activity.stats?.duration == 7200)
        #expect(activity.stats?.averagePace == 288)
    }

    @Test("Activity uses profile data correctly")
    func activityUsesProfile() {
        let run = makeRun()
        let profile = makeProfile()
        let activity = ActivityPublisher.createActivity(from: run, athleteProfile: profile)

        #expect(activity.athleteProfileId == "athlete-1")
        #expect(activity.athleteDisplayName == "Trail Runner")
        #expect(activity.likeCount == 0)
        #expect(activity.isLikedByMe == false)
    }
}
