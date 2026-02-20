import Foundation
import HealthKit
import os

@Observable
@MainActor
final class HealthKitService: @preconcurrency HealthKitServiceProtocol, @unchecked Sendable {

    // MARK: - State

    var authorizationStatus: HealthKitAuthStatus = .unavailable

    // MARK: - Private

    private let healthStore: HKHealthStore?
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var heartRateContinuation: AsyncStream<HealthKitHeartRateReading>.Continuation?

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

    // MARK: - Resting & Max HR

    func fetchRestingHeartRate() async throws -> Int? {
        guard let healthStore else {
            throw DomainError.healthKitUnavailable
        }

        let heartRateType = HKQuantityType(.restingHeartRate)
        let now = Date.now
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(
            withStart: sevenDaysAgo, end: now, options: .strictEndDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .mostRecent
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let bpm = statistics?.mostRecentQuantity()?.doubleValue(
                    for: HKUnit.count().unitDivided(by: .minute())
                )
                continuation.resume(returning: bpm.map { Int($0) })
            }
            healthStore.execute(query)
        }
    }

    func fetchMaxHeartRate() async throws -> Int? {
        guard let healthStore else {
            throw DomainError.healthKitUnavailable
        }

        let heartRateType = HKQuantityType(.heartRate)
        let now = Date.now
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let predicate = HKQuery.predicateForSamples(
            withStart: thirtyDaysAgo, end: now, options: .strictEndDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteMax
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let bpm = statistics?.maximumQuantity()?.doubleValue(
                    for: HKUnit.count().unitDivided(by: .minute())
                )
                continuation.resume(returning: bpm.map { Int($0) })
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Body Weight

    func fetchBodyWeight() async throws -> Double? {
        guard let healthStore else {
            throw DomainError.healthKitUnavailable
        }
        return try await HealthKitQueryHelper.fetchBodyWeight(store: healthStore)
    }

    // MARK: - Save Workout

    func saveWorkout(run: CompletedRun) async throws {
        guard let healthStore else {
            throw DomainError.healthKitUnavailable
        }

        let workoutType = HKWorkoutType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        guard status == .sharingAuthorized else {
            throw DomainError.healthKitWriteDenied
        }

        try await HealthKitQueryHelper.saveWorkout(store: healthStore, run: run)
    }

    // MARK: - Workout Import

    func fetchRunningWorkouts(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HealthKitWorkout] {
        guard let healthStore else {
            throw DomainError.healthKitUnavailable
        }

        let workoutType = HKWorkoutType.workoutType()
        let datePredicate = HKQuery.predicateForSamples(
            withStart: startDate, end: endDate, options: .strictEndDate
        )
        let activityPredicate = HKQuery.predicateForWorkouts(
            with: .running
        )
        let predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [datePredicate, activityPredicate]
        )
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate, ascending: false
        )

        let hkWorkouts: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKWorkout] ?? [])
            }
            healthStore.execute(query)
        }

        var results: [HealthKitWorkout] = []
        for workout in hkWorkouts {
            let mapped = await mapWorkout(workout)
            results.append(mapped)
        }
        return results
    }

    // MARK: - Private

    private func checkAuthorizationStatus() {
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

    private func startHeartRateQuery() {
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

    private nonisolated func processHeartRateSamples(_ samples: [HKSample]?) {
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

    private func mapWorkout(_ workout: HKWorkout) async -> HealthKitWorkout {
        guard let healthStore else {
            return makeBasicWorkout(workout)
        }

        let distanceKm: Double
        if let distance = workout.totalDistance {
            distanceKm = distance.doubleValue(for: .meterUnit(with: .kilo))
        } else {
            distanceKm = 0
        }

        let elevationGainM = HealthKitQueryHelper.fetchElevationGain(
            store: healthStore, workout: workout
        )

        var averageHR: Int?
        var maxHR: Int?
        do {
            let hrStats = try await HealthKitQueryHelper.fetchHeartRateStats(
                store: healthStore,
                startDate: workout.startDate,
                endDate: workout.endDate
            )
            averageHR = hrStats.average
            maxHR = hrStats.max
        } catch {
            Logger.healthKit.error("Failed to fetch HR stats for workout: \(error)")
        }

        let source = workout.sourceRevision.source.name

        return HealthKitWorkout(
            id: UUID(),
            originalUUID: workout.uuid.uuidString,
            startDate: workout.startDate,
            endDate: workout.endDate,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            duration: workout.duration,
            averageHeartRate: averageHR,
            maxHeartRate: maxHR,
            source: source
        )
    }

    private nonisolated func makeBasicWorkout(_ workout: HKWorkout) -> HealthKitWorkout {
        let distanceKm: Double
        if let distance = workout.totalDistance {
            distanceKm = distance.doubleValue(for: .meterUnit(with: .kilo))
        } else {
            distanceKm = 0
        }

        return HealthKitWorkout(
            id: UUID(),
            originalUUID: workout.uuid.uuidString,
            startDate: workout.startDate,
            endDate: workout.endDate,
            distanceKm: distanceKm,
            elevationGainM: 0,
            duration: workout.duration,
            averageHeartRate: nil,
            maxHeartRate: nil,
            source: workout.sourceRevision.source.name
        )
    }
}
