import Foundation
import HealthKit
import os

// MARK: - Resting HR, Max HR, Body Weight, Workout Import

extension HealthKitService {

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
        try await fetchWorkouts(
            activityTypes: [.running, .trailRunning],
            from: startDate,
            to: endDate
        )
    }

    func fetchWorkouts(
        activityTypes: [ActivityType],
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

        let hkTypes = HealthKitQueryHelper.hkActivityTypes(for: activityTypes)
        let activityPredicates = hkTypes.map { HKQuery.predicateForWorkouts(with: $0) }
        let activityPredicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: activityPredicates
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

    func mapWorkout(_ workout: HKWorkout) async -> HealthKitWorkout {
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
        let activityType = HealthKitQueryHelper.mapActivityType(workout.workoutActivityType)

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
            source: source,
            activityType: activityType
        )
    }

    nonisolated func makeBasicWorkout(_ workout: HKWorkout) -> HealthKitWorkout {
        let distanceKm: Double
        if let distance = workout.totalDistance {
            distanceKm = distance.doubleValue(for: .meterUnit(with: .kilo))
        } else {
            distanceKm = 0
        }

        let activityType = HealthKitQueryHelper.mapActivityType(workout.workoutActivityType)

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
            source: workout.sourceRevision.source.name,
            activityType: activityType
        )
    }
}
