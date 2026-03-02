import Foundation
import Testing
@testable import UltraTrain

/// Tests for the shared types and message encoding/decoding that support
/// WatchConnectivityService. The service itself lives in the Watch extension
/// target, so we test the WatchMessageCoder, WatchCommand, and the
/// application context data models that flow through connectivity.
@Suite("Watch Connectivity Service Supporting Logic Tests")
struct WatchConnectivityServiceTests {

    // MARK: - Command Encoding

    @Test("WatchCommand encodes and decodes through message dictionary")
    func commandRoundTrip() {
        for command in [WatchCommand.pause, .resume, .stop, .dismissReminder] {
            let message = WatchMessageCoder.encodeCommand(command)
            let decoded = WatchMessageCoder.decodeCommand(message)
            #expect(decoded == command)
        }
    }

    @Test("Decoding a command from an invalid message returns nil")
    func invalidCommandReturnsNil() {
        let emptyMessage: [String: Any] = [:]
        #expect(WatchMessageCoder.decodeCommand(emptyMessage) == nil)

        let wrongKey: [String: Any] = ["wrongKey": "pause"]
        #expect(WatchMessageCoder.decodeCommand(wrongKey) == nil)

        let invalidValue: [String: Any] = ["command": "invalidCommand"]
        #expect(WatchMessageCoder.decodeCommand(invalidValue) == nil)
    }

    // MARK: - Session Data Encoding

    @Test("WatchSessionData round-trips through application context encoding")
    func sessionDataRoundTrip() {
        let sessionId = UUID()
        let session = WatchSessionData(
            sessionId: sessionId,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            type: "longRun",
            plannedDistanceKm: 25,
            plannedElevationGainM: 800,
            plannedDuration: 7200,
            intensity: "moderate",
            description: "Easy long run",
            maxHeartRate: 185,
            restingHeartRate: 55
        )

        let context = WatchMessageCoder.encodeSessionData(session)
        let decoded = WatchMessageCoder.decodeSessionData(context)

        #expect(decoded != nil)
        #expect(decoded?.sessionId == sessionId)
        #expect(decoded?.type == "longRun")
        #expect(decoded?.plannedDistanceKm == 25)
        #expect(decoded?.maxHeartRate == 185)
        #expect(decoded?.restingHeartRate == 55)
    }

    // MARK: - Completed Run Encoding

    @Test("WatchCompletedRunData round-trips through transferUserInfo encoding")
    func completedRunRoundTrip() {
        let runId = UUID()
        let linkedSessionId = UUID()
        let data = WatchCompletedRunData(
            runId: runId,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            distanceKm: 18.5,
            elevationGainM: 650,
            elevationLossM: 400,
            duration: 5400,
            pausedDuration: 90,
            averageHeartRate: 148,
            maxHeartRate: 172,
            averagePaceSecondsPerKm: 292,
            trackPoints: [
                WatchTrackPoint(
                    latitude: 45.0, longitude: 6.0, altitudeM: 1000,
                    timestamp: Date(timeIntervalSince1970: 1_700_000_000),
                    heartRate: 140
                )
            ],
            splits: [],
            linkedSessionId: linkedSessionId
        )

        let userInfo = WatchMessageCoder.encodeCompletedRun(data)
        let decoded = WatchMessageCoder.decodeCompletedRun(userInfo)

        #expect(decoded != nil)
        #expect(decoded?.runId == runId)
        #expect(decoded?.distanceKm == 18.5)
        #expect(decoded?.elevationGainM == 650)
        #expect(decoded?.linkedSessionId == linkedSessionId)
        #expect(decoded?.trackPoints.count == 1)
    }

    // MARK: - Complication Data Encoding

    @Test("WatchComplicationData round-trips through application context encoding")
    func complicationDataRoundTrip() {
        let data = WatchComplicationData(
            nextSessionType: "Intervals",
            nextSessionIcon: "timer",
            nextSessionDistanceKm: 12.0,
            nextSessionDate: Date(timeIntervalSince1970: 1_700_100_000),
            raceCountdownDays: 28,
            raceName: "UTMB"
        )

        let context = WatchMessageCoder.encodeComplicationData(data)
        let decoded = WatchMessageCoder.decodeComplicationData(context)

        #expect(decoded != nil)
        #expect(decoded?.nextSessionType == "Intervals")
        #expect(decoded?.nextSessionIcon == "timer")
        #expect(decoded?.nextSessionDistanceKm == 12.0)
        #expect(decoded?.raceCountdownDays == 28)
        #expect(decoded?.raceName == "UTMB")
    }

    // MARK: - Merged Application Context

    @Test("mergeApplicationContext combines multiple data types into one dictionary")
    func mergedContextContainsAllKeys() {
        let runData = WatchRunData(
            runState: "running",
            elapsedTime: 3600,
            distanceKm: 10,
            currentPace: "6:00",
            currentHeartRate: 150,
            elevationGainM: 300,
            formattedTime: "1:00:00",
            formattedDistance: "10.00",
            formattedElevation: "+300 m",
            isAutoPaused: false,
            activeReminderMessage: nil,
            activeReminderType: nil
        )

        let sessionData = WatchSessionData(
            sessionId: UUID(),
            date: .now,
            type: "tempo",
            plannedDistanceKm: 15,
            plannedElevationGainM: 200,
            plannedDuration: 4500,
            intensity: "hard",
            description: "Tempo run",
            maxHeartRate: 185,
            restingHeartRate: 55
        )

        let complicationData = WatchComplicationData(raceName: "CCC")

        let merged = WatchMessageCoder.mergeApplicationContext(
            runData: runData,
            sessionData: sessionData,
            complicationData: complicationData
        )

        // All three keys should be present
        let decodedRun = WatchMessageCoder.decodeRunData(merged)
        let decodedSession = WatchMessageCoder.decodeSessionData(merged)
        let decodedComplication = WatchMessageCoder.decodeComplicationData(merged)

        #expect(decodedRun != nil)
        #expect(decodedRun?.runState == "running")
        #expect(decodedSession != nil)
        #expect(decodedSession?.type == "tempo")
        #expect(decodedComplication != nil)
        #expect(decodedComplication?.raceName == "CCC")
    }
}
