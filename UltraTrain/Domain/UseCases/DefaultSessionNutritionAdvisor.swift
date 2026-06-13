import Foundation

struct DefaultSessionNutritionAdvisor: SessionNutritionAdvisor {

    func advise(
        for session: TrainingSession,
        athleteWeightKg: Double,
        experienceLevel: ExperienceLevel,
        preferences: NutritionPreferences
    ) -> SessionNutritionAdvice? {
        guard session.type != .rest else { return nil }

        let durationHours = session.plannedDuration / 3600
        let isLong = durationHours >= 2
        let isHard = session.intensity == .hard || session.intensity == .maxEffort

        return SessionNutritionAdvice(
            preRun: buildPreRun(session: session, isLong: isLong, isHard: isHard),
            duringRun: buildDuringRun(
                session: session,
                weightKg: athleteWeightKg,
                experience: experienceLevel,
                durationHours: durationHours,
                preferences: preferences
            ),
            postRun: buildPostRun(
                session: session,
                weightKg: athleteWeightKg,
                durationHours: durationHours,
                isHard: isHard
            ),
            isGutTrainingRecommended: isGutTrainingSession(session, durationHours: durationHours)
        )
    }

    // MARK: - Pre-Run

    private func buildPreRun(session: TrainingSession, isLong: Bool, isHard: Bool) -> PreRunAdvice {
        let timing = String(localized: "nadv.timing.2_3h", defaultValue: "2-3 hours before")

        if isLong || session.type == .longRun || session.type == .backToBack || session.type == .race {
            return PreRunAdvice(
                timingDescription: timing,
                carbsGrams: 100,
                hydrationMl: 500,
                mealSuggestions: [String(localized: "nadv.meal.oatmeal", defaultValue: "Oatmeal with banana and honey"), String(localized: "nadv.meal.riceSauce", defaultValue: "Rice with a light sauce"), String(localized: "nadv.meal.toastJamBanana", defaultValue: "Toast with jam and a banana")],
                avoidNotes: isHard ? String(localized: "nadv.avoid.fiberFat", defaultValue: "Avoid high-fiber and high-fat foods close to the session") : nil
            )
        }

        if isHard || session.type == .tempo || session.type == .intervals || session.type == .verticalGain {
            return PreRunAdvice(
                timingDescription: timing,
                carbsGrams: 60,
                hydrationMl: 500,
                mealSuggestions: [String(localized: "nadv.meal.toastHoney", defaultValue: "Toast with honey"), String(localized: "nadv.meal.bananaBar", defaultValue: "Banana with a small energy bar"), String(localized: "nadv.meal.riceCake", defaultValue: "Rice cake with jam")],
                avoidNotes: String(localized: "nadv.avoid.fiberFat", defaultValue: "Avoid high-fiber and high-fat foods close to the session")
            )
        }

        return PreRunAdvice(
            timingDescription: String(localized: "nadv.timing.1_2h", defaultValue: "1-2 hours before"),
            carbsGrams: 25,
            hydrationMl: 400,
            mealSuggestions: [String(localized: "nadv.meal.banana", defaultValue: "Banana"), String(localized: "nadv.meal.lightSnack", defaultValue: "Light snack or toast")],
            avoidNotes: nil
        )
    }

    // MARK: - During-Run

    private func buildDuringRun(
        session: TrainingSession,
        weightKg: Double,
        experience: ExperienceLevel,
        durationHours: Double,
        preferences: NutritionPreferences
    ) -> DuringRunAdvice? {
        let durationMinutes = session.plannedDuration / 60
        guard durationMinutes > 45 else { return nil }

        let factor = caloriesFactor(experience: experience, intensity: session.intensity)
        let calsPerHour = Int(weightKg * factor)
        let carbsPerHour = calsPerHour / 4
        let hydration = durationHours >= 2 ? 600 : 400

        var products: [ProductSuggestion] = []

        if !preferences.excludedProductIds.contains(DefaultProducts.gel.id) {
            products.append(ProductSuggestion(
                product: DefaultProducts.gel,
                frequencyDescription: String(localized: "nadv.freq.gel", defaultValue: "1 every 30-45 min")
            ))
        }

        if !preferences.excludedProductIds.contains(DefaultProducts.drink.id) {
            products.append(ProductSuggestion(
                product: DefaultProducts.drink,
                frequencyDescription: String(localized: "nadv.freq.drink", defaultValue: "Sip regularly")
            ))
        }

        if durationHours >= 2 && !preferences.excludedProductIds.contains(DefaultProducts.bar.id) {
            products.append(ProductSuggestion(
                product: DefaultProducts.bar,
                frequencyDescription: String(localized: "nadv.freq.bar", defaultValue: "Half every 60 min")
            ))
        }

        if durationHours >= 3 && !preferences.excludedProductIds.contains(DefaultProducts.saltCapsule.id) {
            products.append(ProductSuggestion(
                product: DefaultProducts.saltCapsule,
                frequencyDescription: String(localized: "nadv.freq.salt", defaultValue: "1 every 60 min")
            ))
        }

        if preferences.avoidCaffeine {
            products.removeAll { $0.product.caffeinated }
        }

        let notes: String? = isGutTrainingSession(session, durationHours: durationHours)
            ? String(localized: "nadv.during.gutNote", defaultValue: "Practice your race-day nutrition strategy during this session")
            : nil

        return DuringRunAdvice(
            caloriesPerHour: calsPerHour,
            hydrationMlPerHour: hydration,
            carbsGramsPerHour: carbsPerHour,
            suggestedProducts: products,
            notes: notes
        )
    }

    private func caloriesFactor(experience: ExperienceLevel, intensity: Intensity) -> Double {
        let baseFactor: Double = switch experience {
        case .beginner: 3.0
        case .intermediate: 4.0
        case .advanced: 4.8
        case .elite: 5.5
        }

        let intensityMultiplier: Double = switch intensity {
        case .easy: 0.8
        case .moderate: 1.0
        case .hard: 1.1
        case .maxEffort: 1.2
        }

        return baseFactor * intensityMultiplier
    }

    // MARK: - Post-Run

    private func buildPostRun(
        session: TrainingSession,
        weightKg: Double,
        durationHours: Double,
        isHard: Bool
    ) -> PostRunAdvice {
        let priority = recoveryPriority(session: session, durationHours: durationHours, isHard: isHard)

        switch priority {
        case .high:
            return PostRunAdvice(
                priority: .high,
                windowDescription: String(localized: "nadv.window.30", defaultValue: "Within 30 minutes"),
                proteinGrams: Int(0.5 * weightKg).clamped(to: 30...40),
                carbsGrams: Int(1.2 * weightKg),
                hydrationMl: 750,
                mealSuggestions: [
                    String(localized: "nadv.meal.recoveryShake", defaultValue: "Recovery shake with protein and banana"),
                    String(localized: "nadv.meal.chickenRice", defaultValue: "Chicken breast with rice and vegetables"),
                    String(localized: "nadv.meal.greekYogurt", defaultValue: "Greek yogurt with granola and berries")
                ]
            )
        case .moderate:
            return PostRunAdvice(
                priority: .moderate,
                windowDescription: String(localized: "nadv.window.60", defaultValue: "Within 60 minutes"),
                proteinGrams: Int(0.35 * weightKg).clamped(to: 20...30),
                carbsGrams: Int(0.8 * weightKg),
                hydrationMl: 500,
                mealSuggestions: [
                    String(localized: "nadv.meal.smoothie", defaultValue: "Smoothie with protein powder and fruit"),
                    String(localized: "nadv.meal.eggsToast", defaultValue: "Eggs on toast"),
                    String(localized: "nadv.meal.turkey", defaultValue: "Turkey sandwich")
                ]
            )
        case .low:
            return PostRunAdvice(
                priority: .low,
                windowDescription: String(localized: "nadv.window.normal", defaultValue: "Normal meal timing"),
                proteinGrams: 20,
                carbsGrams: Int(0.5 * weightKg),
                hydrationMl: 500,
                mealSuggestions: [
                    String(localized: "nadv.meal.balanced", defaultValue: "Balanced meal at your usual time"),
                    String(localized: "nadv.meal.fruitNuts", defaultValue: "Fruit and a handful of nuts")
                ]
            )
        }
    }

    private func recoveryPriority(session: TrainingSession, durationHours: Double, isHard: Bool) -> RecoveryPriority {
        if session.type == .longRun || session.type == .backToBack || session.type == .race || isHard || durationHours >= 2 {
            return .high
        }
        if session.type == .tempo || session.type == .intervals || session.type == .verticalGain {
            return .moderate
        }
        return .low
    }

    // MARK: - Gut Training

    private func isGutTrainingSession(_ session: TrainingSession, durationHours: Double) -> Bool {
        (session.type == .longRun || session.type == .backToBack || session.type == .race) && durationHours >= 2
    }
}

// MARK: - Int Clamping

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
