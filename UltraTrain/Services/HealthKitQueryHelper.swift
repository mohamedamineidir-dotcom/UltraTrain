import Foundation
import HealthKit
import os

enum HealthKitQueryHelper {

    // MARK: - Heart Rate Stats

    static func fetchHeartRateStats(
        store: HKHealthStore,
        startDate: Date,
        endDate: Date
    ) async throws -> (average: Int?, max: Int?) {
        let heartRateType = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate, end: endDate, options: .strictEndDate
        )
        let bpmUnit = HKUnit.count().unitDivided(by: .minute())

        let average: Int? = try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let bpm = statistics?.averageQuantity()?.doubleValue(for: bpmUnit)
                continuation.resume(returning: bpm.map { Int($0) })
            }
            store.execute(query)
        }

        let max: Int? = try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteMax
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let bpm = statistics?.maximumQuantity()?.doubleValue(for: bpmUnit)
                continuation.resume(returning: bpm.map { Int($0) })
            }
            store.execute(query)
        }

        return (average: average, max: max)
    }

    // MARK: - Elevation

    static func fetchElevationGain(
        store: HKHealthStore,
        workout: HKWorkout
    ) -> Double {
        if let elevationQuantity = workout.metadata?[HKMetadataKeyElevationAscended] as? HKQuantity {
            return elevationQuantity.doubleValue(for: .meter())
        }
        return 0
    }

    // MARK: - Body Weight

    static func fetchBodyWeight(
        store: HKHealthStore
    ) async throws -> Double? {
        let bodyMassType = HKQuantityType(.bodyMass)
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate, ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: kg)
            }
            store.execute(query)
        }
    }

    // MARK: - Save Workout

    static func saveWorkout(
        store: HKHealthStore,
        run: CompletedRun
    ) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor

        let builder = HKWorkoutBuilder(
            healthStore: store,
            configuration: configuration,
            device: .local()
        )

        try await builder.beginCollection(at: run.date)

        let endDate = run.date.addingTimeInterval(run.duration)

        if run.distanceKm > 0 {
            let distanceType = HKQuantityType(.distanceWalkingRunning)
            let distanceQuantity = HKQuantity(
                unit: .meterUnit(with: .kilo),
                doubleValue: run.distanceKm
            )
            let distanceSample = HKQuantitySample(
                type: distanceType,
                quantity: distanceQuantity,
                start: run.date,
                end: endDate
            )
            try await builder.addSamples([distanceSample])
        }

        try await builder.endCollection(at: endDate)
        try await builder.finishWorkout()

        Logger.healthKit.info("Workout saved to Apple Health: \(run.distanceKm, format: .fixed(precision: 1)) km")
    }

    // MARK: - Write Types

    static func writeTypes() -> Set<HKSampleType> {
        var types: Set<HKSampleType> = []
        types.insert(HKWorkoutType.workoutType())
        types.insert(HKQuantityType(.distanceWalkingRunning))
        return types
    }

    // MARK: - Read Types

    static func readTypes() -> Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        types.insert(HKQuantityType(.heartRate))
        types.insert(HKQuantityType(.restingHeartRate))
        types.insert(HKQuantityType(.distanceWalkingRunning))
        types.insert(HKQuantityType(.activeEnergyBurned))
        types.insert(HKQuantityType(.bodyMass))
        types.insert(HKWorkoutType.workoutType())
        return types
    }
}
