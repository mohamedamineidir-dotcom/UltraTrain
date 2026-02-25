import Foundation
import HealthKit
import os

@Observable
@MainActor
final class HealthKitService: @preconcurrency HealthKitServiceProtocol, @unchecked Sendable {

    // MARK: - State

    var authorizationStatus: HealthKitAuthStatus = .unavailable

    // MARK: - Internal

    let healthStore: HKHealthStore?
    var heartRateQuery: HKAnchoredObjectQuery?
    var heartRateContinuation: AsyncStream<HealthKitHeartRateReading>.Continuation?

    // MARK: - Init

    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
            authorizationStatus = .notDetermined
        } else {
            healthStore = nil
            authorizationStatus = .unavailable
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard let healthStore else {
            throw DomainError.healthKitUnavailable
        }

        let readTypes = HealthKitQueryHelper.readTypes()
        let writeTypes = HealthKitQueryHelper.writeTypes()

        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        checkAuthorizationStatus()
        Logger.healthKit.info("HealthKit authorization requested")
    }

    // MARK: - Heart Rate Streaming

    func startHeartRateStream() -> AsyncStream<HealthKitHeartRateReading> {
        AsyncStream { [weak self] continuation in
            guard let self else { return }

            self.heartRateContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.stopHeartRateStream()
                }
            }

            self.startHeartRateQuery()
            Logger.healthKit.info("Heart rate stream started")
        }
    }

    func stopHeartRateStream() {
        if let query = heartRateQuery, let store = healthStore {
            store.stop(query)
        }
        heartRateQuery = nil
        heartRateContinuation?.finish()
        heartRateContinuation = nil
        Logger.healthKit.info("Heart rate stream stopped")
    }

    // MARK: - Private Helpers

    func checkAuthorizationStatus() {
        guard let healthStore else {
            authorizationStatus = .unavailable
            return
        }

        let heartRateType = HKQuantityType(.heartRate)
        let status = healthStore.authorizationStatus(for: heartRateType)

        authorizationStatus = switch status {
        case .notDetermined: .notDetermined
        case .sharingDenied: .authorized
        case .sharingAuthorized: .authorized
        @unknown default: .notDetermined
        }
    }

    func startHeartRateQuery() {
        guard let healthStore else { return }

        let heartRateType = HKQuantityType(.heartRate)
        let now = Date.now

        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: HKQuery.predicateForSamples(
                withStart: now, end: nil, options: .strictStartDate
            ),
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, error in
            if let error {
                Task { @MainActor in
                    Logger.healthKit.error("HR query initial error: \(error)")
                }
                return
            }
            self?.processHeartRateSamples(samples)
        }

        query.updateHandler = { [weak self] _, samples, _, _, error in
            if let error {
                Task { @MainActor in
                    Logger.healthKit.error("HR query update error: \(error)")
                }
                return
            }
            self?.processHeartRateSamples(samples)
        }

        heartRateQuery = query
        healthStore.execute(query)
    }

    nonisolated func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let quantitySamples = samples as? [HKQuantitySample] else { return }

        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
        for sample in quantitySamples {
            let bpm = Int(sample.quantity.doubleValue(for: bpmUnit))
            let reading = HealthKitHeartRateReading(
                beatsPerMinute: bpm,
                timestamp: sample.startDate
            )
            Task { @MainActor [weak self] in
                self?.heartRateContinuation?.yield(reading)
            }
        }
    }
}
