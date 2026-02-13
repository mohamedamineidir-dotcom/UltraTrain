import Foundation

struct NutritionPlanGenerator: GenerateNutritionPlanUseCase {

    func execute(
        athlete: Athlete,
        race: Race,
        estimatedDuration: TimeInterval
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
            isLongUltra: isLongUltra
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
        isLongUltra: Bool
    ) -> [NutritionEntry] {
        var entries: [NutritionEntry] = []
        let intervalMinutes = 20
        let startMinute = intervalMinutes
        let endMinute = durationMinutes - 20

        guard endMinute > startMinute else {
            entries.append(makeEntry(
                product: DefaultProducts.gel,
                timingMinutes: 30,
                notes: "Take with water"
            ))
            return entries
        }

        var gelChewToggle = false

        for minute in stride(from: startMinute, through: endMinute, by: intervalMinutes) {
            let useCaffeine = minute >= 240

            // Primary calorie source: gel or chew every 20 min
            let product: NutritionProduct
            if gelChewToggle {
                product = useCaffeine ? DefaultProducts.caffeineChew : DefaultProducts.chew
            } else {
                product = useCaffeine ? DefaultProducts.caffeineGel : DefaultProducts.gel
            }
            gelChewToggle.toggle()

            let notes = useCaffeine ? "Caffeinated — take with water" : "Take with water"
            entries.append(makeEntry(product: product, timingMinutes: minute, notes: notes))

            // Every 60 min: solid food for long ultras
            if isLongUltra && minute % 60 == 0 && minute > 0 {
                let solidProduct = minute % 120 == 0 ? DefaultProducts.bar : DefaultProducts.realFood
                entries.append(makeEntry(
                    product: solidProduct,
                    timingMinutes: minute,
                    notes: "Eat at aid station if possible"
                ))
            }

            // Electrolyte drink every 60 min
            if minute % 60 == 0 {
                entries.append(makeEntry(
                    product: DefaultProducts.drink,
                    timingMinutes: minute,
                    notes: "Mix with 500ml water"
                ))
            }

            // Salt capsule every 60 min for ultras
            if isUltra && minute % 60 == 0 {
                entries.append(makeEntry(
                    product: DefaultProducts.saltCapsule,
                    timingMinutes: minute,
                    notes: "Take with water"
                ))
            }
        }

        entries.sort { $0.timingMinutes < $1.timingMinutes }
        return entries
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
