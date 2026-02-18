import Foundation
import Testing
@testable import UltraTrain

struct WatchMessageCoderTests {

    // MARK: - WatchRunData Encode/Decode

    @Test func encodeDecodeRunData_roundTrips() {
        let data = WatchRunData(
            runState: "running",
            elapsedTime: 3661,
            distanceKm: 12.45,
            currentPace: "5:23",
            currentHeartRate: 155,
            elevationGainM: 450,
            formattedTime: "1:01:01",
            formattedDistance: "12.45",
            formattedElevation: "+450 m",
            isAutoPaused: false,
            activeReminderMessage: nil,
            activeReminderType: nil
        )

        let encoded = WatchMessageCoder.encode(data)
        let decoded = WatchMessageCoder.decodeRunData(encoded)

        #expect(decoded != nil)
        #expect(decoded?.runState == "running")
        #expect(decoded?.elapsedTime == 3661)
        #expect(decoded?.distanceKm == 12.45)
        #expect(decoded?.currentPace == "5:23")
        #expect(decoded?.currentHeartRate == 155)
        #expect(decoded?.elevationGainM == 450)
        #expect(decoded?.formattedTime == "1:01:01")
        #expect(decoded?.formattedDistance == "12.45")
        #expect(decoded?.formattedElevation == "+450 m")
        #expect(decoded?.isAutoPaused == false)
        #expect(decoded?.activeReminderMessage == nil)
        #expect(decoded?.activeReminderType == nil)
    }

    @Test func encodeDecodeRunData_withNutritionReminder() {
        let data = WatchRunData(
            runState: "running",
            elapsedTime: 1800,
            distanceKm: 5.0,
            currentPace: "6:00",
            currentHeartRate: 140,
            elevationGainM: 200,
            formattedTime: "0:30:00",
            formattedDistance: "5.00",
            formattedElevation: "+200 m",
            isAutoPaused: false,
            activeReminderMessage: "Time to drink!",
            activeReminderType: "hydration"
        )

        let decoded = WatchMessageCoder.decodeRunData(WatchMessageCoder.encode(data))

        #expect(decoded?.activeReminderMessage == "Time to drink!")
        #expect(decoded?.activeReminderType == "hydration")
    }

    @Test func encodeDecodeRunData_autoPausedState() {
        let data = WatchRunData(
            runState: "autoPaused",
            elapsedTime: 900,
            distanceKm: 3.0,
            currentPace: "5:00",
            currentHeartRate: nil,
            elevationGainM: 100,
            formattedTime: "0:15:00",
            formattedDistance: "3.00",
            formattedElevation: "+100 m",
            isAutoPaused: true,
            activeReminderMessage: nil,
            activeReminderType: nil
        )

        let decoded = WatchMessageCoder.decodeRunData(WatchMessageCoder.encode(data))

        #expect(decoded?.runState == "autoPaused")
        #expect(decoded?.isAutoPaused == true)
        #expect(decoded?.currentHeartRate == nil)
    }

    @Test func decodeRunData_withCorruptedData_returnsNil() {
        let corrupted: [String: Any] = ["runData": Data([0xFF, 0xFE])]
        #expect(WatchMessageCoder.decodeRunData(corrupted) == nil)
    }

    @Test func decodeRunData_withMissingKey_returnsNil() {
        let empty: [String: Any] = ["wrong": "key"]
        #expect(WatchMessageCoder.decodeRunData(empty) == nil)
    }

    @Test func decodeRunData_withWrongType_returnsNil() {
        let wrongType: [String: Any] = ["runData": "not data"]
        #expect(WatchMessageCoder.decodeRunData(wrongType) == nil)
    }

    // MARK: - WatchCommand Encode/Decode

    @Test(arguments: [
        WatchCommand.pause,
        WatchCommand.resume,
        WatchCommand.stop,
        WatchCommand.dismissReminder
    ])
    func encodeDecodeCommand_roundTrips(command: WatchCommand) {
        let encoded = WatchMessageCoder.encodeCommand(command)
        let decoded = WatchMessageCoder.decodeCommand(encoded)

        #expect(decoded == command)
    }

    @Test func decodeCommand_withUnknownValue_returnsNil() {
        let unknown: [String: Any] = ["command": "invalid"]
        #expect(WatchMessageCoder.decodeCommand(unknown) == nil)
    }

    @Test func decodeCommand_withMissingKey_returnsNil() {
        let missing: [String: Any] = ["wrong": "pause"]
        #expect(WatchMessageCoder.decodeCommand(missing) == nil)
    }

    @Test func decodeCommand_withWrongType_returnsNil() {
        let wrongType: [String: Any] = ["command": 42]
        #expect(WatchMessageCoder.decodeCommand(wrongType) == nil)
    }

    // MARK: - Edge Cases

    @Test func encodeRunData_emptyContext_whenEncodingFails() {
        // Normal data should never fail, but verify non-empty result
        let data = WatchRunData(
            runState: "notStarted",
            elapsedTime: 0,
            distanceKm: 0,
            currentPace: "--:--",
            currentHeartRate: nil,
            elevationGainM: 0,
            formattedTime: "0:00:00",
            formattedDistance: "0.00",
            formattedElevation: "+0 m",
            isAutoPaused: false,
            activeReminderMessage: nil,
            activeReminderType: nil
        )

        let encoded = WatchMessageCoder.encode(data)
        #expect(!encoded.isEmpty)
    }

    @Test(arguments: ["running", "paused", "autoPaused", "notStarted", "finished"])
    func allRunStates_encodeCorrectly(state: String) {
        let data = WatchRunData(
            runState: state,
            elapsedTime: 0,
            distanceKm: 0,
            currentPace: "--:--",
            currentHeartRate: nil,
            elevationGainM: 0,
            formattedTime: "0:00:00",
            formattedDistance: "0.00",
            formattedElevation: "+0 m",
            isAutoPaused: state == "autoPaused",
            activeReminderMessage: nil,
            activeReminderType: nil
        )

        let decoded = WatchMessageCoder.decodeRunData(WatchMessageCoder.encode(data))
        #expect(decoded?.runState == state)
    }
}
