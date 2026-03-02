import Foundation
import Testing
@testable import UltraTrain

@Suite("PhoneConnectivityService Tests")
struct PhoneConnectivityServiceTests {

    // NOTE: PhoneConnectivityService depends on WCSession which is only available on paired devices.
    // We test observable state properties, initial configuration, and handler management.

    // MARK: - Initial State

    @MainActor
    @Test("PhoneConnectivityService starts with isWatchReachable false")
    func initialIsWatchReachableFalse() {
        let service = PhoneConnectivityService()
        #expect(!service.isWatchReachable)
    }

    @MainActor
    @Test("PhoneConnectivityService starts with nil command handler")
    func initialCommandHandlerNil() {
        let service = PhoneConnectivityService()
        #expect(service.commandHandler == nil)
    }

    @MainActor
    @Test("PhoneConnectivityService starts with nil completedRunHandler")
    func initialCompletedRunHandlerNil() {
        let service = PhoneConnectivityService()
        #expect(service.completedRunHandler == nil)
    }

    // MARK: - Handler Assignment

    @MainActor
    @Test("commandHandler can be set and is retained")
    func commandHandlerCanBeSet() {
        let service = PhoneConnectivityService()
        var receivedCommand: WatchCommand?

        service.commandHandler = { command in
            receivedCommand = command
        }

        #expect(service.commandHandler != nil)
        _ = receivedCommand // suppress unused warning
    }

    @MainActor
    @Test("completedRunHandler can be set and is retained")
    func completedRunHandlerCanBeSet() {
        let service = PhoneConnectivityService()
        var receivedRun: WatchCompletedRunData?

        service.completedRunHandler = { data in
            receivedRun = data
        }

        #expect(service.completedRunHandler != nil)
        _ = receivedRun // suppress unused warning
    }

    // MARK: - Send Methods

    @MainActor
    @Test("sendRunUpdate does not crash when session is nil")
    func sendRunUpdateSafeWithoutSession() {
        let service = PhoneConnectivityService()
        let runData = WatchRunData(
            runState: "running",
            elapsedTime: 1800,
            distanceKm: 5.0,
            currentPace: "6:00",
            currentHeartRate: 145,
            elevationGainM: 200,
            formattedTime: "30:00",
            formattedDistance: "5.0 km",
            formattedElevation: "200 m",
            isAutoPaused: false,
            activeReminderMessage: nil,
            activeReminderType: nil
        )
        // Should not crash even without an active WCSession
        service.sendRunUpdate(runData)
    }

    @MainActor
    @Test("sendSessionData with nil does not crash")
    func sendSessionDataNilIsSafe() {
        let service = PhoneConnectivityService()
        service.sendSessionData(nil)
    }

    @MainActor
    @Test("activate does not crash when WCSession is not supported")
    func activateDoesNotCrash() {
        let service = PhoneConnectivityService()
        // On simulator, WCSession.isSupported() returns false
        // so the session property is nil and activate() just returns
        service.activate()
    }
}
