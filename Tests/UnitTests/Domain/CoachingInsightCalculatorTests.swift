import Foundation
import Testing
@testable import UltraTrain

@Suite("CoachingInsightCalculator Tests")
struct CoachingInsightCalculatorTests {

    private func makeSnapshot(
        fitness: Double = 50,
        fatigue: Double = 40,
        form: Double = 10,
        acr: Double = 1.0
    ) -> FitnessSnapshot {
        FitnessSnapshot(
            id: UUID(),
            date: .now,
            fitness: fitness,
            fatigue: fatigue,
            form: form,
            weeklyVolumeKm: 40,
            weeklyElevationGainM: 800,
            weeklyDuration: 14400,
            acuteToChronicRatio: acr,
            monotony: 1.0
        )
    }

    private func makeRace(daysFromNow: Int) -> Race {
        Race(
            id: UUID(),
            name: "Test Race",
            date: Date.now.adding(days: daysFromNow),
            distanceKm: 50,
            elevationGainM: 2000,
            elevationLossM: 2000,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
        )
    }

    private func makePlan(
        currentPhase: TrainingPhase = .build,
        previousPhase: TrainingPhase? = nil,
        longRunCompleted: Bool = true,
        targetVolumeKm: Double = 50,
        completedSessions: Int = 4,
        totalSessions: Int = 5
    ) -> TrainingPlan {
        let now = Date.now
        let weekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!

        var sessions: [TrainingSession] = []
        for i in 0..<totalSessions {
            let type: SessionType = (i == 0) ? .longRun : [.tempo, .intervals, .recovery, .crossTraining][min(i - 1, 3)]
            let isCompleted = i < completedSessions
            let isLongRunDone = (type == .longRun) ? longRunCompleted : isCompleted
            sessions.append(TrainingSession(
                id: UUID(),
                date: Calendar.current.date(byAdding: .day, value: i, to: weekStart)!,
                type: type,
                plannedDistanceKm: type == .longRun ? 25 : 10,
                plannedElevationGainM: 200,
                plannedDuration: 3600,
                intensity: .moderate,
                description: "\(type.rawValue)",
                isCompleted: type == .longRun ? isLongRunDone : isCompleted,
                isSkipped: false
            ))
        }

        var weeks = [TrainingWeek(
            id: UUID(),
            weekNumber: 2,
            startDate: weekStart,
            endDate: weekEnd,
            phase: currentPhase,
            sessions: sessions,
            isRecoveryWeek: false,
            targetVolumeKm: targetVolumeKm,
            targetElevationGainM: 1000
        )]

        if let prevPhase = previousPhase {
            let prevStart = Calendar.current.date(byAdding: .day, value: -7, to: weekStart)!
            let prevEnd = Calendar.current.date(byAdding: .day, value: -1, to: weekStart)!
            weeks.insert(TrainingWeek(
                id: UUID(),
                weekNumber: 1,
                startDate: prevStart,
                endDate: prevEnd,
                phase: prevPhase,
                sessions: [],
                isRecoveryWeek: false,
                targetVolumeKm: 40,
                targetElevationGainM: 800
            ), at: 0)
        }

        return TrainingPlan(
            id: UUID(),
            athleteId: UUID(),
            targetRaceId: UUID(),
            createdAt: .now,
            weeks: weeks,
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
    }

    // MARK: - No Data

    @Test("No fitness data returns empty insights")
    func noFitnessData() {
        let results = CoachingInsightCalculator.generate(
            fitness: nil, plan: nil, weeklyVolumes: [], nextRace: nil, adherencePercent: nil
        )
        #expect(results.isEmpty)
    }

    // MARK: - Race Week

    @Test("Race within 7 days triggers raceWeek insight")
    func raceWeek() {
        let race = makeRace(daysFromNow: 3)
        let results = CoachingInsightCalculator.generate(
            fitness: makeSnapshot(), plan: nil, weeklyVolumes: [], nextRace: race, adherencePercent: nil
        )
        #expect(results.contains { $0.type == .raceWeek })
        #expect(results.first?.type == .raceWeek)
    }

    // MARK: - Ready to Race

    @Test("Race within 14 days and good form triggers readyToRace")
    func readyToRace() {
        let race = makeRace(daysFromNow: 10)
        let snapshot = makeSnapshot(form: 12)
        let results = CoachingInsightCalculator.generate(
            fitness: snapshot, plan: nil, weeklyVolumes: [], nextRace: race, adherencePercent: nil
        )
        #expect(results.contains { $0.type == .readyToRace })
    }

    @Test("Race within 14 days but low form does not trigger readyToRace")
    func readyToRaceLowForm() {
        let race = makeRace(daysFromNow: 10)
        let snapshot = makeSnapshot(form: -5)
        let results = CoachingInsightCalculator.generate(
            fitness: snapshot, plan: nil, weeklyVolumes: [], nextRace: race, adherencePercent: nil
        )
        #expect(!results.contains { $0.type == .readyToRace })
    }

    // MARK: - Taper Guidance

    @Test("Taper phase triggers taperGuidance")
    func taperGuidance() {
        let plan = makePlan(currentPhase: .taper)
        let results = CoachingInsightCalculator.generate(
            fitness: makeSnapshot(), plan: plan, weeklyVolumes: [], nextRace: nil, adherencePercent: nil
        )
        #expect(results.contains { $0.type == .taperGuidance })
    }

    // MARK: - Form Peaking

    @Test("Form above 15 with no race soon triggers formPeaking")
    func formPeaking() {
        let snapshot = makeSnapshot(form: 20)
        let results = CoachingInsightCalculator.generate(
            fitness: snapshot, plan: nil, weeklyVolumes: [], nextRace: nil, adherencePercent: nil
        )
        #expect(results.contains { $0.type == .formPeaking })
    }

    @Test("Form above 15 with race within 14 days does not trigger formPeaking")
    func formPeakingWithRaceSoon() {
        let snapshot = makeSnapshot(form: 20)
        let race = makeRace(daysFromNow: 10)
        let results = CoachingInsightCalculator.generate(
            fitness: snapshot, plan: nil, weeklyVolumes: [], nextRace: race, adherencePercent: nil
        )
        #expect(!results.contains { $0.type == .formPeaking })
    }

    // MARK: - Recovery Needed

    @Test("Form below -15 triggers recoveryNeeded")
    func recoveryNeeded() {
        let snapshot = makeSnapshot(form: -20)
        let results = CoachingInsightCalculator.generate(
            fitness: snapshot, plan: nil, weeklyVolumes: [], nextRace: nil, adherencePercent: nil
        )
        #expect(results.contains { $0.type == .recoveryNeeded })
        #expect(results.first(where: { $0.type == .recoveryNeeded })?.category == .warning)
    }

    // MARK: - Detraining Risk

    @Test("Low ACR with fitness above 10 triggers detrainingRisk")
    func detrainingRisk() {
        let snapshot = makeSnapshot(fitness: 30, acr: 0.6)
        let results = CoachingInsightCalculator.generate(
            fitness: snapshot, plan: nil, weeklyVolumes: [], nextRace: nil, adherencePercent: nil
        )
        #expect(results.contains { $0.type == .detrainingRisk })
    }

    @Test("Low ACR with low fitness does not trigger detrainingRisk")
    func detrainingRiskLowFitness() {
        let snapshot = makeSnapshot(fitness: 5, acr: 0.6)
        let results = CoachingInsightCalculator.generate(
            fitness: snapshot, plan: nil, weeklyVolumes: [], nextRace: nil, adherencePercent: nil
        )
        #expect(!results.contains { $0.type == .detrainingRisk })
    }

    // MARK: - Phase Transition

    @Test("Phase change triggers phaseTransition")
    func phaseTransition() {
        let plan = makePlan(currentPhase: .build, previousPhase: .base)
        let results = CoachingInsightCalculator.generate(
            fitness: makeSnapshot(), plan: plan, weeklyVolumes: [], nextRace: nil, adherencePercent: nil
        )
        #expect(results.contains { $0.type == .phaseTransition })
    }

    @Test("Same phase does not trigger phaseTransition")
    func samePhase() {
        let plan = makePlan(currentPhase: .build, previousPhase: .build)
        let results = CoachingInsightCalculator.generate(
            fitness: makeSnapshot(), plan: plan, weeklyVolumes: [], nextRace: nil, adherencePercent: nil
        )
        #expect(!results.contains { $0.type == .phaseTransition })
    }

    // MARK: - Consistent Training

    @Test("High adherence triggers consistentTraining")
    func consistentTraining() {
        let results = CoachingInsightCalculator.generate(
            fitness: makeSnapshot(), plan: nil, weeklyVolumes: [], nextRace: nil, adherencePercent: 0.95
        )
        #expect(results.contains { $0.type == .consistentTraining })
    }

    @Test("Low adherence does not trigger consistentTraining")
    func lowAdherence() {
        let results = CoachingInsightCalculator.generate(
            fitness: makeSnapshot(), plan: nil, weeklyVolumes: [], nextRace: nil, adherencePercent: 0.5
        )
        #expect(!results.contains { $0.type == .consistentTraining })
    }

    // MARK: - Max Insights Cap

    @Test("Maximum 3 insights returned")
    func maxThreeInsights() {
        let snapshot = makeSnapshot(form: 20)
        let plan = makePlan(currentPhase: .build, previousPhase: .base)
        let results = CoachingInsightCalculator.generate(
            fitness: snapshot, plan: plan, weeklyVolumes: [], nextRace: nil, adherencePercent: 0.95
        )
        #expect(results.count <= 3)
    }

    // MARK: - Priority Ordering

    @Test("raceWeek has highest priority")
    func raceWeekPriority() {
        let race = makeRace(daysFromNow: 3)
        let snapshot = makeSnapshot(form: 20)
        let results = CoachingInsightCalculator.generate(
            fitness: snapshot, plan: nil, weeklyVolumes: [], nextRace: race, adherencePercent: 0.95
        )
        #expect(results.first?.type == .raceWeek)
    }

    // MARK: - Categories

    @Test("Positive insights use correct category")
    func positiveCategory() {
        let snapshot = makeSnapshot(form: 20)
        let results = CoachingInsightCalculator.generate(
            fitness: snapshot, plan: nil, weeklyVolumes: [], nextRace: nil, adherencePercent: nil
        )
        let peaking = results.first { $0.type == .formPeaking }
        #expect(peaking?.category == .positive)
    }

    @Test("Warning insights use correct category")
    func warningCategory() {
        let snapshot = makeSnapshot(form: -20)
        let results = CoachingInsightCalculator.generate(
            fitness: snapshot, plan: nil, weeklyVolumes: [], nextRace: nil, adherencePercent: nil
        )
        let recovery = results.first { $0.type == .recoveryNeeded }
        #expect(recovery?.category == .warning)
    }

    @Test("Guidance insights use correct category")
    func guidanceCategory() {
        let race = makeRace(daysFromNow: 3)
        let results = CoachingInsightCalculator.generate(
            fitness: makeSnapshot(), plan: nil, weeklyVolumes: [], nextRace: race, adherencePercent: nil
        )
        let raceWeek = results.first { $0.type == .raceWeek }
        #expect(raceWeek?.category == .guidance)
    }

    // MARK: - Sleep / Recovery Insights

    private func makeRecoveryScore(
        overall: Int,
        sleepQuality: Int = 60,
        status: RecoveryStatus = .moderate
    ) -> RecoveryScore {
        RecoveryScore(
            id: UUID(),
            date: .now,
            overallScore: overall,
            sleepQualityScore: sleepQuality,
            sleepConsistencyScore: 60,
            restingHRScore: 60,
            trainingLoadBalanceScore: 60,
            recommendation: "Test",
            status: status
        )
    }

    @Test("Low recovery score triggers poorSleepRecovery insight")
    func poorSleepRecoveryInsight() {
        let recovery = makeRecoveryScore(overall: 25, sleepQuality: 25, status: .poor)
        let results = CoachingInsightCalculator.generate(
            fitness: makeSnapshot(), plan: nil, weeklyVolumes: [],
            nextRace: nil, adherencePercent: nil, recoveryScore: recovery
        )
        #expect(results.contains { $0.type == .poorSleepRecovery })
        #expect(results.first(where: { $0.type == .poorSleepRecovery })?.category == .warning)
    }

    @Test("Low sleep quality but decent overall triggers sleepDeficit insight")
    func sleepDeficitInsight() {
        let recovery = makeRecoveryScore(overall: 55, sleepQuality: 30, status: .moderate)
        let results = CoachingInsightCalculator.generate(
            fitness: makeSnapshot(), plan: nil, weeklyVolumes: [],
            nextRace: nil, adherencePercent: nil, recoveryScore: recovery
        )
        #expect(results.contains { $0.type == .sleepDeficit })
    }

    @Test("High recovery score triggers goodRecovery insight")
    func goodRecoveryInsight() {
        let recovery = makeRecoveryScore(overall: 85, sleepQuality: 85, status: .excellent)
        let results = CoachingInsightCalculator.generate(
            fitness: makeSnapshot(), plan: nil, weeklyVolumes: [],
            nextRace: nil, adherencePercent: nil, recoveryScore: recovery
        )
        #expect(results.contains { $0.type == .goodRecovery })
        #expect(results.first(where: { $0.type == .goodRecovery })?.category == .positive)
    }
}
