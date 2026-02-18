import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("CloudKit Model Compatibility Tests")
struct CloudKitModelCompatibilityTests {

    @Test("AthleteSwiftDataModel has CloudKit-compatible defaults")
    func athleteDefaults() {
        let model = AthleteSwiftDataModel()
        #expect(model.firstName == "")
        #expect(model.lastName == "")
        #expect(model.weightKg == 0)
        #expect(model.heightCm == 0)
        #expect(model.updatedAt <= Date())
    }

    @Test("CompletedRunSwiftDataModel has CloudKit-compatible defaults")
    func completedRunDefaults() {
        let model = CompletedRunSwiftDataModel()
        #expect(model.distanceKm == 0)
        #expect(model.duration == 0)
        #expect(model.gpsTrackData == Data())
        #expect(model.splits.isEmpty)
        #expect(model.updatedAt <= Date())
    }

    @Test("SplitSwiftDataModel has CloudKit-compatible defaults and inverse")
    func splitDefaults() {
        let model = SplitSwiftDataModel()
        #expect(model.kilometerNumber == 0)
        #expect(model.duration == 0)
        #expect(model.run == nil)
        #expect(model.updatedAt <= Date())
    }

    @Test("RaceSwiftDataModel has CloudKit-compatible defaults")
    func raceDefaults() {
        let model = RaceSwiftDataModel()
        #expect(model.name == "")
        #expect(model.distanceKm == 0)
        #expect(model.checkpointModels.isEmpty)
        #expect(model.updatedAt <= Date())
    }

    @Test("CheckpointSwiftDataModel has CloudKit-compatible defaults and inverse")
    func checkpointDefaults() {
        let model = CheckpointSwiftDataModel()
        #expect(model.name == "")
        #expect(model.race == nil)
        #expect(model.updatedAt <= Date())
    }

    @Test("TrainingPlanSwiftDataModel has CloudKit-compatible defaults")
    func trainingPlanDefaults() {
        let model = TrainingPlanSwiftDataModel()
        #expect(model.weeks.isEmpty)
        #expect(model.intermediateRaceIds.isEmpty)
        #expect(model.updatedAt <= Date())
    }

    @Test("TrainingWeekSwiftDataModel has CloudKit-compatible defaults and inverse")
    func trainingWeekDefaults() {
        let model = TrainingWeekSwiftDataModel()
        #expect(model.weekNumber == 0)
        #expect(model.sessions.isEmpty)
        #expect(model.plan == nil)
        #expect(model.updatedAt <= Date())
    }

    @Test("TrainingSessionSwiftDataModel has CloudKit-compatible defaults and inverse")
    func trainingSessionDefaults() {
        let model = TrainingSessionSwiftDataModel()
        #expect(model.typeRaw == "easy")
        #expect(model.week == nil)
        #expect(model.updatedAt <= Date())
    }

    @Test("NutritionPlanSwiftDataModel has CloudKit-compatible defaults")
    func nutritionPlanDefaults() {
        let model = NutritionPlanSwiftDataModel()
        #expect(model.caloriesPerHour == 0)
        #expect(model.entries.isEmpty)
        #expect(model.updatedAt <= Date())
    }

    @Test("NutritionEntrySwiftDataModel has CloudKit-compatible defaults and inverse")
    func nutritionEntryDefaults() {
        let model = NutritionEntrySwiftDataModel()
        #expect(model.productName == "")
        #expect(model.nutritionPlan == nil)
        #expect(model.updatedAt <= Date())
    }

    @Test("NutritionProductSwiftDataModel has CloudKit-compatible defaults")
    func nutritionProductDefaults() {
        let model = NutritionProductSwiftDataModel()
        #expect(model.name == "")
        #expect(model.typeRaw == "gel")
        #expect(model.updatedAt <= Date())
    }

    @Test("NutritionPreferencesSwiftDataModel has CloudKit-compatible defaults")
    func nutritionPreferencesDefaults() {
        let model = NutritionPreferencesSwiftDataModel()
        #expect(model.avoidCaffeine == false)
        #expect(model.updatedAt <= Date())
    }

    @Test("FitnessSnapshotSwiftDataModel has CloudKit-compatible defaults")
    func fitnessSnapshotDefaults() {
        let model = FitnessSnapshotSwiftDataModel()
        #expect(model.fitness == 0)
        #expect(model.fatigue == 0)
        #expect(model.updatedAt <= Date())
    }

    @Test("AppSettingsSwiftDataModel has CloudKit-compatible defaults")
    func appSettingsDefaults() {
        let model = AppSettingsSwiftDataModel()
        #expect(model.trainingRemindersEnabled == true)
        #expect(model.autoPauseEnabled == true)
        #expect(model.updatedAt <= Date())
    }

    @Test("All 14 models can be instantiated with no arguments")
    func allModelsInstantiateWithDefaults() {
        let models: [any PersistentModel] = [
            AthleteSwiftDataModel(),
            CompletedRunSwiftDataModel(),
            SplitSwiftDataModel(),
            RaceSwiftDataModel(),
            CheckpointSwiftDataModel(),
            TrainingPlanSwiftDataModel(),
            TrainingWeekSwiftDataModel(),
            TrainingSessionSwiftDataModel(),
            NutritionPlanSwiftDataModel(),
            NutritionEntrySwiftDataModel(),
            NutritionProductSwiftDataModel(),
            NutritionPreferencesSwiftDataModel(),
            FitnessSnapshotSwiftDataModel(),
            AppSettingsSwiftDataModel()
        ]
        #expect(models.count == 14)
    }
}
