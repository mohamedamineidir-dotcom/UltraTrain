import Foundation
import Testing
@testable import UltraTrain

@Suite("Nutrition Plan Generator Tests")
struct NutritionPlanGeneratorTests {

    private func makeAthlete(
        weightKg: Double = 70,
        experience: ExperienceLevel = .intermediate
    ) -> Athlete {
        Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: weightKg,
            heightCm: 175,
            restingHeartRate: 55,
            maxHeartRate: 185,
            experienceLevel: experience,
            weeklyVolumeKm: 40,
            longestRunKm: 25,
            preferredUnit: .metric
        )
    }

    private func makeRace(
        distanceKm: Double = 100,
        elevationGainM: Double = 5000
    ) -> Race {
        Race(
            id: UUID(),
            name: "Test Ultra",
            date: Date.now.adding(weeks: 16),
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: elevationGainM,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
        )
    }

    // MARK: - Carb target (g/hr)

    @Test("Carbs/hr scales with duration — marathon > half")
    func carbsScaleWithDuration() {
        let half = NutritionTargets.carbsGramsPerHour(
            durationHours: 1.5, experience: .intermediate, goal: .targetTime,
            bodyWeightKg: 70, toleranceCeiling: nil
        )
        let marathon = NutritionTargets.carbsGramsPerHour(
            durationHours: 3.5, experience: .intermediate, goal: .targetTime,
            bodyWeightKg: 70, toleranceCeiling: nil
        )
        #expect(marathon > half)
    }

    @Test("Carbs/hr respects gut-training tolerance ceiling")
    func carbsRespectTolerance() {
        let uncapped = NutritionTargets.carbsGramsPerHour(
            durationHours: 4, experience: .advanced, goal: .competitive,
            bodyWeightKg: 70, toleranceCeiling: nil
        )
        let capped = NutritionTargets.carbsGramsPerHour(
            durationHours: 4, experience: .advanced, goal: .competitive,
            bodyWeightKg: 70, toleranceCeiling: 60
        )
        #expect(capped <= 60)
        #expect(capped < uncapped)
    }

    @Test("Competitive goal exceeds finish goal at same inputs")
    func goalAffectsCarbs() {
        let finish = NutritionTargets.carbsGramsPerHour(
            durationHours: 3.5, experience: .intermediate, goal: .finishComfortably,
            bodyWeightKg: 70, toleranceCeiling: nil
        )
        let competitive = NutritionTargets.carbsGramsPerHour(
            durationHours: 3.5, experience: .intermediate, goal: .competitive,
            bodyWeightKg: 70, toleranceCeiling: nil
        )
        #expect(competitive > finish)
    }

    @Test("Carbs hard-capped at 120 g/hr absolute")
    func carbsAbsoluteCap() {
        let elite = NutritionTargets.carbsGramsPerHour(
            durationHours: 24, experience: .elite, goal: .competitive,
            bodyWeightKg: 90, toleranceCeiling: nil
        )
        #expect(elite <= 120)
    }

    // MARK: - Hydration (ml/hr) — sweat-profile driven

    @Test("Measured sweat rate drives hydration target (80% replacement)")
    func hydrationFromSweatRate() {
        var profile = SweatProfile.unknown
        profile.sweatRateMlPerHour = 1000
        let ml = NutritionTargets.hydrationMlPerHour(sweatProfile: profile, bodyWeightKg: 70, weather: nil)
        #expect(ml == 800) // 80% of 1000
    }

    @Test("Hydration falls back to weight-adjusted baseline when sweat rate unknown")
    func hydrationFallback() {
        let smallAthlete = NutritionTargets.hydrationMlPerHour(
            sweatProfile: .unknown, bodyWeightKg: 55, weather: nil
        )
        let largeAthlete = NutritionTargets.hydrationMlPerHour(
            sweatProfile: .unknown, bodyWeightKg: 90, weather: nil
        )
        #expect(largeAthlete > smallAthlete)
    }

    // MARK: - Sodium (mg/hr)

    @Test("Sodium uses sweat sodium concentration when known")
    func sodiumFromSweatComposition() {
        var profile = SweatProfile.unknown
        profile.sweatSodiumMgPerL = 1200
        let mg = NutritionTargets.sodiumMgPerHour(
            sweatProfile: profile, hydrationMlPerHour: 800, durationHours: 3, weather: nil
        )
        // 800 ml × 1200 mg/L = 960 mg/hr, rounded to nearest 25 = 950.
        #expect(mg == 950)
    }

    @Test("Heavy salty sweater gets elevated sodium")
    func sodiumHeavySaltySweater() {
        var profile = SweatProfile.unknown
        profile.heavySaltySweater = true
        let heavy = NutritionTargets.sodiumMgPerHour(
            sweatProfile: profile, hydrationMlPerHour: 600, durationHours: 4, weather: nil
        )
        let normal = NutritionTargets.sodiumMgPerHour(
            sweatProfile: .unknown, hydrationMlPerHour: 600, durationHours: 4, weather: nil
        )
        #expect(heavy > normal)
    }

    @Test("ISSN ultra floor of 575 mg/L applies for races >6h")
    func sodiumIssnFloor() {
        // Set an unrealistically low sodium concentration; expect floor to apply.
        var profile = SweatProfile.unknown
        profile.sweatSodiumMgPerL = 200
        let mgOver6h = NutritionTargets.sodiumMgPerHour(
            sweatProfile: profile, hydrationMlPerHour: 600, durationHours: 8, weather: nil
        )
        // 600 ml × 575 mg/L (floor) = 345 mg/hr, minimum clamped to 200
        #expect(mgOver6h >= 345)
    }

    // MARK: - Caffeine (total mg)

    @Test("Caffeine is 0 when avoidCaffeine is true")
    func caffeineZeroWhenAvoided() {
        var prefs = NutritionPreferences.default
        prefs.avoidCaffeine = true
        let mg = NutritionTargets.caffeineTotalMg(for: prefs, bodyWeightKg: 70)
        #expect(mg == 0)
    }

    @Test("Caffeine scales with sensitivity")
    func caffeineScalesWithSensitivity() {
        var low = NutritionPreferences.default
        low.caffeineSensitivity = .low
        var high = NutritionPreferences.default
        high.caffeineSensitivity = .high
        let lowMg = NutritionTargets.caffeineTotalMg(for: low, bodyWeightKg: 70)
        let highMg = NutritionTargets.caffeineTotalMg(for: high, bodyWeightKg: 70)
        #expect(highMg > lowMg)
    }

    // MARK: - Schedule Structure

    @Test("Generated plan has entries for race duration")
    func planHasEntries() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(distanceKm: 100)

        let plan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 15 * 3600, preferences: .default)

        #expect(!plan.entries.isEmpty)
        #expect(plan.raceId == race.id)
    }

    @Test("Entries start after 20 minutes")
    func entriesStartAfter20Min() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace()

        let plan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 10 * 3600, preferences: .default)

        let firstTiming = plan.entries.min(by: { $0.timingMinutes < $1.timingMinutes })?.timingMinutes ?? 0
        #expect(firstTiming >= 20)
    }

    @Test("Caffeine entries appear in the back half of ultra races")
    func caffeineBackLoadedForUltras() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace()

        let plan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 12 * 3600, preferences: .default)

        let caffeineEntries = plan.entries.filter { $0.product.caffeinated }
        #expect(!caffeineEntries.isEmpty)
        // Ultra schedule back-loads caffeine from hour 3 onward.
        for entry in caffeineEntries {
            #expect(entry.timingMinutes >= 180)
        }
    }

    @Test("Salt capsules included for ultra races")
    func saltCapsulesForUltra() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(distanceKm: 80)

        let plan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 12 * 3600, preferences: .default)

        let saltEntries = plan.entries.filter { $0.product.type == .salt }
        #expect(!saltEntries.isEmpty)
    }

    @Test("No salt capsules for non-ultra races")
    func noSaltForShortRaces() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(distanceKm: 42)

        let plan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 4 * 3600, preferences: .default)

        let saltEntries = plan.entries.filter { $0.product.type == .salt }
        #expect(saltEntries.isEmpty)
    }

    @Test("Solid food included for long ultras")
    func solidFoodForLongUltras() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(distanceKm: 160)

        let plan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 24 * 3600, preferences: .default)

        let solidEntries = plan.entries.filter { $0.product.type == .bar || $0.product.type == .realFood }
        #expect(!solidEntries.isEmpty)
    }

    @Test("Gut training session IDs start empty")
    func gutTrainingIdsEmpty() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace()

        let plan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 10 * 3600, preferences: .default)

        #expect(plan.gutTrainingSessionIds.isEmpty)
    }

    @Test("Very short race returns minimal hydration-only plan")
    func veryShortRaceReturnsMinimalPlan() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(distanceKm: 5)

        let plan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 25 * 60, preferences: .default)
        #expect(plan.entries.isEmpty, "Sub-30min race needs no in-race nutrition")
        #expect(plan.hydrationMlPerHour == 400)
        #expect(plan.caloriesPerHour == 0)
    }

    @Test("Short race under 90 min gets simplified schedule")
    func shortRaceSimplifiedSchedule() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(distanceKm: 21.1) // half marathon

        let plan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 80 * 60, preferences: .default)
        // Short race: gels + electrolyte drink, no salt capsules, no real food
        let saltEntries = plan.entries.filter { $0.product.type == .salt }
        let solidEntries = plan.entries.filter { $0.product.type == .bar || $0.product.type == .realFood }
        #expect(saltEntries.isEmpty, "No salt capsules for short races")
        #expect(solidEntries.isEmpty, "No solid food for short races")
        #expect(!plan.entries.isEmpty, "Should still have gel/drink entries")
    }

    @Test("Entries are sorted by timing")
    func entriesSortedByTiming() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace()

        let plan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 10 * 3600, preferences: .default)

        for i in 1..<plan.entries.count {
            #expect(plan.entries[i].timingMinutes >= plan.entries[i - 1].timingMinutes)
        }
    }

    @Test("Drink entries appear every hour")
    func drinkEntriesEveryHour() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace()

        let plan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 8 * 3600, preferences: .default)

        let drinkEntries = plan.entries.filter { $0.product.type == .drink }
        #expect(drinkEntries.count >= 6)
    }

    // MARK: - Preferences

    @Test("Avoid caffeine removes caffeinated entries from plan")
    func avoidCaffeineRemovesCaffeinatedEntries() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace()
        let prefs = NutritionPreferences(avoidCaffeine: true, preferRealFood: false, excludedProductIds: [])

        let plan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 12 * 3600, preferences: prefs)

        let caffeinated = plan.entries.filter { $0.product.caffeinated }
        #expect(caffeinated.isEmpty)
    }

    @Test("Prefer real food adds more real food entries for long ultra")
    func preferRealFoodAddsMoreEntries() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(distanceKm: 160)
        let defaultPrefs = NutritionPreferences.default
        let realFoodPrefs = NutritionPreferences(avoidCaffeine: false, preferRealFood: true, excludedProductIds: [])

        let defaultPlan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 24 * 3600, preferences: defaultPrefs)
        let realFoodPlan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 24 * 3600, preferences: realFoodPrefs)

        let defaultSolid = defaultPlan.entries.filter { $0.product.type == .bar || $0.product.type == .realFood }
        let realFoodSolid = realFoodPlan.entries.filter { $0.product.type == .bar || $0.product.type == .realFood }
        #expect(realFoodSolid.count >= defaultSolid.count)
    }

    @Test("Excluded product is omitted from generated plan")
    func excludedProductOmittedFromPlan() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace()
        let gelId = DefaultProducts.gel.id
        let prefs = NutritionPreferences(avoidCaffeine: false, preferRealFood: false, excludedProductIds: [gelId])

        let plan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 10 * 3600, preferences: prefs)

        let hasExcludedGel = plan.entries.contains { $0.product.id == gelId }
        #expect(!hasExcludedGel)
    }

    @Test("Default preferences produce same plan structure as before")
    func defaultPreferencesBackwardsCompat() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace()

        let plan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 10 * 3600, preferences: .default)

        #expect(!plan.entries.isEmpty)
        #expect(plan.entries.contains { $0.product.type == .gel })
        #expect(plan.entries.contains { $0.product.type == .drink })
    }

    // MARK: - Weather Adjustments

    @Test("Hot weather increases hydration in generated plan")
    func hotWeatherIncreasesHydration() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace()
        let duration: TimeInterval = 10 * 3600

        let normalPlan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: duration, preferences: .default)
        let weatherAdj = WeatherImpactCalculator.NutritionWeatherAdjustment(
            hydrationMultiplier: 1.5, sodiumMultiplier: 1.3, caloriesMultiplier: 1.0,
            notes: ["Increase fluid intake"]
        )
        let weatherPlan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: duration, preferences: .default, weatherAdjustment: weatherAdj)

        #expect(weatherPlan.hydrationMlPerHour > normalPlan.hydrationMlPerHour)
        #expect(weatherPlan.sodiumMgPerHour > normalPlan.sodiumMgPerHour)
    }

    @Test("Cold weather increases calories in generated plan")
    func coldWeatherIncreasesCalories() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace()
        let duration: TimeInterval = 10 * 3600

        let normalPlan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: duration, preferences: .default)
        let weatherAdj = WeatherImpactCalculator.NutritionWeatherAdjustment(
            hydrationMultiplier: 1.0, sodiumMultiplier: 1.0, caloriesMultiplier: 1.1,
            notes: ["Increase calorie intake"]
        )
        let weatherPlan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: duration, preferences: .default, weatherAdjustment: weatherAdj)

        #expect(weatherPlan.caloriesPerHour > normalPlan.caloriesPerHour)
    }

    @Test("Multiple excluded products still produce valid plan")
    func multipleExclusionsProduceValidPlan() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace()
        let prefs = NutritionPreferences(
            avoidCaffeine: false,
            preferRealFood: false,
            excludedProductIds: [DefaultProducts.gel.id, DefaultProducts.bar.id, DefaultProducts.saltCapsule.id]
        )

        let plan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 10 * 3600, preferences: prefs)

        #expect(!plan.entries.isEmpty)
        let hasExcluded = plan.entries.contains {
            $0.product.id == DefaultProducts.gel.id
            || $0.product.id == DefaultProducts.bar.id
            || $0.product.id == DefaultProducts.saltCapsule.id
        }
        #expect(!hasExcluded)
    }
}
