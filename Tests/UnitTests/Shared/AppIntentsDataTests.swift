import Foundation
import Testing
@testable import UltraTrain

@Suite("App Intents Data Integration Tests")
struct AppIntentsDataTests {

    // MARK: - WidgetDataKeys Tests

    @Test("WidgetDataKeys has correct deep link key")
    func deepLinkKey() {
        #expect(WidgetDataKeys.deepLink == "widget.deepLink")
    }

    @Test("WidgetDataKeys has correct suite name")
    func suiteName() {
        #expect(WidgetDataKeys.suiteName == "group.com.ultratrain.shared")
    }

    @Test("All widget data keys are unique")
    func uniqueKeys() {
        let keys = [
            WidgetDataKeys.nextSession,
            WidgetDataKeys.raceCountdown,
            WidgetDataKeys.weeklyProgress,
            WidgetDataKeys.lastRun,
            WidgetDataKeys.fitnessData,
            WidgetDataKeys.pendingAction,
            WidgetDataKeys.deepLink,
        ]
        #expect(Set(keys).count == keys.count)
    }

    @Test("All widget data keys use widget prefix")
    func keyPrefix() {
        #expect(WidgetDataKeys.nextSession.hasPrefix("widget."))
        #expect(WidgetDataKeys.raceCountdown.hasPrefix("widget."))
        #expect(WidgetDataKeys.weeklyProgress.hasPrefix("widget."))
        #expect(WidgetDataKeys.lastRun.hasPrefix("widget."))
        #expect(WidgetDataKeys.fitnessData.hasPrefix("widget."))
        #expect(WidgetDataKeys.pendingAction.hasPrefix("widget."))
        #expect(WidgetDataKeys.deepLink.hasPrefix("widget."))
    }

    // MARK: - WidgetSessionData Tests

    @Test("WidgetSessionData encodes and decodes correctly")
    func sessionDataRoundTrip() throws {
        let sessionId = UUID()
        let data = WidgetSessionData(
            sessionId: sessionId,
            sessionType: "longRun",
            sessionIcon: "figure.run",
            displayName: "Long Run",
            description: "Steady state long run",
            plannedDistanceKm: 25.0,
            plannedElevationGainM: 800,
            plannedDuration: 7200,
            intensity: "moderate",
            date: Date(timeIntervalSince1970: 1700000000)
        )
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(WidgetSessionData.self, from: encoded)
        #expect(decoded.sessionId == sessionId)
        #expect(decoded.displayName == "Long Run")
        #expect(decoded.plannedDistanceKm == 25.0)
        #expect(decoded.plannedElevationGainM == 800)
        #expect(decoded.intensity == "moderate")
        #expect(decoded.sessionType == "longRun")
        #expect(decoded.sessionIcon == "figure.run")
        #expect(decoded.description == "Steady state long run")
        #expect(decoded.plannedDuration == 7200)
    }

    // MARK: - WidgetRaceData Tests

    @Test("WidgetRaceData encodes and decodes correctly")
    func raceDataRoundTrip() throws {
        let data = WidgetRaceData(
            name: "UTMB",
            date: Date(timeIntervalSince1970: 1700000000),
            distanceKm: 171,
            elevationGainM: 10000,
            planCompletionPercent: 75
        )
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(WidgetRaceData.self, from: encoded)
        #expect(decoded.name == "UTMB")
        #expect(decoded.distanceKm == 171)
        #expect(decoded.elevationGainM == 10000)
        #expect(decoded.planCompletionPercent == 75)
    }

    // MARK: - WidgetFitnessData Tests

    @Test("WidgetFitnessData encodes and decodes correctly")
    func fitnessDataRoundTrip() throws {
        let data = WidgetFitnessData(
            form: 30.0,
            fitness: 85.0,
            fatigue: 55.0,
            trend: [
                WidgetFitnessPoint(date: Date(timeIntervalSinceReferenceDate: 700000000), form: 28),
                WidgetFitnessPoint(date: Date(timeIntervalSinceReferenceDate: 700086400), form: 30),
            ]
        )
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(WidgetFitnessData.self, from: encoded)
        #expect(decoded.fitness == 85.0)
        #expect(decoded.fatigue == 55.0)
        #expect(decoded.form == 30.0)
        #expect(decoded.trend.count == 2)
        #expect(decoded.trend[0].form == 28)
        #expect(decoded.trend[1].form == 30)
    }

    // MARK: - WidgetWeeklyProgressData Tests

    @Test("WidgetWeeklyProgressData encodes and decodes correctly")
    func weeklyProgressRoundTrip() throws {
        let data = WidgetWeeklyProgressData(
            actualDistanceKm: 55.0,
            targetDistanceKm: 60.0,
            actualElevationGainM: 2000,
            targetElevationGainM: 2500,
            phase: "Build",
            weekNumber: 12
        )
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(WidgetWeeklyProgressData.self, from: encoded)
        #expect(decoded.weekNumber == 12)
        #expect(decoded.phase == "Build")
        #expect(decoded.actualDistanceKm == 55.0)
        #expect(decoded.targetDistanceKm == 60.0)
        #expect(decoded.actualElevationGainM == 2000)
        #expect(decoded.targetElevationGainM == 2500)
    }

    // MARK: - WidgetLastRunData Tests

    @Test("WidgetLastRunData encodes and decodes correctly")
    func lastRunDataRoundTrip() throws {
        let data = WidgetLastRunData(
            date: Date(timeIntervalSince1970: 1700000000),
            distanceKm: 15.5,
            elevationGainM: 450,
            duration: 5400,
            averagePaceSecondsPerKm: 360,
            averageHeartRate: 152
        )
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(WidgetLastRunData.self, from: encoded)
        #expect(decoded.distanceKm == 15.5)
        #expect(decoded.elevationGainM == 450)
        #expect(decoded.duration == 5400)
        #expect(decoded.averagePaceSecondsPerKm == 360)
        #expect(decoded.averageHeartRate == 152)
    }

    @Test("WidgetLastRunData handles nil average heart rate")
    func lastRunDataNilHeartRate() throws {
        let data = WidgetLastRunData(
            date: Date(timeIntervalSince1970: 1700000000),
            distanceKm: 10.0,
            elevationGainM: 200,
            duration: 3600,
            averagePaceSecondsPerKm: 360,
            averageHeartRate: nil
        )
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(WidgetLastRunData.self, from: encoded)
        #expect(decoded.averageHeartRate == nil)
        #expect(decoded.distanceKm == 10.0)
    }

    // MARK: - WidgetPendingAction Tests

    @Test("WidgetPendingAction encodes and decodes correctly")
    func pendingActionRoundTrip() throws {
        let sessionId = UUID()
        let data = WidgetPendingAction(
            sessionId: sessionId,
            action: "start",
            timestamp: Date(timeIntervalSince1970: 1700000000)
        )
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(WidgetPendingAction.self, from: encoded)
        #expect(decoded.sessionId == sessionId)
        #expect(decoded.action == "start")
    }
}
