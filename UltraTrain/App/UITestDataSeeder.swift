#if DEBUG
import Foundation
import SwiftData

enum UITestDataSeeder {

    static func seed(into container: ModelContainer) {
        let context = ModelContext(container)

        let athleteId = UUID()
        let raceId = UUID()

        seedAthlete(id: athleteId, into: context)
        seedRace(id: raceId, into: context)
        seedTrainingPlan(athleteId: athleteId, raceId: raceId, into: context)
        seedAppSettings(into: context)
        seedGear(into: context)

        try? context.save()
    }

    // MARK: - Athlete

    private static func seedAthlete(id: UUID, into context: ModelContext) {
        let dob = Calendar.current.date(byAdding: .year, value: -30, to: .now)!
        let athlete = AthleteSwiftDataModel(
            id: id,
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: dob,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 60,
            maxHeartRate: 185,
            experienceLevelRaw: "intermediate",
            weeklyVolumeKm: 40,
            longestRunKm: 30,
            preferredUnitRaw: "metric"
        )
        context.insert(athlete)
    }

    // MARK: - Race

    private static func seedRace(id: UUID, into context: ModelContext) {
        let raceDate = Calendar.current.date(byAdding: .month, value: 6, to: .now)!
        let race = RaceSwiftDataModel(
            id: id,
            name: "Test Ultra 50K",
            date: raceDate,
            distanceKm: 50,
            elevationGainM: 2000,
            elevationLossM: 2000,
            priorityRaw: "aRace",
            goalTypeRaw: "finish",
            goalValue: nil,
            terrainDifficultyRaw: "moderate"
        )
        context.insert(race)
    }

    // MARK: - Training Plan

    private static func seedTrainingPlan(athleteId: UUID, raceId: UUID, into context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 2), to: today)!

        let weeks = (0..<3).map { weekOffset -> TrainingWeekSwiftDataModel in
            let weekStart = calendar.date(byAdding: .day, value: weekOffset * 7, to: startOfWeek)!
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            let sessions = buildSessions(weekStart: weekStart, calendar: calendar)

            return TrainingWeekSwiftDataModel(
                id: UUID(),
                weekNumber: weekOffset + 1,
                startDate: weekStart,
                endDate: weekEnd,
                phaseRaw: "base",
                sessions: sessions,
                isRecoveryWeek: false,
                targetVolumeKm: 40,
                targetElevationGainM: 800
            )
        }

        let plan = TrainingPlanSwiftDataModel(
            id: UUID(),
            athleteId: athleteId,
            targetRaceId: raceId,
            createdAt: .now,
            weeks: weeks,
            intermediateRaceIds: []
        )
        context.insert(plan)
    }

    private static func buildSessions(
        weekStart: Date,
        calendar: Calendar
    ) -> [TrainingSessionSwiftDataModel] {
        let types: [(String, String, Double, Double, Double)] = [
            ("recovery", "easy", 8, 100, 45 * 60),
            ("tempo", "moderate", 12, 200, 60 * 60),
            ("rest", "easy", 0, 0, 0),
            ("intervals", "hard", 10, 150, 50 * 60),
            ("recovery", "easy", 8, 100, 45 * 60),
            ("longRun", "easy", 25, 600, 2.5 * 3600),
            ("rest", "easy", 0, 0, 0)
        ]

        return types.enumerated().map { dayOffset, config in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
            return TrainingSessionSwiftDataModel(
                id: UUID(),
                date: date,
                typeRaw: config.0,
                plannedDistanceKm: config.2,
                plannedElevationGainM: config.3,
                plannedDuration: config.4,
                intensityRaw: config.1,
                sessionDescription: "\(config.0.capitalized) session",
                nutritionNotes: nil,
                isCompleted: false,
                isSkipped: false,
                linkedRunId: nil
            )
        }
    }

    // MARK: - Gear

    private static func seedGear(into context: ModelContext) {
        let shoes = GearItemSwiftDataModel(
            id: UUID(),
            name: "Speedgoat 5",
            brand: "HOKA",
            typeRaw: "trailShoes",
            purchaseDate: Calendar.current.date(byAdding: .month, value: -3, to: .now)!,
            maxDistanceKm: 800,
            totalDistanceKm: 210,
            totalDuration: 72000,
            isRetired: false,
            notes: nil
        )
        let poles = GearItemSwiftDataModel(
            id: UUID(),
            name: "Trail Running Poles",
            brand: "Black Diamond",
            typeRaw: "poles",
            purchaseDate: Calendar.current.date(byAdding: .month, value: -6, to: .now)!,
            maxDistanceKm: 2000,
            totalDistanceKm: 450,
            totalDuration: 162000,
            isRetired: false,
            notes: nil
        )
        context.insert(shoes)
        context.insert(poles)
    }

    // MARK: - App Settings

    private static func seedAppSettings(into context: ModelContext) {
        let settings = AppSettingsSwiftDataModel(
            id: UUID(),
            trainingRemindersEnabled: false,
            nutritionRemindersEnabled: false,
            autoPauseEnabled: true,
            nutritionAlertSoundEnabled: false
        )
        context.insert(settings)
    }
}
#endif
