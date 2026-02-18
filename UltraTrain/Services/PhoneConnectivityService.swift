import Foundation
import WatchConnectivity
import os

@Observable
@MainActor
final class PhoneConnectivityService: NSObject, @unchecked Sendable {

    // MARK: - State

    var isWatchReachable = false
    var commandHandler: (@MainActor @Sendable (WatchCommand) -> Void)?
    var completedRunHandler: (@MainActor @Sendable (WatchCompletedRunData) -> Void)?

    // MARK: - Private

    private var session: WCSession?
    private var currentRunData: WatchRunData?
    private var currentSessionData: WatchSessionData?
    private var currentComplicationData: WatchComplicationData?

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
        currentRunData = data
        sendApplicationContext()
    }

    // MARK: - Send Session Data

    func sendSessionData(_ data: WatchSessionData?) {
        currentSessionData = data
        sendApplicationContext()
    }

    // MARK: - Send Complication Data

    func sendComplicationData(_ data: WatchComplicationData) {
        currentComplicationData = data
        sendApplicationContext()
    }

    // MARK: - Private

    private func sendApplicationContext() {
        guard let session, session.activationState == .activated else { return }
        let context = WatchMessageCoder.mergeApplicationContext(
            runData: currentRunData,
            sessionData: currentSessionData,
            complicationData: currentComplicationData
        )
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

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        guard let completedRun = WatchMessageCoder.decodeCompletedRun(userInfo) else {
            Logger.watch.warning("Received unknown userInfo from Watch")
            return
        }
        Logger.watch.info("Received completed run from Watch: \(completedRun.runId)")
        Task { @MainActor in
            self.completedRunHandler?(completedRun)
        }
    }
}
