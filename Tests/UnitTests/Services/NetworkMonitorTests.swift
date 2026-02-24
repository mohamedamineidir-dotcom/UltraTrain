import Testing
import Foundation
@testable import UltraTrain

struct NetworkMonitorTests {

    @Test func initiallyConnected() {
        let monitor = NetworkMonitor()
        #expect(monitor.isConnected == true)
    }

    @Test func conformsToProtocol() {
        let monitor = NetworkMonitor()
        let _: any NetworkMonitorProtocol = monitor
        #expect(monitor.isConnected)
    }

    @Test func canStartAndStop() {
        let monitor = NetworkMonitor()
        monitor.start()
        monitor.stop()
        // No crash = success
    }

    @Test func initWithCallback() {
        let monitor = NetworkMonitor(onConnectivityRestored: {
            // Callback only fires on actual connectivity restoration
        })
        #expect(monitor.isConnected)
    }
}
