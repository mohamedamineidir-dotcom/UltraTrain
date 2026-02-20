import Foundation
import Testing
@testable import UltraTrain

@Suite("Phase Visualization Calculator Tests")
struct PhaseVisualizationCalculatorTests {

    // MARK: - Helpers

    private func makeWeek(
        number: Int,
        phase: TrainingPhase,
        startDaysFromNow: Int
    ) -> TrainingWeek {
        let start = Date.now.adding(days: startDaysFromNow)
        return TrainingWeek(
            id: UUID(),
            weekNumber: number,
            startDate: start,
            endDate: start.adding(days: 6),
            phase: phase,
            sessions: [],
            isRecoveryWeek: false,
            targetVolumeKm: 50,
            targetElevationGainM: 1000
        )
    }

    private func makePlan(weeks: [TrainingWeek]) -> TrainingPlan {
        TrainingPlan(
            id: UUID(),
            athleteId: UUID(),
            targetRaceId: UUID(),
            createdAt: Date.now,
            weeks: weeks,
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
    }

    // MARK: - Tests

    @Test("Empty plan produces empty blocks")
    func emptyPlan() {
        let plan = makePlan(weeks: [])
        let blocks = PhaseVisualizationCalculator.computePhaseBlocks(from: plan)
        #expect(blocks.isEmpty)
    }

    @Test("Single phase plan produces one block")
    func singlePhase() {
        let plan = makePlan(weeks: [
            makeWeek(number: 1, phase: .base, startDaysFromNow: -14),
            makeWeek(number: 2, phase: .base, startDaysFromNow: -7),
            makeWeek(number: 3, phase: .base, startDaysFromNow: 0),
        ])

        let blocks = PhaseVisualizationCalculator.computePhaseBlocks(from: plan)
        #expect(blocks.count == 1)
        #expect(blocks[0].phase == .base)
        #expect(blocks[0].weekNumbers == [1, 2, 3])
    }

    @Test("Multiple phases produce correct blocks")
    func multiplePhases() {
        let plan = makePlan(weeks: [
            makeWeek(number: 1, phase: .base, startDaysFromNow: -28),
            makeWeek(number: 2, phase: .base, startDaysFromNow: -21),
            makeWeek(number: 3, phase: .build, startDaysFromNow: -14),
            makeWeek(number: 4, phase: .build, startDaysFromNow: -7),
            makeWeek(number: 5, phase: .peak, startDaysFromNow: 0),
            makeWeek(number: 6, phase: .taper, startDaysFromNow: 7),
        ])

        let blocks = PhaseVisualizationCalculator.computePhaseBlocks(from: plan)
        #expect(blocks.count == 4)
        #expect(blocks[0].phase == .base)
        #expect(blocks[0].weekNumbers == [1, 2])
        #expect(blocks[1].phase == .build)
        #expect(blocks[1].weekNumbers == [3, 4])
        #expect(blocks[2].phase == .peak)
        #expect(blocks[2].weekNumbers == [5])
        #expect(blocks[3].phase == .taper)
        #expect(blocks[3].weekNumbers == [6])
    }

    @Test("Current phase is correctly identified")
    func currentPhaseDetection() {
        let plan = makePlan(weeks: [
            makeWeek(number: 1, phase: .base, startDaysFromNow: -14),
            makeWeek(number: 2, phase: .build, startDaysFromNow: -3),
            makeWeek(number: 3, phase: .peak, startDaysFromNow: 7),
        ])

        let blocks = PhaseVisualizationCalculator.computePhaseBlocks(from: plan)
        #expect(blocks.count == 3)

        let currentBlocks = blocks.filter(\.isCurrentPhase)
        #expect(currentBlocks.count == 1)
        #expect(currentBlocks[0].phase == .build)
    }

    @Test("All future plan has no current phase")
    func allFuturePlan() {
        let plan = makePlan(weeks: [
            makeWeek(number: 1, phase: .base, startDaysFromNow: 7),
            makeWeek(number: 2, phase: .build, startDaysFromNow: 14),
        ])

        let blocks = PhaseVisualizationCalculator.computePhaseBlocks(from: plan)
        let currentBlocks = blocks.filter(\.isCurrentPhase)
        #expect(currentBlocks.isEmpty)
    }
}
