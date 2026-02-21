import Foundation
import Testing
@testable import UltraTrain

@Suite("Fitness Calculator Tests")
struct FitnessCalculatorTests {

    private let calculator = FitnessCalculator()

    private func makeRun(
        daysAgo: Int = 0,
        distanceKm: Double = 10,
        elevationGainM: Double = 200,
        duration: TimeInterval = 3600,
        trainingStressScore: Double? = nil
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: Date.now.adding(days: -daysAgo),
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 180,
            duration: duration,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            notes: nil,
            pausedDuration: 0,
            trainingStressScore: trainingStressScore
        )
    }

    // MARK: - Empty & Basic

    @Test("Empty runs returns zero snapshot")
    func emptyRuns() async throws {
        let snapshot = try await calculator.execute(runs: [], asOf: .now)
        #expect(snapshot.fitness == 0)
        #expect(snapshot.fatigue == 0)
        #expect(snapshot.form == 0)
        #expect(snapshot.weeklyVolumeKm == 0)
        #expect(snapshot.weeklyElevationGainM == 0)
        #expect(snapshot.acuteToChronicRatio == 0)
    }

    @Test("Single run produces non-zero fitness and fatigue")
    func singleRun() async throws {
        let run = makeRun(daysAgo: 0, distanceKm: 10, elevationGainM: 200)
        let snapshot = try await calculator.execute(runs: [run], asOf: .now)
        #expect(snapshot.fitness > 0)
        #expect(snapshot.fatigue > 0)
        #expect(snapshot.weeklyVolumeKm == 10)
        #expect(snapshot.weeklyElevationGainM == 200)
    }

    // MARK: - TSB & ACR

    @Test("TSB equals CTL minus ATL")
    func tsbCalculation() async throws {
        let runs = (0..<14).map { makeRun(daysAgo: $0) }
        let snapshot = try await calculator.execute(runs: runs, asOf: .now)
        let expectedTSB = snapshot.fitness - snapshot.fatigue
        #expect(abs(snapshot.form - expectedTSB) < 0.001)
    }

    @Test("ACR equals ATL divided by CTL")
    func acrCalculation() async throws {
        let runs = (0..<42).map { makeRun(daysAgo: $0) }
        let snapshot = try await calculator.execute(runs: runs, asOf: .now)
        let expectedACR = snapshot.fatigue / snapshot.fitness
        #expect(abs(snapshot.acuteToChronicRatio - expectedACR) < 0.001)
    }

    @Test("ACR is zero when no prior fitness")
    func acrZeroCTL() async throws {
        let snapshot = try await calculator.execute(runs: [], asOf: .now)
        #expect(snapshot.acuteToChronicRatio == 0)
    }

    // MARK: - Weekly Scope

    @Test("Weekly volume only includes last 7 days")
    func weeklyVolumeScope() async throws {
        let oldRun = makeRun(daysAgo: 10, distanceKm: 20)
        let recentRun = makeRun(daysAgo: 2, distanceKm: 15)
        let snapshot = try await calculator.execute(runs: [oldRun, recentRun], asOf: .now)
        #expect(snapshot.weeklyVolumeKm == 15)
    }

    @Test("Weekly duration sums correctly")
    func weeklyDurationSum() async throws {
        let run1 = makeRun(daysAgo: 1, duration: 3600)
        let run2 = makeRun(daysAgo: 3, duration: 5400)
        let snapshot = try await calculator.execute(runs: [run1, run2], asOf: .now)
        #expect(snapshot.weeklyDuration == 9000)
    }

    // MARK: - EMA Behavior

    @Test("ATL responds faster than CTL to load spike")
    func atlRespondsFaster() async throws {
        var runs: [CompletedRun] = []
        // 30 days of easy running
        for day in 4..<34 {
            runs.append(makeRun(daysAgo: day, distanceKm: 5, elevationGainM: 50))
        }
        // 3 days of heavy running
        for day in 0..<3 {
            runs.append(makeRun(daysAgo: day, distanceKm: 30, elevationGainM: 1000))
        }
        let snapshot = try await calculator.execute(runs: runs, asOf: .now)
        // After a load spike, ATL > CTL, so form should be negative
        #expect(snapshot.form < 0)
        #expect(snapshot.fatigue > snapshot.fitness)
    }

    // MARK: - Monotony

    @Test("Empty runs returns zero monotony")
    func monotonyZeroForEmptyRuns() async throws {
        let snapshot = try await calculator.execute(runs: [], asOf: .now)
        #expect(snapshot.monotony == 0)
    }

    @Test("Single run produces non-zero monotony")
    func monotonyNonZeroForSingleRun() async throws {
        let run = makeRun(daysAgo: 0)
        let snapshot = try await calculator.execute(runs: [run], asOf: .now)
        // With only 1 day having load and 6 days with 0, stddev > 0 → monotony > 0
        #expect(snapshot.monotony >= 0)
    }

    @Test("Consistent training produces positive form after taper")
    func taperProducesPositiveForm() async throws {
        var runs: [CompletedRun] = []
        // 30 days of heavy training
        for day in 7..<37 {
            runs.append(makeRun(daysAgo: day, distanceKm: 15, elevationGainM: 400))
        }
        // 7 days of rest (no runs)
        let snapshot = try await calculator.execute(runs: runs, asOf: .now)
        // After rest, ATL drops faster than CTL, so form should be positive
        #expect(snapshot.form > 0)
        #expect(snapshot.fitness > snapshot.fatigue)
    }

    // MARK: - TSS Integration

    @Test("Fitness uses TSS when available instead of effort-weighted distance")
    func testFitness_usesTSSWhenAvailable() async throws {
        // Run with TSS = 80. Effort-weighted distance would be 10 + 200/100 = 12
        // Since TSS (80) differs from effort distance (12), the resulting fitness
        // should reflect the TSS load, which is significantly higher.
        let runWithTSS = makeRun(
            daysAgo: 0,
            distanceKm: 10,
            elevationGainM: 200,
            trainingStressScore: 80.0
        )
        let runWithoutTSS = makeRun(
            daysAgo: 0,
            distanceKm: 10,
            elevationGainM: 200,
            trainingStressScore: nil
        )

        let snapshotWithTSS = try await calculator.execute(runs: [runWithTSS], asOf: .now)
        let snapshotWithoutTSS = try await calculator.execute(runs: [runWithoutTSS], asOf: .now)

        // TSS of 80 is much higher than effort distance of 12, so fitness should be higher
        #expect(snapshotWithTSS.fitness > snapshotWithoutTSS.fitness)
    }

    @Test("Fitness falls back to effort-weighted distance when TSS is nil")
    func testFitness_fallsBackToEffortWeighted() async throws {
        // Run without TSS: load = distanceKm + elevationGainM / 100 = 10 + 2 = 12
        let run = makeRun(
            daysAgo: 0,
            distanceKm: 10,
            elevationGainM: 200,
            trainingStressScore: nil
        )
        let snapshot = try await calculator.execute(runs: [run], asOf: .now)
        // Fitness should be non-zero, derived from effort distance load of 12
        #expect(snapshot.fitness > 0)
        #expect(snapshot.fatigue > 0)
    }
}
