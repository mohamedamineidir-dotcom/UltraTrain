import Foundation

struct NutritionPlanGenerator: GenerateNutritionPlanUseCase {

    func execute(
        athlete: Athlete,
        race: Race,
        estimatedDuration: TimeInterval,
        preferences: NutritionPreferences
    ) async throws -> NutritionPlan {
        let durationMinutes = Int(estimatedDuration / 60)

        guard durationMinutes >= 60 else {
            throw DomainError.invalidTrainingPlan(
                reason: "Race duration must be at least 1 hour for a nutrition plan."
            )
        }

        let caloriesPerHour = calculateCaloriesPerHour(
            weightKg: athlete.weightKg,
            experience: athlete.experienceLevel
        )
        let hydrationMlPerHour = calculateHydrationPerHour(durationMinutes: durationMinutes)
        let sodiumMgPerHour = calculateSodiumPerHour(distanceKm: race.distanceKm)

        let isUltra = race.distanceKm > 50
        let isLongUltra = estimatedDuration > 6 * 3600

        let entries = buildSchedule(
            durationMinutes: durationMinutes,
            isUltra: isUltra,
            isLongUltra: isLongUltra,
            preferences: preferences
        )

        return NutritionPlan(
            id: UUID(),
            raceId: race.id,
            caloriesPerHour: caloriesPerHour,
            hydrationMlPerHour: hydrationMlPerHour,
            sodiumMgPerHour: sodiumMgPerHour,
            entries: entries,
            gutTrainingSessionIds: []
        )
    }

    // MARK: - Hourly Target Calculations

    func calculateCaloriesPerHour(weightKg: Double, experience: ExperienceLevel) -> Int {
        let factor: Double = switch experience {
        case .beginner:     AppConfiguration.Nutrition.caloriesPerKgPerHourLow
        case .intermediate: AppConfiguration.Nutrition.caloriesPerKgPerHourLow + 0.5
        case .advanced:     AppConfiguration.Nutrition.caloriesPerKgPerHourHigh - 0.5
        case .elite:        AppConfiguration.Nutrition.caloriesPerKgPerHourHigh
        }
        return Int(weightKg * factor)
    }

    func calculateHydrationPerHour(durationMinutes: Int) -> Int {
        let low = AppConfiguration.Nutrition.hydrationMlPerHourLow
        let high = AppConfiguration.Nutrition.hydrationMlPerHourHigh
        let fraction = min(1.0, Double(durationMinutes - 60) / Double(12 * 60 - 60))
        return low + Int(fraction * Double(high - low))
    }

    func calculateSodiumPerHour(distanceKm: Double) -> Int {
        distanceKm > 100 ? 800 : AppConfiguration.Nutrition.sodiumMgPerHour
    }

    // MARK: - Schedule Builder

    func buildSchedule(
        durationMinutes: Int,
        isUltra: Bool,
        isLongUltra: Bool,
        preferences: NutritionPreferences
    ) -> [NutritionEntry] {
        var entries: [NutritionEntry] = []
        let intervalMinutes = 20
        let startMinute = intervalMinutes
        let endMinute = durationMinutes - 20

        guard endMinute > startMinute else {
            if let gel = resolve(DefaultProducts.gel, preferences: preferences) {
                entries.append(makeEntry(product: gel, timingMinutes: 30, notes: "Take with water"))
            }
            return entries
        }

        let realFoodInterval = preferences.preferRealFood && isLongUltra ? 40 : 60
        var gelChewToggle = false

        for minute in stride(from: startMinute, through: endMinute, by: intervalMinutes) {
            let useCaffeine = minute >= 240 && !preferences.avoidCaffeine

            // Primary calorie source: gel or chew every 20 min
            let desired: NutritionProduct
            if gelChewToggle {
                desired = useCaffeine ? DefaultProducts.caffeineChew : DefaultProducts.chew
            } else {
                desired = useCaffeine ? DefaultProducts.caffeineGel : DefaultProducts.gel
            }
            gelChewToggle.toggle()

            if let product = resolve(desired, preferences: preferences) {
                let notes = product.caffeinated ? "Caffeinated — take with water" : "Take with water"
                entries.append(makeEntry(product: product, timingMinutes: minute, notes: notes))
            }

            // Solid food for long ultras
            if isLongUltra && minute % realFoodInterval == 0 && minute > 0 {
                let solidProduct = minute % 120 == 0 ? DefaultProducts.bar : DefaultProducts.realFood
                if let resolved = resolve(solidProduct, preferences: preferences) {
                    entries.append(makeEntry(
                        product: resolved,
                        timingMinutes: minute,
                        notes: "Eat at aid station if possible"
                    ))
                }
            }

            // Electrolyte drink every 60 min
            if minute % 60 == 0 {
                if let drink = resolve(DefaultProducts.drink, preferences: preferences) {
                    entries.append(makeEntry(
                        product: drink,
                        timingMinutes: minute,
                        notes: "Mix with 500ml water"
                    ))
                }
            }

            // Salt capsule every 60 min for ultras
            if isUltra && minute % 60 == 0 {
                if let salt = resolve(DefaultProducts.saltCapsule, preferences: preferences) {
                    entries.append(makeEntry(
                        product: salt,
                        timingMinutes: minute,
                        notes: "Take with water"
                    ))
                }
            }
        }

        entries.sort { $0.timingMinutes < $1.timingMinutes }
        return entries
    }

    private func resolve(
        _ product: NutritionProduct,
        preferences: NutritionPreferences
    ) -> NutritionProduct? {
        if preferences.avoidCaffeine && product.caffeinated {
            return fallbackNonCaffeinated(for: product)
        }
        if preferences.excludedProductIds.contains(product.id) {
            return fallbackSameType(for: product, preferences: preferences)
        }
        return product
    }

    private func fallbackNonCaffeinated(for product: NutritionProduct) -> NutritionProduct? {
        DefaultProducts.all.first { $0.type == product.type && !$0.caffeinated }
    }

    private func fallbackSameType(
        for product: NutritionProduct,
        preferences: NutritionPreferences
    ) -> NutritionProduct? {
        DefaultProducts.all.first {
            $0.type == product.type
            && $0.id != product.id
            && !preferences.excludedProductIds.contains($0.id)
            && (!preferences.avoidCaffeine || !$0.caffeinated)
        }
    }

    private func makeEntry(
        product: NutritionProduct,
        timingMinutes: Int,
        notes: String?
    ) -> NutritionEntry {
        NutritionEntry(
            id: UUID(),
            product: product,
            timingMinutes: timingMinutes,
            quantity: 1,
            notes: notes
        )
    }
}
