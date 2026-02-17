import Foundation
import Testing
@testable import UltraTrain

@Suite("RunAnalysis ViewModel Tests")
struct RunAnalysisViewModelTests {

    // MARK: - Helpers

    private func makeAthlete(maxHeartRate: Int = 185) -> Athlete {
        Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 50,
            maxHeartRate: maxHeartRate,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 50,
            longestRunKm: 30,
            preferredUnit: .metric
        )
    }

    private func makeTrackPoints(count: Int, withHR: Bool = false) -> [TrackPoint] {
        let baseDate = Date.now
        var points: [TrackPoint] = []
        for i in 0..<count {
            let lat = 45.0 + Double(i) * 0.0001
            let lon = 6.0 + Double(i) * 0.0001
            let alt = 500.0 + Double(i) * 2.0
            let time = baseDate.addingTimeInterval(Double(i) * 10)
            let hr: Int? = withHR ? 140 + (i % 40) : nil
            let point = TrackPoint(
                latitude: lat,
                longitude: lon,
                altitudeM: alt,
                timestamp: time,
                heartRate: hr
            )
            points.append(point)
        }
        return points
    }

    private func makeSplits(count: Int) -> [Split] {
        (1...count).map { km in
            Split(
                id: UUID(),
                kilometerNumber: km,
                duration: 300 + Double(km * 5),
                elevationChangeM: Double(km * 10),
                averageHeartRate: 150
            )
        }
    }

    private func makeRun(
        linkedSessionId: UUID? = nil,
        withHR: Bool = false
    ) -> CompletedRun {
        let avgHR: Int? = withHR ? 155 : nil
        let maxHR: Int? = withHR ? 180 : nil
        let track = makeTrackPoints(count: 50, withHR: withHR)
        let splits = makeSplits(count: 10)

        return CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: Date.now,
            distanceKm: 10,
            elevationGainM: 300,
            elevationLossM: 250,
            duration: 3600,
            averageHeartRate: avgHR,
            maxHeartRate: maxHR,
            averagePaceSecondsPerKm: 360,
            gpsTrack: track,
            splits: splits,
            linkedSessionId: linkedSessionId,
            notes: nil,
            pausedDuration: 0
        )
    }

    private func makeSession(id: UUID) -> TrainingSession {
        TrainingSession(
            id: id,
            date: Date.now,
            type: .longRun,
            plannedDistanceKm: 12,
            plannedElevationGainM: 400,
            plannedDuration: 4200,
            intensity: .moderate,
            description: "Long run with hills",
            nutritionNotes: nil,
            isCompleted: true, isSkipped: false,
            linkedRunId: nil
        )
    }

    private func makePlan(withSession session: TrainingSession) -> TrainingPlan {
        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: Date.now.addingTimeInterval(-86400),
            endDate: Date.now.addingTimeInterval(86400 * 6),
            phase: .build,
            sessions: [session],
            isRecoveryWeek: false,
            targetVolumeKm: 50,
            targetElevationGainM: 1500
        )
        return TrainingPlan(
            id: UUID(),
            athleteId: UUID(),
            targetRaceId: UUID(),
            createdAt: Date.now,
            weeks: [week],
            intermediateRaceIds: []
        )
    }

    @MainActor
    private func makeViewModel(
        run: CompletedRun,
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository(),
        raceRepo: MockRaceRepository = MockRaceRepository()
    ) -> RunAnalysisViewModel {
        RunAnalysisViewModel(
            run: run,
            planRepository: planRepo,
            athleteRepository: athleteRepo,
            raceRepository: raceRepo
        )
    }

    // MARK: - Elevation Profile

    @Test("Load computes elevation profile from GPS track")
    @MainActor
    func loadElevationProfile() async {
        let run = makeRun()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(run: run, athleteRepo: athleteRepo)
        await vm.load()

        #expect(!vm.elevationProfile.isEmpty)
        #expect(vm.elevationProfile[0].distanceKm == 0)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load with empty GPS track produces empty elevation profile")
    @MainActor
    func loadEmptyTrack() async {
        var run = makeRun()
        run.gpsTrack = []

        let vm = makeViewModel(run: run)
        await vm.load()

        #expect(vm.elevationProfile.isEmpty)
    }

    // MARK: - HR Zone Distribution

    @Test("Load computes HR zone distribution when HR data available")
    @MainActor
    func loadHRZones() async {
        let run = makeRun(withHR: true)
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete(maxHeartRate: 185)

        let vm = makeViewModel(run: run, athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.hasHeartRateData)
        #expect(vm.zoneDistribution.count == 5)
        let totalPercentage = vm.zoneDistribution.map(\.percentage).reduce(0, +)
        #expect(abs(totalPercentage - 100) < 1)
    }

    @Test("Load skips HR zones when no HR data in track")
    @MainActor
    func loadNoHRData() async {
        let run = makeRun(withHR: false)
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(run: run, athleteRepo: athleteRepo)
        await vm.load()

        #expect(!vm.hasHeartRateData)
    }

    @Test("Load skips HR zones when athlete has no maxHeartRate")
    @MainActor
    func loadNoMaxHR() async {
        let run = makeRun(withHR: true)
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete(maxHeartRate: 0)

        let vm = makeViewModel(run: run, athleteRepo: athleteRepo)
        await vm.load()

        #expect(!vm.hasHeartRateData)
    }

    // MARK: - Plan Comparison

    @Test("Load builds plan comparison when linked session exists")
    @MainActor
    func loadPlanComparison() async {
        let sessionId = UUID()
        let run = makeRun(linkedSessionId: sessionId)
        let session = makeSession(id: sessionId)
        let plan = makePlan(withSession: session)

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = plan

        let vm = makeViewModel(run: run, athleteRepo: athleteRepo, planRepo: planRepo)
        await vm.load()

        #expect(vm.hasLinkedSession)
        #expect(vm.planComparison?.plannedDistanceKm == 12)
        #expect(vm.planComparison?.actualDistanceKm == 10)
        #expect(vm.planComparison?.sessionType == .longRun)
    }

    @Test("Load handles no linked session gracefully")
    @MainActor
    func loadNoLinkedSession() async {
        let run = makeRun(linkedSessionId: nil)
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(run: run, athleteRepo: athleteRepo)
        await vm.load()

        #expect(!vm.hasLinkedSession)
        #expect(vm.planComparison == nil)
    }

    @Test("Load handles session not found in plan")
    @MainActor
    func loadSessionNotFound() async {
        let run = makeRun(linkedSessionId: UUID())
        let session = makeSession(id: UUID())
        let plan = makePlan(withSession: session)

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = plan

        let vm = makeViewModel(run: run, athleteRepo: athleteRepo, planRepo: planRepo)
        await vm.load()

        #expect(!vm.hasLinkedSession)
    }

    // MARK: - Error Handling

    @Test("Load handles repository error")
    @MainActor
    func loadError() async {
        let run = makeRun()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.shouldThrow = true

        let vm = makeViewModel(run: run, athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }
}
