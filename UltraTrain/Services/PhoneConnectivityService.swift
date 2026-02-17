import Foundation
import WatchConnectivity
import os

@Observable
@MainActor
final class PhoneConnectivityService: NSObject, @unchecked Sendable {

    // MARK: - State

    var isWatchReachable = false
    var commandHandler: (@MainActor @Sendable (WatchCommand) -> Void)?

    // MARK: - Private

    private var session: WCSession?

    // MARK: - Init

    override init() {
        super.init()
        guard WCSession.isSupported() else {
            Logger.watch.info("WCSession not supported on this device")
            return
        }
        session = WCSession.default
    }

    // MARK: - Activation

    func activate() {
        guard let session else { return }
        session.delegate = self
        session.activate()
        Logger.watch.info("WCSession activation requested")
    }

    // MARK: - Send Run Update

    func sendRunUpdate(_ data: WatchRunData) {
        guard let session, session.activationState == .activated else { return }
        let context = WatchMessageCoder.encode(data)
        guard !context.isEmpty else { return }
        do {
            try session.updateApplicationContext(context)
        } catch {
            Logger.watch.error("Failed to update application context: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityService: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        if let error {
            Logger.watch.error("WCSession activation failed: \(error)")
            return
        }
        let reachable = session.isReachable
        Task { @MainActor in
            self.isWatchReachable = reachable
            Logger.watch.info("WCSession activated, reachable: \(reachable)")
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Logger.watch.info("WCSession became inactive")
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Logger.watch.info("WCSession deactivated")
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isWatchReachable = reachable
            Logger.watch.info("Watch reachability changed: \(reachable)")
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        guard let command = WatchMessageCoder.decodeCommand(message) else {
            Logger.watch.warning("Received unknown message from Watch")
            return
        }
        Logger.watch.info("Received command from Watch: \(command.rawValue)")
        Task { @MainActor in
            self.commandHandler?(command)
        }
    }
}
