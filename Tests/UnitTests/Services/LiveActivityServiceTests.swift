import Foundation
import Testing
@testable import UltraTrain

@MainActor
struct LiveActivityServiceTests {

    // MARK: - Mock Tracks Calls

    @Test func startActivity_incrementsCallCount() {
        let mock = MockLiveActivityService()
        let attributes = makeAttributes()
        let state = makeState()

        mock.startActivity(attributes: attributes, state: state)

        #expect(mock.startCallCount == 1)
        #expect(mock.lastAttributes?.startTime == attributes.startTime)
        #expect(mock.lastState?.runState == "running")
    }

    @Test func updateActivity_incrementsCallCount() {
        let mock = MockLiveActivityService()
        let state = makeState(runState: "paused", isPaused: true)

        mock.updateActivity(state: state)

        #expect(mock.updateCallCount == 1)
        #expect(mock.lastState?.runState == "paused")
        #expect(mock.lastState?.isPaused == true)
    }

    @Test func endActivity_incrementsCallCount() {
        let mock = MockLiveActivityService()
        let state = makeState(runState: "finished", isPaused: true)

        mock.startActivity(attributes: makeAttributes(), state: makeState())
        mock.endActivity(state: state)

        #expect(mock.endCallCount == 1)
        #expect(mock.lastState?.runState == "finished")
    }

    @Test func isActivityActive_reflectsStartEndBalance() {
        let mock = MockLiveActivityService()

        #expect(!mock.isActivityActive)

        mock.startActivity(attributes: makeAttributes(), state: makeState())
        #expect(mock.isActivityActive)

        mock.endActivity(state: makeState(runState: "finished", isPaused: true))
        #expect(!mock.isActivityActive)
    }

    // MARK: - Content State

    @Test func contentState_preservesAllFields() {
        let state = RunActivityAttributes.ContentState(
            elapsedTime: 3661,
            distanceKm: 12.45,
            currentHeartRate: 155,
            elevationGainM: 450,
            runState: "running",
            isAutoPaused: false,
            formattedDistance: "12.45",
            formattedElevation: "+450 m",
            formattedPace: "5:23",
            timerStartDate: Date.now.addingTimeInterval(-3661),
            isPaused: false
        )

        #expect(state.elapsedTime == 3661)
        #expect(state.distanceKm == 12.45)
        #expect(state.currentHeartRate == 155)
        #expect(state.elevationGainM == 450)
        #expect(state.runState == "running")
        #expect(state.isAutoPaused == false)
        #expect(state.formattedDistance == "12.45")
        #expect(state.formattedElevation == "+450 m")
        #expect(state.formattedPace == "5:23")
        #expect(state.isPaused == false)
    }

    @Test func contentState_withNilHeartRate() {
        let state = makeState(heartRate: nil)
        #expect(state.currentHeartRate == nil)
    }

    @Test func contentState_pausedState_hasCorrectTimerDate() {
        let state = makeState(runState: "paused", isPaused: true)

        #expect(state.isPaused == true)
        #expect(state.runState == "paused")
    }

    @Test func contentState_autoPausedState() {
        let state = RunActivityAttributes.ContentState(
            elapsedTime: 900,
            distanceKm: 3.0,
            currentHeartRate: nil,
            elevationGainM: 100,
            runState: "autoPaused",
            isAutoPaused: true,
            formattedDistance: "3.00",
            formattedElevation: "+100 m",
            formattedPace: "5:00",
            timerStartDate: Date.now,
            isPaused: true
        )

        #expect(state.runState == "autoPaused")
        #expect(state.isAutoPaused == true)
        #expect(state.isPaused == true)
    }

    // MARK: - Multiple Updates

    @Test func multipleUpdates_trackedCorrectly() {
        let mock = MockLiveActivityService()

        mock.startActivity(attributes: makeAttributes(), state: makeState())
        mock.updateActivity(state: makeState(distance: 1.0))
        mock.updateActivity(state: makeState(distance: 2.0))
        mock.updateActivity(state: makeState(distance: 3.0))
        mock.endActivity(state: makeState(runState: "finished", isPaused: true))

        #expect(mock.startCallCount == 1)
        #expect(mock.updateCallCount == 3)
        #expect(mock.endCallCount == 1)
        #expect(mock.lastState?.runState == "finished")
    }

    // MARK: - Attributes

    @Test func attributes_preservesFields() {
        let startTime = Date.now
        let attributes = RunActivityAttributes(
            startTime: startTime,
            linkedSessionName: "Long Run"
        )

        #expect(attributes.startTime == startTime)
        #expect(attributes.linkedSessionName == "Long Run")
    }

    @Test func attributes_nilSessionName() {
        let attributes = RunActivityAttributes(
            startTime: Date.now,
            linkedSessionName: nil
        )

        #expect(attributes.linkedSessionName == nil)
    }

    // MARK: - Helpers

    private func makeAttributes() -> RunActivityAttributes {
        RunActivityAttributes(startTime: Date.now, linkedSessionName: nil)
    }

    private func makeState(
        runState: String = "running",
        distance: Double = 0,
        heartRate: Int? = 140,
        isPaused: Bool = false
    ) -> RunActivityAttributes.ContentState {
        RunActivityAttributes.ContentState(
            elapsedTime: 0,
            distanceKm: distance,
            currentHeartRate: heartRate,
            elevationGainM: 0,
            runState: runState,
            isAutoPaused: false,
            formattedDistance: String(format: "%.2f", distance),
            formattedElevation: "+0 m",
            formattedPace: "--:--",
            timerStartDate: Date.now,
            isPaused: isPaused
        )
    }
}
