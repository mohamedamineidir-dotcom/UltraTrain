import HealthKit
import os

enum WatchHKAuthStatus: Sendable {
    case notDetermined
    case denied
    case authorized
}

@MainActor
protocol WatchHealthKitServiceProtocol: Sendable {
    var authStatus: WatchHKAuthStatus { get }
    func requestAuthorization() async throws
    func startWorkoutSession() async throws
    func stopWorkoutSession() async throws
    func pauseWorkoutSession()
    func resumeWorkoutSession()
    func heartRateStream() -> AsyncStream<Int>
}

@Observable
@MainActor
final class WatchHealthKitService: NSObject, WatchHealthKitServiceProtocol, @unchecked Sendable {

    // MARK: - State

    var authStatus: WatchHKAuthStatus = .notDetermined

    // MARK: - Private

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var heartRateContinuation: AsyncStream<Int>.Continuation?

    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    private let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!

    // MARK: - Authorization

    func requestAuthorization() async throws {
        let readTypes: Set<HKObjectType> = [heartRateType, activeEnergyType, distanceType]
        let shareTypes: Set<HKSampleType> = [HKWorkoutType.workoutType()]

        try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
        updateAuthStatus()
        Logger.watch.info("Watch HealthKit authorization completed")
    }

    // MARK: - Workout Session

    func startWorkoutSession() async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor

        let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )

        session.delegate = self
        builder.delegate = self

        self.workoutSession = session
        self.workoutBuilder = builder

        session.startActivity(with: .now)
        try await builder.beginCollection(at: .now)
        Logger.watch.info("Watch workout session started")
    }

    func stopWorkoutSession() async throws {
        guard let session = workoutSession, let builder = workoutBuilder else { return }
        session.end()
        try await builder.endCollection(at: .now)
        try await builder.finishWorkout()

        heartRateContinuation?.finish()
        heartRateContinuation = nil
        workoutSession = nil
        workoutBuilder = nil
        Logger.watch.info("Watch workout session ended and saved")
    }

    func pauseWorkoutSession() {
        workoutSession?.pause()
        Logger.watch.info("Watch workout session paused")
    }

    func resumeWorkoutSession() {
        workoutSession?.resume()
        Logger.watch.info("Watch workout session resumed")
    }

    // MARK: - Heart Rate Stream

    func heartRateStream() -> AsyncStream<Int> {
        AsyncStream { continuation in
            self.heartRateContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { @MainActor in
                    self.heartRateContinuation = nil
                }
            }
        }
    }

    // MARK: - Private

    private func updateAuthStatus() {
        let status = healthStore.authorizationStatus(for: heartRateType)
        switch status {
        case .notDetermined:
            authStatus = .notDetermined
        case .sharingDenied:
            authStatus = .denied
        case .sharingAuthorized:
            authStatus = .authorized
        @unknown default:
            authStatus = .denied
        }
    }

    private func processHeartRateSamples(_ samples: [HKSample]) {
        guard let quantitySamples = samples as? [HKQuantitySample] else { return }
        let unit = HKUnit.count().unitDivided(by: .minute())
        for sample in quantitySamples {
            let hr = Int(sample.quantity.doubleValue(for: unit))
            heartRateContinuation?.yield(hr)
        }
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchHealthKitService: HKWorkoutSessionDelegate {

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Logger.watch.info("Workout session state: \(fromState.rawValue) → \(toState.rawValue)")
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: any Error
    ) {
        Logger.watch.error("Workout session error: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WatchHealthKitService: HKLiveWorkoutBuilderDelegate {

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        guard collectedTypes.contains(heartRateType) else { return }
        let samples = workoutBuilder.statistics(for: heartRateType)
        guard let mostRecent = samples?.mostRecentQuantity() else { return }
        let unit = HKUnit.count().unitDivided(by: .minute())
        let hr = Int(mostRecent.doubleValue(for: unit))
        Task { @MainActor in
            self.heartRateContinuation?.yield(hr)
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // No-op — events handled via session delegate
    }
}
