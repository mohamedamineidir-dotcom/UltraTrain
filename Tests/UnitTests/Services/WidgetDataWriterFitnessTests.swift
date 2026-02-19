import Foundation
import Testing
@testable import UltraTrain

@Suite("Widget Data Writer Fitness Tests")
struct WidgetDataWriterFitnessTests {

    private func testDefaults() -> UserDefaults {
        UserDefaults(suiteName: "test.writerfitness.\(UUID().uuidString)")!
    }

    private func makeSnapshot(
        date: Date = .now,
        form: Double = 12,
        fitness: Double = 65,
        fatigue: Double = 53
    ) -> FitnessSnapshot {
        FitnessSnapshot(
            id: UUID(),
            date: date,
            fitness: fitness,
            fatigue: fatigue,
            form: form,
            weeklyVolumeKm: 50,
            weeklyElevationGainM: 1500,
            weeklyDuration: 18000,
            acuteToChronicRatio: 1.1,
            monotony: 1.5
        )
    }

    @Test("Writes fitness data with latest snapshot")
    func writesFitnessData() async {
        let defaults = testDefaults()
        let fitnessRepo = MockFitnessRepository()
        fitnessRepo.snapshots = [makeSnapshot(form: 15, fitness: 70, fatigue: 55)]

        let writer = WidgetDataWriter(
            planRepository: MockTrainingPlanRepository(),
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            fitnessRepository: fitnessRepo,
            defaults: defaults
        )

        await writer.writeFitnessData()

        let data = defaults.data(forKey: WidgetDataKeys.fitnessData)
        #expect(data != nil)

        let decoded = try? JSONDecoder().decode(WidgetFitnessData.self, from: data!)
        #expect(decoded?.form == 15)
        #expect(decoded?.fitness == 70)
        #expect(decoded?.fatigue == 55)
    }

    @Test("Clears fitness data when no snapshot exists")
    func clearsWhenNoSnapshot() async {
        let defaults = testDefaults()
        defaults.set(Data(), forKey: WidgetDataKeys.fitnessData)

        let fitnessRepo = MockFitnessRepository()
        let writer = WidgetDataWriter(
            planRepository: MockTrainingPlanRepository(),
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            fitnessRepository: fitnessRepo,
            defaults: defaults
        )

        await writer.writeFitnessData()

        #expect(defaults.data(forKey: WidgetDataKeys.fitnessData) == nil)
    }

    @Test("Sparkline contains 14-day history points")
    func sparklineHas14DayHistory() async {
        let defaults = testDefaults()
        let fitnessRepo = MockFitnessRepository()

        // Create 14 snapshots over 14 days
        for i in 0..<14 {
            let date = Calendar.current.date(byAdding: .day, value: -13 + i, to: .now)!
            fitnessRepo.snapshots.append(makeSnapshot(
                date: date,
                form: Double(i) - 5
            ))
        }

        let writer = WidgetDataWriter(
            planRepository: MockTrainingPlanRepository(),
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            fitnessRepository: fitnessRepo,
            defaults: defaults
        )

        await writer.writeFitnessData()

        let data = defaults.data(forKey: WidgetDataKeys.fitnessData)
        #expect(data != nil)

        let decoded = try? JSONDecoder().decode(WidgetFitnessData.self, from: data!)
        #expect(decoded?.trend.count == 14)
    }

    @Test("Clears fitness data when no repository provided")
    func clearsWhenNoRepository() async {
        let defaults = testDefaults()
        defaults.set(Data(), forKey: WidgetDataKeys.fitnessData)

        let writer = WidgetDataWriter(
            planRepository: MockTrainingPlanRepository(),
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            defaults: defaults
        )

        await writer.writeFitnessData()

        #expect(defaults.data(forKey: WidgetDataKeys.fitnessData) == nil)
    }
}
