import Foundation
import HealthKit
import os

// MARK: - HRV, Sleep, Private Helpers

extension HealthKitService {

    // MARK: - HRV

    func fetchHRVData(from startDate: Date, to endDate: Date) async throws -> [HRVReading] {
        guard let healthStore else {
            throw DomainError.healthKitUnavailable
        }

        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate, end: endDate, options: .strictEndDate
        )
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate, ascending: true
        )

        let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
            }
            healthStore.execute(query)
        }

        return samples.map { sample in
            let sdnn = sample.quantity.doubleValue(for: .secondUnit(with: .milli))
            return HRVReading(
                date: sample.startDate,
                sdnnMs: sdnn,
                source: sample.sourceRevision.source.name
            )
        }
    }

    // MARK: - Sleep

    func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> [SleepEntry] {
        guard let healthStore else {
            throw DomainError.healthKitUnavailable
        }

        let samples = try await HealthKitQueryHelper.fetchSleepSamples(
            store: healthStore, from: startDate, to: endDate
        )
        return mapSleepSamples(samples)
    }

    nonisolated func mapSleepSamples(_ samples: [HKCategorySample]) -> [SleepEntry] {
        let nightGroups = groupIntoNights(samples)

        return nightGroups.compactMap { nightSamples -> SleepEntry? in
            var deep: TimeInterval = 0
            var rem: TimeInterval = 0
            var core: TimeInterval = 0
            var unspecified: TimeInterval = 0
            var inBedTime: TimeInterval = 0
            var earliestBedtime: Date = Date.distantFuture
            var latestWake: Date = Date.distantPast

            for sample in nightSamples {
                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)

                switch value {
                case .asleepDeep: deep += duration
                case .asleepREM: rem += duration
                case .asleepCore: core += duration
                case .asleepUnspecified: unspecified += duration
                case .inBed: inBedTime += duration
                case .awake: break
                default: break
                }

                if sample.startDate < earliestBedtime { earliestBedtime = sample.startDate }
                if sample.endDate > latestWake { latestWake = sample.endDate }
            }

            let totalSleep = deep + rem + core + unspecified
            guard totalSleep > 0 else { return nil }

            let effectiveInBed = inBedTime > 0
                ? inBedTime
                : latestWake.timeIntervalSince(earliestBedtime)
            let efficiency = effectiveInBed > 0
                ? min(totalSleep / effectiveInBed, 1.0)
                : 0

            let nightDate = Calendar.current.startOfDay(for: earliestBedtime)

            return SleepEntry(
                id: UUID(),
                date: nightDate,
                totalSleepDuration: totalSleep,
                deepSleepDuration: deep,
                remSleepDuration: rem,
                coreSleepDuration: core,
                sleepEfficiency: efficiency,
                bedtime: earliestBedtime,
                wakeTime: latestWake,
                timeInBed: effectiveInBed
            )
        }
    }

    nonisolated func groupIntoNights(_ samples: [HKCategorySample]) -> [[HKCategorySample]] {
        guard !samples.isEmpty else { return [] }

        var groups: [[HKCategorySample]] = [[samples[0]]]

        for sample in samples.dropFirst() {
            let lastGroup = groups[groups.count - 1]
            let lastEnd = lastGroup.map(\.endDate).max() ?? Date.distantPast
            let gap = sample.startDate.timeIntervalSince(lastEnd)

            if gap <= 1800 {
                groups[groups.count - 1].append(sample)
            } else {
                groups.append([sample])
            }
        }

        return groups
    }
}
