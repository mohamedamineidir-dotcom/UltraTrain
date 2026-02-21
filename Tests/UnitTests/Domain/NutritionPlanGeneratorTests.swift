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

    // MARK: - Calorie Calculations

    @Test("Calories scale with athlete weight")
    func caloriesScaleWithWeight() {
        let generator = NutritionPlanGenerator()
        let light = generator.calculateCaloriesPerHour(weightKg: 55, experience: .intermediate)
        let heavy = generator.calculateCaloriesPerHour(weightKg: 85, experience: .intermediate)
        #expect(heavy > light)
    }

    @Test("Calories increase with experience level")
    func caloriesIncreaseWithExperience() {
        let generator = NutritionPlanGenerator()
        let beginner = generator.calculateCaloriesPerHour(weightKg: 70, experience: .beginner)
        let elite = generator.calculateCaloriesPerHour(weightKg: 70, experience: .elite)
        #expect(elite > beginner)
    }

    @Test("Calories are within expected range for 70kg intermediate")
    func caloriesInRange() {
        let generator = NutritionPlanGenerator()
        let cal = generator.calculateCaloriesPerHour(weightKg: 70, experience: .intermediate)
        #expect(cal >= 280)
        #expect(cal <= 350)
    }

    // MARK: - Hydration

    @Test("Hydration increases with race duration")
    func hydrationScalesWithDuration() {
        let generator = NutritionPlanGenerator()
        let short = generator.calculateHydrationPerHour(durationMinutes: 120)
        let long = generator.calculateHydrationPerHour(durationMinutes: 720)
        #expect(long > short)
    }

    @Test("Hydration stays within configured bounds")
    func hydrationInBounds() {
        let generator = NutritionPlanGenerator()
        let hydration = generator.calculateHydrationPerHour(durationMinutes: 600)
        #expect(hydration >= AppConfiguration.Nutrition.hydrationMlPerHourLow)
        #expect(hydration <= AppConfiguration.Nutrition.hydrationMlPerHourHigh)
    }

    // MARK: - Sodium

    @Test("Sodium is higher for 100km+ races")
    func sodiumHigherForLongRaces() {
        let generator = NutritionPlanGenerator()
        let short = generator.calculateSodiumPerHour(distanceKm: 50)
        let long = generator.calculateSodiumPerHour(distanceKm: 160)
        #expect(long > short)
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

    @Test("Caffeine entries appear after 4 hours")
    func caffeineAfter4Hours() async throws {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace()

        let plan = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 12 * 3600, preferences: .default)

        let caffeineEntries = plan.entries.filter { $0.product.caffeinated }
        #expect(!caffeineEntries.isEmpty)
        for entry in caffeineEntries {
            #expect(entry.timingMinutes >= 240)
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

    @Test("Throws for race under 1 hour")
    func throwsForShortRace() async {
        let generator = NutritionPlanGenerator()
        let athlete = makeAthlete()
        let race = makeRace(distanceKm: 5)

        do {
            _ = try await generator.execute(athlete: athlete, race: race, estimatedDuration: 30 * 60, preferences: .default)
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is DomainError)
        }
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
