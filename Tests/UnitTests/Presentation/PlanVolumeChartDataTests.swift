import Foundation
import Testing
@testable import UltraTrain

@Suite("PlanVolumeChartData Tests")
struct PlanVolumeChartDataTests {

    private func makeWeek(
        number: Int,
        phase: TrainingPhase = .build,
        targetKm: Double = 50,
        targetElevation: Double = 2000,
        completedCount: Int = 0
    ) -> TrainingWeek {
        let start = Calendar.current.date(byAdding: .weekOfYear, value: number - 1, to: .now)!
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start)!

        var sessions: [TrainingSession] = [
            TrainingSession(
                id: UUID(), date: start, type: .rest,
                plannedDistanceKm: 0, plannedElevationGainM: 0,
                plannedDuration: 0, intensity: .easy,
                description: "Rest", isCompleted: false, isSkipped: false, linkedRunId: nil
            ),
            TrainingSession(
                id: UUID(), date: start.addingTimeInterval(86400), type: .tempo,
                plannedDistanceKm: 10, plannedElevationGainM: 300,
                plannedDuration: 3600, intensity: .moderate,
                description: "Tempo", isCompleted: false, isSkipped: false, linkedRunId: nil
            ),
            TrainingSession(
                id: UUID(), date: start.addingTimeInterval(2 * 86400), type: .longRun,
                plannedDistanceKm: 25, plannedElevationGainM: 1000,
                plannedDuration: 10800, intensity: .easy,
                description: "Long run", isCompleted: false, isSkipped: false, linkedRunId: nil
            ),
        ]

        for i in 0..<min(completedCount, sessions.count) {
            sessions[i].isCompleted = true
        }

        return TrainingWeek(
            id: UUID(),
            weekNumber: number,
            startDate: start,
            endDate: end,
            phase: phase,
            sessions: sessions,
            isRecoveryWeek: false,
            targetVolumeKm: targetKm,
            targetElevationGainM: targetElevation
        )
    }

    @Test("extracts correct number of data points")
    func correctCount() {
        let weeks = (1...4).map { makeWeek(number: $0) }
        let points = PlanVolumeChartData.extract(from: weeks)
        #expect(points.count == 4)
    }

    @Test("planned distance matches target volume")
    func plannedDistance() {
        let weeks = [makeWeek(number: 1, targetKm: 60)]
        let points = PlanVolumeChartData.extract(from: weeks)
        #expect(points.first?.plannedDistanceKm == 60)
    }

    @Test("planned elevation matches target elevation")
    func plannedElevation() {
        let weeks = [makeWeek(number: 1, targetElevation: 3000)]
        let points = PlanVolumeChartData.extract(from: weeks)
        #expect(points.first?.plannedElevationM == 3000)
    }

    @Test("completed distance sums only completed non-rest sessions")
    func completedDistance() {
        let weeks = [makeWeek(number: 1, completedCount: 2)]
        let points = PlanVolumeChartData.extract(from: weeks)
        // Rest (0km completed=true) + Tempo (10km completed=true) = 10km
        #expect(points.first?.completedDistanceKm == 10)
    }

    @Test("no completed sessions returns zero completed values")
    func noCompleted() {
        let weeks = [makeWeek(number: 1, completedCount: 0)]
        let points = PlanVolumeChartData.extract(from: weeks)
        #expect(points.first?.completedDistanceKm == 0)
        #expect(points.first?.completedDurationSeconds == 0)
        #expect(points.first?.completedElevationM == 0)
    }

    @Test("week numbers are preserved")
    func weekNumbers() {
        let weeks = [makeWeek(number: 3), makeWeek(number: 7)]
        let points = PlanVolumeChartData.extract(from: weeks)
        #expect(points.map(\.weekNumber) == [3, 7])
    }

    @Test("phase is preserved")
    func phasePreserved() {
        let weeks = [makeWeek(number: 1, phase: .peak)]
        let points = PlanVolumeChartData.extract(from: weeks)
        #expect(points.first?.phase == .peak)
    }

    @Test("empty weeks returns empty data points")
    func emptyWeeks() {
        let points = PlanVolumeChartData.extract(from: [])
        #expect(points.isEmpty)
    }
}
