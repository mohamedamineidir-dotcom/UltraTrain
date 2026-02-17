import Foundation
import Testing
@testable import UltraTrain

@Suite("Progress ViewModel Trends Tests")
struct ProgressViewModelTrendsTests {

    private let athleteId = UUID()

    private func makeAthlete() -> Athlete {
        Athlete(
            id: athleteId,
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 50,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 50,
            longestRunKm: 30,
            preferredUnit: .metric
        )
    }

    private func makeRun(
        daysAgo: Int = 0,
        distanceKm: Double = 10,
        elevationGainM: Double = 200,
        duration: TimeInterval = 3600,
        averagePaceSecondsPerKm: Double = 360,
        averageHeartRate: Int? = 150
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: Date.now.adding(days: -daysAgo),
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 180,
            duration: duration,
            averageHeartRate: averageHeartRate,
            maxHeartRate: averageHeartRate.map { $0 + 25 },
            averagePaceSecondsPerKm: averagePaceSecondsPerKm,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    @MainActor
    private func makeViewModel(
        runRepo: MockRunRepository = MockRunRepository(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository(),
        fitnessCalc: MockCalculateFitnessUseCase = MockCalculateFitnessUseCase(),
        fitnessRepo: MockFitnessRepository = MockFitnessRepository()
    ) -> ProgressViewModel {
        ProgressViewModel(
            runRepository: runRepo,
            athleteRepository: athleteRepo,
            planRepository: planRepo,
            fitnessCalculator: fitnessCalc,
            fitnessRepository: fitnessRepo
        )
    }

    // MARK: - Run Trends

    @Test("Compute run trends produces sorted trend points")
    @MainActor
    func runTrendsSorted() async {
        let vm = makeViewModel()
        let runs = [
            makeRun(daysAgo: 10, averagePaceSecondsPerKm: 360),
            makeRun(daysAgo: 5, averagePaceSecondsPerKm: 350),
            makeRun(daysAgo: 0, averagePaceSecondsPerKm: 340)
        ]

        let trends = vm.computeRunTrends(from: runs)

        #expect(trends.count == 3)
        #expect(trends[0].date < trends[1].date)
        #expect(trends[1].date < trends[2].date)
    }

    @Test("Rolling average pace computed with window of 5")
    @MainActor
    func rollingAveragePace() async {
        let vm = makeViewModel()
        let runs = (0..<6).map { i in
            makeRun(
                daysAgo: 30 - (i * 5),
                averagePaceSecondsPerKm: Double(360 - i * 10)
            )
        }

        let trends = vm.computeRunTrends(from: runs)

        #expect(trends.count == 6)
        // First point: only 1 run, no rolling average
        #expect(trends[0].rollingAveragePace == nil)
        // Second point: 2 runs → rolling average exists
        #expect(trends[1].rollingAveragePace != nil)
        // 6th point (index 5): window of runs[1..5] (5 runs)
        let expectedAvg = (Double(360 - 10) + Double(360 - 20) + Double(360 - 30) + Double(360 - 40) + Double(360 - 50)) / 5.0
        #expect(trends[5].rollingAveragePace! == expectedAvg)
    }

    @Test("Rolling average HR skips nil values")
    @MainActor
    func rollingAverageSkipsNilHR() async {
        let vm = makeViewModel()
        let runs = [
            makeRun(daysAgo: 10, averageHeartRate: nil),
            makeRun(daysAgo: 5, averageHeartRate: 150),
            makeRun(daysAgo: 0, averageHeartRate: nil)
        ]

        let trends = vm.computeRunTrends(from: runs)

        // Only 1 non-nil HR in window → no rolling average
        #expect(trends[0].rollingAverageHR == nil)
        #expect(trends[1].rollingAverageHR == nil) // only 1 HR value in window
        #expect(trends[2].rollingAverageHR == nil) // only 1 HR value in window
    }

    @Test("Rolling average HR computed when enough values")
    @MainActor
    func rollingAverageHRComputed() async {
        let vm = makeViewModel()
        let runs = [
            makeRun(daysAgo: 10, averageHeartRate: 140),
            makeRun(daysAgo: 5, averageHeartRate: 150),
            makeRun(daysAgo: 0, averageHeartRate: 160)
        ]

        let trends = vm.computeRunTrends(from: runs)

        #expect(trends[0].rollingAverageHR == nil) // only 1 value
        #expect(trends[1].rollingAverageHR != nil) // 2 values → average
        #expect(trends[1].rollingAverageHR == 145) // (140+150)/2
        #expect(trends[2].rollingAverageHR != nil) // 3 values → average
        #expect(trends[2].rollingAverageHR == 150) // (140+150+160)/3
    }

    @Test("Trend points empty when no runs")
    @MainActor
    func trendPointsEmptyNoRuns() async {
        let vm = makeViewModel()
        let trends = vm.computeRunTrends(from: [])
        #expect(trends.isEmpty)
    }

    // MARK: - Personal Records

    @Test("Personal records finds correct values")
    @MainActor
    func personalRecordsCorrectValues() async {
        let vm = makeViewModel()
        let runs = [
            makeRun(daysAgo: 10, distanceKm: 15, elevationGainM: 300, duration: 5400, averagePaceSecondsPerKm: 360),
            makeRun(daysAgo: 5, distanceKm: 30, elevationGainM: 800, duration: 10800, averagePaceSecondsPerKm: 400),
            makeRun(daysAgo: 0, distanceKm: 10, elevationGainM: 100, duration: 2700, averagePaceSecondsPerKm: 270)
        ]

        let records = vm.computePersonalRecords(from: runs)

        #expect(records.count == 4)

        let distance = records.first { $0.type == .longestDistance }
        #expect(distance?.value == 30)

        let elevation = records.first { $0.type == .mostElevation }
        #expect(elevation?.value == 800)

        let pace = records.first { $0.type == .fastestPace }
        #expect(pace?.value == 270)

        let duration = records.first { $0.type == .longestDuration }
        #expect(duration?.value == 10800)
    }

    @Test("Personal records empty when no runs")
    @MainActor
    func personalRecordsEmptyNoRuns() async {
        let vm = makeViewModel()
        let records = vm.computePersonalRecords(from: [])
        #expect(records.isEmpty)
    }

    // MARK: - Integration via load()

    @Test("Load populates trend points and personal records")
    @MainActor
    func loadPopulatesTrends() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [
            makeRun(daysAgo: 7, distanceKm: 15),
            makeRun(daysAgo: 3, distanceKm: 20),
            makeRun(daysAgo: 0, distanceKm: 10)
        ]

        let vm = makeViewModel(runRepo: runRepo, athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.runTrendPoints.count == 3)
        #expect(vm.personalRecords.count == 4)
        #expect(vm.runTrendPoints[0].date < vm.runTrendPoints[1].date)
    }
}
