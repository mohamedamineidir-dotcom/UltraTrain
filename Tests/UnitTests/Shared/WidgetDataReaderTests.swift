import Foundation
import Testing
@testable import UltraTrain

@Suite("Widget Data Reader Tests")
struct WidgetDataReaderTests {

    private func testDefaults() -> UserDefaults {
        UserDefaults(suiteName: "test.widgetreader.\(UUID().uuidString)")!
    }

    private func write<T: Encodable>(_ value: T, key: String, to defaults: UserDefaults) {
        let data = try! JSONEncoder().encode(value)
        defaults.set(data, forKey: key)
    }

    // MARK: - Round-Trip Tests

    @Test("Round-trip next session data")
    func roundTripNextSession() {
        let defaults = testDefaults()
        let session = WidgetSessionData(
            sessionType: "longRun",
            sessionIcon: "figure.run",
            displayName: "Long Run",
            description: "Steady state long run",
            plannedDistanceKm: 25,
            plannedElevationGainM: 800,
            plannedDuration: 7200,
            intensity: "moderate",
            date: Date(timeIntervalSinceReferenceDate: 700000000)
        )
        write(session, key: WidgetDataKeys.nextSession, to: defaults)

        guard let data = defaults.data(forKey: WidgetDataKeys.nextSession),
              let result = try? JSONDecoder().decode(WidgetSessionData.self, from: data) else {
            Issue.record("Failed to decode")
            return
        }

        #expect(result.sessionType == "longRun")
        #expect(result.displayName == "Long Run")
        #expect(result.plannedDistanceKm == 25)
        #expect(result.plannedElevationGainM == 800)
    }

    @Test("Round-trip race countdown data")
    func roundTripRaceCountdown() {
        let defaults = testDefaults()
        let race = WidgetRaceData(
            name: "UTMB",
            date: Date(timeIntervalSinceReferenceDate: 750000000),
            distanceKm: 171,
            elevationGainM: 10000,
            planCompletionPercent: 0.65
        )
        write(race, key: WidgetDataKeys.raceCountdown, to: defaults)

        guard let data = defaults.data(forKey: WidgetDataKeys.raceCountdown),
              let result = try? JSONDecoder().decode(WidgetRaceData.self, from: data) else {
            Issue.record("Failed to decode")
            return
        }

        #expect(result.name == "UTMB")
        #expect(result.distanceKm == 171)
        #expect(result.planCompletionPercent == 0.65)
    }

    @Test("Round-trip weekly progress data")
    func roundTripWeeklyProgress() {
        let defaults = testDefaults()
        let progress = WidgetWeeklyProgressData(
            actualDistanceKm: 45,
            targetDistanceKm: 70,
            actualElevationGainM: 1200,
            targetElevationGainM: 2000,
            phase: "build",
            weekNumber: 8
        )
        write(progress, key: WidgetDataKeys.weeklyProgress, to: defaults)

        guard let data = defaults.data(forKey: WidgetDataKeys.weeklyProgress),
              let result = try? JSONDecoder().decode(WidgetWeeklyProgressData.self, from: data) else {
            Issue.record("Failed to decode")
            return
        }

        #expect(result.actualDistanceKm == 45)
        #expect(result.targetDistanceKm == 70)
        #expect(result.phase == "build")
        #expect(result.weekNumber == 8)
    }

    @Test("Round-trip last run data")
    func roundTripLastRun() {
        let defaults = testDefaults()
        let run = WidgetLastRunData(
            date: Date(timeIntervalSinceReferenceDate: 700000000),
            distanceKm: 18.5,
            elevationGainM: 650,
            duration: 5400,
            averagePaceSecondsPerKm: 360,
            averageHeartRate: 148
        )
        write(run, key: WidgetDataKeys.lastRun, to: defaults)

        guard let data = defaults.data(forKey: WidgetDataKeys.lastRun),
              let result = try? JSONDecoder().decode(WidgetLastRunData.self, from: data) else {
            Issue.record("Failed to decode")
            return
        }

        #expect(result.distanceKm == 18.5)
        #expect(result.elevationGainM == 650)
        #expect(result.averagePaceSecondsPerKm == 360)
        #expect(result.averageHeartRate == 148)
    }

    @Test("Last run with nil heart rate")
    func roundTripLastRunNilHR() {
        let defaults = testDefaults()
        let run = WidgetLastRunData(
            date: .now,
            distanceKm: 10,
            elevationGainM: 200,
            duration: 3600,
            averagePaceSecondsPerKm: 360,
            averageHeartRate: nil
        )
        write(run, key: WidgetDataKeys.lastRun, to: defaults)

        guard let data = defaults.data(forKey: WidgetDataKeys.lastRun),
              let result = try? JSONDecoder().decode(WidgetLastRunData.self, from: data) else {
            Issue.record("Failed to decode")
            return
        }

        #expect(result.averageHeartRate == nil)
    }

    // MARK: - Missing Data

    @Test("Returns nil when no data exists")
    func returnsNilWhenEmpty() {
        let defaults = testDefaults()
        let data = defaults.data(forKey: WidgetDataKeys.nextSession)
        #expect(data == nil)
    }
}
