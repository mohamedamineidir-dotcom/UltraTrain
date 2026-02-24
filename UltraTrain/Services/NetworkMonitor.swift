import Foundation
import Network
import os

protocol NetworkMonitorProtocol: Sendable {
    var isConnected: Bool { get }
    func start()
    func stop()
}

@Observable
final class NetworkMonitor: NetworkMonitorProtocol, @unchecked Sendable {
    private(set) var isConnected: Bool = true
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private let onConnectivityRestored: (@Sendable () async -> Void)?
    private var wasDisconnected = false

    init(onConnectivityRestored: (@Sendable () async -> Void)? = nil) {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "com.ultratrain.networkmonitor")
        self.onConnectivityRestored = onConnectivityRestored
    }

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied

            Task { @MainActor in
                let previouslyDisconnected = self.wasDisconnected
                self.isConnected = connected

                if !connected {
                    self.wasDisconnected = true
                    Logger.network.info("NetworkMonitor: connectivity lost")
                } else if previouslyDisconnected {
                    self.wasDisconnected = false
                    Logger.network.info("NetworkMonitor: connectivity restored")
                    if let callback = self.onConnectivityRestored {
                        Task { await callback() }
                    }
                }
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}
