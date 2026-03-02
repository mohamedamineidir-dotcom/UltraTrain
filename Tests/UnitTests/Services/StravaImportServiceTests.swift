import Foundation
import Testing
@testable import UltraTrain

@Suite("StravaImportService Tests")
struct StravaImportServiceTests {

    private let athleteId = UUID()

    // MARK: - Helpers

    private func makeSampleActivity(
        id: Int = 1001,
        name: String = "Morning Trail Run",
        type: String = "TrailRun",
        startDate: Date = Date(),
        distanceMeters: Double = 15000,
        movingTimeSeconds: Int = 5400,
        totalElevationGain: Double = 850,
        averageHeartRate: Double? = 155,
        maxHeartRate: Double? = 180,
        isImported: Bool = false
    ) -> StravaActivity {
        StravaActivity(
            id: id,
            name: name,
            type: type,
            startDate: startDate,
            distanceMeters: distanceMeters,
            movingTimeSeconds: movingTimeSeconds,
            totalElevationGain: totalElevationGain,
            averageHeartRate: averageHeartRate,
            maxHeartRate: maxHeartRate,
            isImported: isImported
        )
    }

    private func makeMockService(
        shouldThrow: Bool = false,
        activities: [StravaActivity] = []
    ) -> MockStravaImportService {
        let mock = MockStravaImportService()
        mock.shouldThrow = shouldThrow
        mock.activities = activities
        return mock
    }

    // MARK: - fetchActivities

    @Test("fetchActivities returns list of activities")
    func fetchActivitiesReturnsActivities() async throws {
        let activities = [
            makeSampleActivity(id: 1, name: "Run 1"),
            makeSampleActivity(id: 2, name: "Run 2"),
            makeSampleActivity(id: 3, name: "Run 3")
        ]
        let service = makeMockService(activities: activities)

        let result = try await service.fetchActivities(page: 1, perPage: 30)

        #expect(result.count == 3)
        #expect(result[0].name == "Run 1")
        #expect(result[2].name == "Run 3")
    }

    @Test("fetchActivities returns empty array when none available")
    func fetchActivitiesReturnsEmpty() async throws {
        let service = makeMockService(activities: [])

        let result = try await service.fetchActivities(page: 1, perPage: 30)

        #expect(result.isEmpty)
    }

    @Test("fetchActivities throws on failure")
    func fetchActivitiesThrows() async {
        let service = makeMockService(shouldThrow: true)

        await #expect(throws: DomainError.self) {
            try await service.fetchActivities(page: 1, perPage: 30)
        }
    }

    // MARK: - importActivity

    @Test("importActivity returns a CompletedRun with correct data")
    func importActivityReturnsRun() async throws {
        let activity = makeSampleActivity(
            id: 42,
            name: "UTMB Training",
            type: "TrailRun",
            distanceMeters: 21000,
            movingTimeSeconds: 7200,
            totalElevationGain: 1200
        )
        let service = makeMockService()

        let run = try await service.importActivity(activity, athleteId: athleteId)

        #expect(run.athleteId == athleteId)
        #expect(run.distanceKm == 21.0)
        #expect(run.elevationGainM == 1200)
        #expect(run.duration == 7200)
        #expect(run.isStravaImport == true)
        #expect(run.stravaActivityId == 42)
        #expect(run.notes?.contains("UTMB Training") == true)
    }

    @Test("importActivity stores the imported activity in mock")
    func importActivityStoresActivity() async throws {
        let activity = makeSampleActivity(id: 99, name: "Test Import")
        let service = makeMockService()

        _ = try await service.importActivity(activity, athleteId: athleteId)

        #expect(service.importedActivity?.id == 99)
        #expect(service.importedActivity?.name == "Test Import")
    }

    @Test("importActivity throws on failure")
    func importActivityThrows() async {
        let activity = makeSampleActivity()
        let service = makeMockService(shouldThrow: true)

        await #expect(throws: DomainError.self) {
            try await service.importActivity(activity, athleteId: athleteId)
        }
    }

    // MARK: - StravaActivity model

    @Test("StravaActivity distanceKm computes correctly from meters")
    func distanceKmComputation() {
        let activity = makeSampleActivity(distanceMeters: 42195)
        #expect(activity.distanceKm == 42.195)
    }

    @Test("StravaActivity formattedDuration shows hours and minutes for long runs")
    func formattedDurationLongRun() {
        let activity = makeSampleActivity(movingTimeSeconds: 7260) // 2h 1m
        #expect(activity.formattedDuration == "2h 01m")
    }

    @Test("StravaActivity formattedDuration shows minutes only for short runs")
    func formattedDurationShortRun() {
        let activity = makeSampleActivity(movingTimeSeconds: 1800) // 30m
        #expect(activity.formattedDuration == "30m")
    }
}
