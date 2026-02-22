#if canImport(ActivityKit)
import ActivityKit
import Foundation
import Testing
@testable import UltraTrain

@Suite("Live Activity Race Mode Tests")
struct LiveActivityRaceModeTests {

    private func makeState(
        nextCheckpoint: String? = nil, distanceToCheckpoint: Double? = nil,
        projectedFinish: String? = nil, timeDelta: Double? = nil,
        nutritionReminder: String? = nil
    ) -> RunActivityAttributes.ContentState {
        RunActivityAttributes.ContentState(
            elapsedTime: 3600, distanceKm: 12.5, currentHeartRate: 155,
            elevationGainM: 450, runState: "running", isAutoPaused: false,
            formattedDistance: "12.5 km", formattedElevation: "450 m",
            formattedPace: "5:30 /km",
            timerStartDate: Date(timeIntervalSince1970: 1_700_000_000),
            isPaused: false, nextCheckpointName: nextCheckpoint,
            distanceToCheckpointKm: distanceToCheckpoint,
            projectedFinishTime: projectedFinish,
            timeDeltaSeconds: timeDelta,
            activeNutritionReminder: nutritionReminder
        )
    }

    @Test("ContentState with all race fields nil represents non-race mode")
    func nonRaceMode() {
        let state = makeState()
        #expect(state.nextCheckpointName == nil)
        #expect(state.distanceToCheckpointKm == nil)
        #expect(state.projectedFinishTime == nil)
        #expect(state.timeDeltaSeconds == nil)
        #expect(state.activeNutritionReminder == nil)
    }

    @Test("ContentState with race fields populated")
    func raceModePopulated() {
        let state = makeState(
            nextCheckpoint: "Col du Bonhomme", distanceToCheckpoint: 3.2,
            projectedFinish: "22:45:00", timeDelta: -180.0
        )
        #expect(state.nextCheckpointName == "Col du Bonhomme")
        #expect(state.distanceToCheckpointKm == 3.2)
        #expect(state.projectedFinishTime == "22:45:00")
        #expect(state.timeDeltaSeconds == -180.0)
    }

    @Test("ContentState with nutrition reminder set")
    func nutritionReminder() {
        let state = makeState(nutritionReminder: "Take a gel now - 200 kcal")
        #expect(state.activeNutritionReminder == "Take a gel now - 200 kcal")
    }

    @Test("ContentState Codable round-trip preserves race fields")
    func codableRoundTrip() throws {
        let original = makeState(
            nextCheckpoint: "Les Contamines", distanceToCheckpoint: 5.8,
            projectedFinish: "24:00:00", timeDelta: 120.0,
            nutritionReminder: "Hydrate - 500ml"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(
            RunActivityAttributes.ContentState.self, from: data
        )
        #expect(decoded.nextCheckpointName == "Les Contamines")
        #expect(decoded.distanceToCheckpointKm == 5.8)
        #expect(decoded.projectedFinishTime == "24:00:00")
        #expect(decoded.timeDeltaSeconds == 120.0)
        #expect(decoded.activeNutritionReminder == "Hydrate - 500ml")
        #expect(decoded.distanceKm == 12.5)
        #expect(decoded.currentHeartRate == 155)
    }

    @Test("Decoding without race fields produces nil (backward compat)")
    func backwardCompatibility() throws {
        // JSON without the new optional race/nutrition fields
        let json = """
        {"elapsedTime":3600,"distanceKm":10,"currentHeartRate":145,\
        "elevationGainM":300,"runState":"running","isAutoPaused":false,\
        "formattedDistance":"10.0 km","formattedElevation":"300 m",\
        "formattedPace":"6:00 /km","timerStartDate":0,"isPaused":false}
        """
        let decoded = try JSONDecoder().decode(
            RunActivityAttributes.ContentState.self, from: Data(json.utf8)
        )
        #expect(decoded.distanceKm == 10.0)
        #expect(decoded.nextCheckpointName == nil)
        #expect(decoded.distanceToCheckpointKm == nil)
        #expect(decoded.projectedFinishTime == nil)
        #expect(decoded.timeDeltaSeconds == nil)
        #expect(decoded.activeNutritionReminder == nil)
    }
}
#endif
