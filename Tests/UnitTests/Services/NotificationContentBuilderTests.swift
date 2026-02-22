import Foundation
import Testing
@testable import UltraTrain

@Suite("NotificationContentBuilder Tests")
struct NotificationContentBuilderTests {

    private func makeSession(
        type: SessionType,
        distanceKm: Double = 0,
        elevationM: Double = 0
    ) -> TrainingSession {
        TrainingSession(
            id: UUID(),
            date: .now,
            type: type,
            plannedDistanceKm: distanceKm,
            plannedElevationGainM: elevationM,
            plannedDuration: 3600,
            intensity: .moderate,
            description: "Test session",
            isCompleted: false,
            isSkipped: false
        )
    }

    @Test("Training reminder body includes distance and elevation for long run")
    func trainingReminderBodyLongRun() {
        let session = makeSession(type: .longRun, distanceKm: 25.0, elevationM: 800)
        let body = NotificationContentBuilder.trainingReminderBody(session)

        #expect(body.contains("Long Run"))
        #expect(body.contains("25.0 km"))
        #expect(body.contains("800 m D+"))
        #expect(body.hasPrefix("Tomorrow:"))
    }

    @Test("Training reminder body omits distance and elevation when zero")
    func trainingReminderBodyRecovery() {
        let session = makeSession(type: .recovery)
        let body = NotificationContentBuilder.trainingReminderBody(session)

        #expect(body.contains("Recovery Run"))
        #expect(!body.contains("km"))
        #expect(!body.contains("D+"))
    }

    @Test("Race countdown body shows tomorrow when 1 day remaining")
    func raceCountdownOneDayRemaining() {
        let body = NotificationContentBuilder.raceCountdownBody(raceName: "UTMB", daysRemaining: 1)
        #expect(body.contains("tomorrow"))
        #expect(body.contains("UTMB"))
    }

    @Test("Race countdown body shows days when 5 days remaining")
    func raceCountdownFiveDays() {
        let body = NotificationContentBuilder.raceCountdownBody(raceName: "CCC", daysRemaining: 5)
        #expect(body.contains("5 days"))
        #expect(body.contains("CCC"))
    }

    @Test("Race countdown body shows weeks when 14 days remaining")
    func raceCountdownTwoWeeks() {
        let body = NotificationContentBuilder.raceCountdownBody(raceName: "OCC", daysRemaining: 14)
        #expect(body.contains("2 weeks"))
        #expect(body.contains("OCC"))
    }

    @Test("Recovery reminder body returns expected text")
    func recoveryReminderBody() {
        let body = NotificationContentBuilder.recoveryReminderBody()
        #expect(body.contains("Rest day"))
        #expect(body.contains("recover"))
    }

    @Test("Weekly summary body formats distance, elevation, and run count")
    func weeklySummaryBody() {
        let body = NotificationContentBuilder.weeklySummaryBody(
            distanceKm: 52.3, elevationM: 1200, runCount: 4
        )
        #expect(body.contains("52.3 km"))
        #expect(body.contains("1200 m D+"))
        #expect(body.contains("4 runs"))
    }

    @Test("Weekly summary body uses singular run for count of 1")
    func weeklySummaryBodySingularRun() {
        let body = NotificationContentBuilder.weeklySummaryBody(
            distanceKm: 10.0, elevationM: 200, runCount: 1
        )
        #expect(body.contains("1 run."))
    }
}
