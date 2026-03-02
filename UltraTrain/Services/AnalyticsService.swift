import Foundation
import os

final class AnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var isEnabled = true
    private var eventBuffer: [BufferedEvent] = []
    private let maxBufferSize = 50
    private let flushInterval: TimeInterval = 300 // 5 minutes
    private let apiClient: APIClient?
    private var flushTask: Task<Void, Never>?

    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient
        startPeriodicFlush()
    }

    func track(_ event: AnalyticsEvent) {
        track(event, properties: [:])
    }

    func track(_ event: AnalyticsEvent, properties: [String: String]) {
        lock.lock()
        let enabled = isEnabled
        lock.unlock()

        guard enabled else { return }
        Logger.analyticsLog.info("Event: \(event.rawValue) \(properties.isEmpty ? "" : properties.description)")

        let buffered = BufferedEvent(
            name: event.rawValue,
            properties: properties,
            timestamp: Date()
        )

        lock.lock()
        eventBuffer.append(buffered)
        let shouldFlush = eventBuffer.count >= maxBufferSize
        lock.unlock()

        if shouldFlush {
            flush()
        }
    }

    func setTrackingEnabled(_ enabled: Bool) {
        lock.lock()
        isEnabled = enabled
        if !enabled {
            eventBuffer.removeAll()
        }
        lock.unlock()
        Logger.analyticsLog.info("Analytics tracking \(enabled ? "enabled" : "disabled")")
    }

    func flush() {
        lock.lock()
        let events = eventBuffer
        eventBuffer.removeAll()
        lock.unlock()

        guard !events.isEmpty, let apiClient else { return }

        Task {
            do {
                let payload = AnalyticsPayload(
                    events: events,
                    appVersion: AppConfiguration.appVersion,
                    buildNumber: AppConfiguration.buildNumber,
                    platform: "iOS",
                    locale: Locale.current.identifier
                )
                try await apiClient.sendVoid(AnalyticsEndpoints.TrackBatch(payload: payload))
                Logger.analyticsLog.info("Flushed \(events.count) analytics events")
            } catch {
                self.rebufferEvents(events)
                Logger.analyticsLog.warning("Analytics flush failed: \(error)")
            }
        }
    }

    // MARK: - Private

    private nonisolated func rebufferEvents(_ events: [BufferedEvent]) {
        lock.lock()
        let reinsertCount = min(events.count, maxBufferSize - eventBuffer.count)
        if reinsertCount > 0 {
            eventBuffer.insert(contentsOf: events.prefix(reinsertCount), at: 0)
        }
        lock.unlock()
    }

    private func startPeriodicFlush() {
        flushTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.flushInterval ?? 300))
                self?.flush()
            }
        }
    }

    deinit {
        flushTask?.cancel()
    }
}

// MARK: - Buffered Event

struct BufferedEvent: Codable, Sendable {
    let name: String
    let properties: [String: String]
    let timestamp: Date
}

// MARK: - Analytics Payload

struct AnalyticsPayload: Codable, Sendable {
    let events: [BufferedEvent]
    let appVersion: String
    let buildNumber: String
    let platform: String
    let locale: String
}

