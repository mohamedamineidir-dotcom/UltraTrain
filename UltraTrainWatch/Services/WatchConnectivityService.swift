import Foundation
import WatchConnectivity
import os

@Observable
@MainActor
final class WatchConnectivityService: NSObject, @unchecked Sendable {

    // MARK: - State

    var runData: WatchRunData?
    var isPhoneReachable = false

    // MARK: - Private

    private let session = WCSession.default

    // MARK: - Activation

    func activate() {
        session.delegate = self
        session.activate()
        Logger.watch.info("Watch WCSession activation requested")
    }

    // MARK: - Send Command

    func sendCommand(_ command: WatchCommand) {
        guard session.isReachable else {
            Logger.watch.warning("Cannot send command — phone not reachable")
            return
        }
        let message = WatchMessageCoder.encodeCommand(command)
        session.sendMessage(message, replyHandler: nil) { error in
            Logger.watch.error("Failed to send command \(command.rawValue): \(error)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        if let error {
            Logger.watch.error("Watch WCSession activation failed: \(error)")
            return
        }
        let reachable = session.isReachable
        Task { @MainActor in
            self.isPhoneReachable = reachable
            Logger.watch.info("Watch WCSession activated")
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        guard let data = WatchMessageCoder.decode(applicationContext) else {
            Logger.watch.warning("Failed to decode application context")
            return
        }
        Task { @MainActor in
            self.runData = data
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isPhoneReachable = reachable
        }
    }
}
