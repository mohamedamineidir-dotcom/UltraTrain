import Foundation

struct DefaultSessionNutritionAdvisor: SessionNutritionAdvisor {

    func advise(
        for session: TrainingSession,
        athleteWeightKg: Double,
        experienceLevel: ExperienceLevel
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
                durationHours: durationHours
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
        let timing = "2-3 hours before"

        if isLong || session.type == .longRun || session.type == .backToBack {
            return PreRunAdvice(
                timingDescription: timing,
                carbsGrams: 100,
                hydrationMl: 500,
                mealSuggestions: ["Oatmeal with banana and honey", "Rice with a light sauce", "Toast with jam and a banana"],
                avoidNotes: isHard ? "Avoid high-fiber and high-fat foods close to the session" : nil
            )
        }

        if isHard || session.type == .tempo || session.type == .intervals || session.type == .verticalGain {
            return PreRunAdvice(
                timingDescription: timing,
                carbsGrams: 60,
                hydrationMl: 500,
                mealSuggestions: ["Toast with honey", "Banana with a small energy bar", "Rice cake with jam"],
                avoidNotes: "Avoid high-fiber and high-fat foods close to the session"
            )
        }

        return PreRunAdvice(
            timingDescription: "1-2 hours before",
            carbsGrams: 25,
            hydrationMl: 400,
            mealSuggestions: ["Banana", "Light snack or toast"],
            avoidNotes: nil
        )
    }

    // MARK: - During-Run

    private func buildDuringRun(
        session: TrainingSession,
        weightKg: Double,
        experience: ExperienceLevel,
        durationHours: Double
    ) -> DuringRunAdvice? {
        let durationMinutes = session.plannedDuration / 60
        guard durationMinutes > 45 else { return nil }

        let factor = caloriesFactor(experience: experience, intensity: session.intensity)
        let calsPerHour = Int(weightKg * factor)
        let carbsPerHour = calsPerHour / 4
        let hydration = durationHours >= 2 ? 600 : 400

        var products: [ProductSuggestion] = [
            ProductSuggestion(product: DefaultProducts.gel, frequencyDescription: "1 every 30-45 min"),
            ProductSuggestion(product: DefaultProducts.drink, frequencyDescription: "Sip regularly")
        ]

        if durationHours >= 2 {
            products.append(ProductSuggestion(product: DefaultProducts.bar, frequencyDescription: "Half every 60 min"))
        }

        if durationHours >= 3 {
            products.append(ProductSuggestion(product: DefaultProducts.saltCapsule, frequencyDescription: "1 every 60 min"))
        }

        let notes: String? = isGutTrainingSession(session, durationHours: durationHours)
            ? "Practice your race-day nutrition strategy during this session"
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
                windowDescription: "Within 30 minutes",
                proteinGrams: Int(0.5 * weightKg).clamped(to: 30...40),
                carbsGrams: Int(1.2 * weightKg),
                hydrationMl: 750,
                mealSuggestions: [
                    "Recovery shake with protein and banana",
                    "Chicken breast with rice and vegetables",
                    "Greek yogurt with granola and berries"
                ]
            )
        case .moderate:
            return PostRunAdvice(
                priority: .moderate,
                windowDescription: "Within 60 minutes",
                proteinGrams: Int(0.35 * weightKg).clamped(to: 20...30),
                carbsGrams: Int(0.8 * weightKg),
                hydrationMl: 500,
                mealSuggestions: [
                    "Smoothie with protein powder and fruit",
                    "Eggs on toast",
                    "Turkey sandwich"
                ]
            )
        case .low:
            return PostRunAdvice(
                priority: .low,
                windowDescription: "Normal meal timing",
                proteinGrams: 20,
                carbsGrams: Int(0.5 * weightKg),
                hydrationMl: 500,
                mealSuggestions: [
                    "Balanced meal at your usual time",
                    "Fruit and a handful of nuts"
                ]
            )
        }
    }

    private func recoveryPriority(session: TrainingSession, durationHours: Double, isHard: Bool) -> RecoveryPriority {
        if session.type == .longRun || session.type == .backToBack || isHard || durationHours >= 2 {
            return .high
        }
        if session.type == .tempo || session.type == .intervals || session.type == .verticalGain {
            return .moderate
        }
        return .low
    }

    // MARK: - Gut Training

    private func isGutTrainingSession(_ session: TrainingSession, durationHours: Double) -> Bool {
        (session.type == .longRun || session.type == .backToBack) && durationHours >= 2
    }
}

// MARK: - Int Clamping

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
