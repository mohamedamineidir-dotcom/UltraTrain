import Testing
import Foundation
@testable import UltraTrain

@Suite("RunningHistoryCalculator Tests")
struct RunningHistoryCalculatorTests {

    private func makeWorkout(
        startDate: Date, distanceKm: Double
    ) -> HealthKitWorkout {
        HealthKitWorkout(
            id: UUID(),
            originalUUID: UUID().uuidString,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(3600),
            distanceKm: distanceKm,
            elevationGainM: 0,
            duration: 3600,
            averageHeartRate: nil,
            maxHeartRate: nil,
            source: "Apple Watch",
            activityType: .running
        )
    }

    @Test("Returns zero for empty workouts")
    func emptyWorkouts() {
        #expect(RunningHistoryCalculator.averageWeeklyKm(from: []) == 0)
    }

    @Test("Single workout returns its distance as weekly average")
    func singleWorkout() {
        let w = makeWorkout(startDate: .now, distanceKm: 20)
        #expect(RunningHistoryCalculator.averageWeeklyKm(from: [w]) == 20)
    }

    @Test("Two workouts in the same week sum correctly")
    func sameWeekWorkouts() {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: .now
        )
        let weekStart = calendar.date(from: components)!

        let w1 = makeWorkout(startDate: weekStart, distanceKm: 10)
        let w2 = makeWorkout(
            startDate: weekStart.addingTimeInterval(2 * 86400), distanceKm: 15
        )

        let avg = RunningHistoryCalculator.averageWeeklyKm(from: [w1, w2])
        #expect(avg == 25)
    }

    @Test("Two workouts in different weeks average correctly")
    func differentWeekWorkouts() {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: .now
        )
        let thisWeek = calendar.date(from: components)!
        let lastWeek = thisWeek.addingTimeInterval(-7 * 86400)

        let w1 = makeWorkout(startDate: thisWeek, distanceKm: 30)
        let w2 = makeWorkout(startDate: lastWeek, distanceKm: 10)

        let avg = RunningHistoryCalculator.averageWeeklyKm(from: [w1, w2])
        #expect(avg == 20)
    }

    @Test("Zero distance workouts are excluded")
    func zeroDistanceExcluded() {
        let w1 = makeWorkout(startDate: .now, distanceKm: 0)
        let w2 = makeWorkout(
            startDate: .now.addingTimeInterval(3600), distanceKm: 20
        )

        let avg = RunningHistoryCalculator.averageWeeklyKm(from: [w1, w2])
        #expect(avg == 20)
    }

    @Test("Only zero distance workouts returns zero")
    func onlyZeroDistance() {
        let w1 = makeWorkout(startDate: .now, distanceKm: 0)
        #expect(RunningHistoryCalculator.averageWeeklyKm(from: [w1]) == 0)
    }
}
