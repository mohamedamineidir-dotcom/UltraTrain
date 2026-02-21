import Foundation
import Testing
@testable import UltraTrain

@Suite("Personal Record Calculator Tests")
struct PersonalRecordCalculatorTests {

    // MARK: - Helpers

    private func makeRun(
        distanceKm: Double,
        elevationGainM: Double = 0,
        duration: TimeInterval,
        date: Date = .now,
        averagePaceSecondsPerKm: Double = 0
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: date,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 0,
            duration: duration,
            averageHeartRate: nil,
            maxHeartRate: nil,
            averagePaceSecondsPerKm: averagePaceSecondsPerKm > 0 ? averagePaceSecondsPerKm : (distanceKm > 0 ? duration / distanceKm : 0),
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    // MARK: - Tests

    @Test("Empty runs returns empty records")
    func emptyRunsReturnsEmpty() {
        let records = PersonalRecordCalculator.computeAll(from: [])
        #expect(records.isEmpty)
    }

    @Test("Computes longest distance record")
    func computesLongestDistance() {
        let runs = [
            makeRun(distanceKm: 25, duration: 9000),
            makeRun(distanceKm: 10, duration: 3600)
        ]

        let records = PersonalRecordCalculator.computeAll(from: runs)
        let longestDistance = records.first { $0.type == .longestDistance }

        #expect(longestDistance != nil)
        #expect(longestDistance?.value == 25)
    }

    @Test("Computes most elevation record")
    func computesMostElevation() {
        let runs = [
            makeRun(distanceKm: 15, elevationGainM: 800, duration: 5400),
            makeRun(distanceKm: 10, elevationGainM: 200, duration: 3600)
        ]

        let records = PersonalRecordCalculator.computeAll(from: runs)
        let mostElevation = records.first { $0.type == .mostElevation }

        #expect(mostElevation != nil)
        #expect(mostElevation?.value == 800)
    }

    @Test("Computes fastest pace record")
    func computesFastestPace() {
        let runs = [
            makeRun(distanceKm: 10, duration: 3000, averagePaceSecondsPerKm: 300),
            makeRun(distanceKm: 10, duration: 3600, averagePaceSecondsPerKm: 360)
        ]

        let records = PersonalRecordCalculator.computeAll(from: runs)
        let fastestPace = records.first { $0.type == .fastestPace }

        #expect(fastestPace != nil)
        #expect(fastestPace?.value == 300)
    }

    @Test("Computes longest duration record")
    func computesLongestDuration() {
        let runs = [
            makeRun(distanceKm: 30, duration: 7200),
            makeRun(distanceKm: 10, duration: 3600)
        ]

        let records = PersonalRecordCalculator.computeAll(from: runs)
        let longestDuration = records.first { $0.type == .longestDuration }

        #expect(longestDuration != nil)
        #expect(longestDuration?.value == 7200)
    }

    @Test("Computes distance bracket records for 5K and 10K")
    func computesDistanceBracketRecords() {
        let runs = [
            makeRun(distanceKm: 5.2, duration: 1500),
            makeRun(distanceKm: 10.5, duration: 3000)
        ]

        let records = PersonalRecordCalculator.computeAll(from: runs)
        let fastest5K = records.first { $0.type == .fastest5K }
        let fastest10K = records.first { $0.type == .fastest10K }

        #expect(fastest5K != nil)
        #expect(fastest5K?.value == 1500)
        #expect(fastest10K != nil)
        #expect(fastest10K?.value == 3000)
    }

    @Test("Bracket tolerance rejects runs outside 10% range")
    func bracketToleranceRejectsOutOfRange() {
        // 6.0 km is 20% over the 5.0 km target, outside the +/- 10% tolerance
        let runs = [
            makeRun(distanceKm: 6.0, duration: 1800)
        ]

        let records = PersonalRecordCalculator.computeAll(from: runs)
        let fastest5K = records.first { $0.type == .fastest5K }

        #expect(fastest5K == nil)
    }

    @Test("Multiple runs in bracket picks the fastest")
    func multipleRunsInBracketPicksFastest() {
        let runs = [
            makeRun(distanceKm: 10.2, duration: 2400),
            makeRun(distanceKm: 9.8, duration: 3000)
        ]

        let records = PersonalRecordCalculator.computeAll(from: runs)
        let fastest10K = records.first { $0.type == .fastest10K }

        #expect(fastest10K != nil)
        #expect(fastest10K?.value == 2400)
    }
}
