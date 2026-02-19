import Foundation
import Testing
@testable import UltraTrain

@Suite("Widget Data Encoding Tests")
struct WidgetDataTests {

    @Test("WidgetFitnessData round-trip encode/decode")
    func fitnessDataRoundTrip() throws {
        let data = WidgetFitnessData(
            form: 12.5,
            fitness: 65.3,
            fatigue: 52.8,
            trend: [
                WidgetFitnessPoint(date: Date(timeIntervalSinceReferenceDate: 700000000), form: 10),
                WidgetFitnessPoint(date: Date(timeIntervalSinceReferenceDate: 700086400), form: 14),
            ]
        )

        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(WidgetFitnessData.self, from: encoded)

        #expect(decoded.form == 12.5)
        #expect(decoded.fitness == 65.3)
        #expect(decoded.fatigue == 52.8)
        #expect(decoded.trend.count == 2)
        #expect(decoded.trend[0].form == 10)
        #expect(decoded.trend[1].form == 14)
    }

    @Test("WidgetPendingAction round-trip encode/decode")
    func pendingActionRoundTrip() throws {
        let sessionId = UUID()
        let data = WidgetPendingAction(
            sessionId: sessionId,
            action: "complete",
            timestamp: Date(timeIntervalSinceReferenceDate: 700000000)
        )

        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(WidgetPendingAction.self, from: encoded)

        #expect(decoded.sessionId == sessionId)
        #expect(decoded.action == "complete")
    }

    @Test("WidgetSessionData with sessionId round-trip encode/decode")
    func sessionDataWithIdRoundTrip() throws {
        let sessionId = UUID()
        let data = WidgetSessionData(
            sessionId: sessionId,
            sessionType: "longRun",
            sessionIcon: "figure.run",
            displayName: "Long Run",
            description: "Steady state long run",
            plannedDistanceKm: 25,
            plannedElevationGainM: 800,
            plannedDuration: 7200,
            intensity: "moderate",
            date: Date(timeIntervalSinceReferenceDate: 700000000)
        )

        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(WidgetSessionData.self, from: encoded)

        #expect(decoded.sessionId == sessionId)
        #expect(decoded.sessionType == "longRun")
        #expect(decoded.plannedDistanceKm == 25)
    }

    @Test("WidgetFitnessData with empty trend")
    func fitnessDataEmptyTrend() throws {
        let data = WidgetFitnessData(form: -5, fitness: 40, fatigue: 45, trend: [])
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(WidgetFitnessData.self, from: encoded)

        #expect(decoded.form == -5)
        #expect(decoded.trend.isEmpty)
    }
}
