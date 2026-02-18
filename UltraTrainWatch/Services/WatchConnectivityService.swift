import Foundation
import WatchConnectivity
import os

@Observable
@MainActor
final class WatchConnectivityService: NSObject, @unchecked Sendable {

    // MARK: - State

    var runData: WatchRunData?
    var sessionData: WatchSessionData?
    var complicationData: WatchComplicationData?
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

    // MARK: - Send Completed Run

    func sendCompletedRun(_ data: WatchCompletedRunData) {
        let userInfo = WatchMessageCoder.encodeCompletedRun(data)
        guard !userInfo.isEmpty else { return }
        session.transferUserInfo(userInfo)
        Logger.watch.info("Queued completed run for transfer: \(data.runId)")
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
        let decodedRunData = WatchMessageCoder.decodeRunData(applicationContext)
        let decodedSessionData = WatchMessageCoder.decodeSessionData(applicationContext)
        let decodedComplicationData = WatchMessageCoder.decodeComplicationData(applicationContext)

        Task { @MainActor in
            if let decodedRunData {
                self.runData = decodedRunData
            }
            if let decodedSessionData {
                self.sessionData = decodedSessionData
            }
            if let decodedComplicationData {
                self.complicationData = decodedComplicationData
            }
            Logger.watch.info("Received application context — run: \(decodedRunData != nil), session: \(decodedSessionData != nil), complication: \(decodedComplicationData != nil)")
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isPhoneReachable = reachable
        }
    }
}
