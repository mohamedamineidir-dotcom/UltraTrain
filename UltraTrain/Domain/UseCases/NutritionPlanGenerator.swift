import Foundation

/// Generates an evidence-based race-day nutrition plan.
///
/// ## Philosophy
/// Carbs-per-hour is the modern target (Jeukendrup, ISSN position stand,
/// Stellingwerff lab work). Targets scale by **expected duration** not distance,
/// modified by goal (finish / target / competitive), body weight, experience,
/// and gut-trained tolerance ceiling. Hydration and sodium come from the
/// athlete's sweat profile when known, or a temp+humidity+weight heuristic.
///
/// ## Scope
/// Covers 5K through 100-mile. Prescribes in-race fueling only. Pre-race
/// carb-loading guidance and race-morning meal are computed by the
/// generator and exposed via `CarbLoadingPlan` (consumed by the UI).
struct NutritionPlanGenerator: GenerateNutritionPlanUseCase {

    func execute(
        athlete: Athlete,
        race: Race,
        estimatedDuration: TimeInterval,
        preferences: NutritionPreferences,
        weatherAdjustment: WeatherImpactCalculator.NutritionWeatherAdjustment?
    ) async throws -> NutritionPlan {

        let durationHours = estimatedDuration / 3600
        let durationMinutes = Int(estimatedDuration / 60)

        // Very short races (<30 min): no fueling, maybe a mouth rinse.
        guard durationMinutes >= 30 else {
            return NutritionPlan(
                id: UUID(),
                raceId: race.id,
                carbsPerHour: 0,
                caloriesPerHour: 0,
                hydrationMlPerHour: 400,
                sodiumMgPerHour: 0,
                totalCaffeineMg: NutritionTargets.caffeineTotalMg(for: preferences, bodyWeightKg: athlete.weightKg),
                entries: [],
                gutTrainingSessionIds: []
            )
        }

        // 1. Compute targets (per hour)
        let carbsPerHour = NutritionTargets.carbsGramsPerHour(
            durationHours: durationHours,
            experience: athlete.experienceLevel,
            goal: preferences.nutritionGoal,
            bodyWeightKg: athlete.weightKg,
            toleranceCeiling: preferences.carbsPerHourTolerance
        )

        let hydrationMlPerHour = NutritionTargets.hydrationMlPerHour(
            sweatProfile: preferences.sweatProfile,
            bodyWeightKg: athlete.weightKg,
            weather: weatherAdjustment
        )

        let sodiumMgPerHour = NutritionTargets.sodiumMgPerHour(
            sweatProfile: preferences.sweatProfile,
            hydrationMlPerHour: hydrationMlPerHour,
            durationHours: durationHours,
            weather: weatherAdjustment
        )

        let totalCaffeineMg = NutritionTargets.caffeineTotalMg(
            for: preferences,
            bodyWeightKg: athlete.weightKg
        )

        // 2. Apply the weather calorie multiplier to final kcal/hr only
        //    (hydration/sodium already personalized).
        let caloriesFromCarbs = carbsPerHour * 4
        let proteinKcal = durationHours > 6 ? 30 : 0  // ultras: ~7-8 g/hr protein
        let fatKcal = durationHours > 8 ? 50 : 0       // 100-mile: ~5-6 g/hr fat
        let rawCalories = caloriesFromCarbs + proteinKcal + fatKcal
        let caloriesPerHour = Int(Double(rawCalories) * (weatherAdjustment?.caloriesMultiplier ?? 1.0))

        // 3. Build the in-race schedule
        let entries = NutritionScheduleBuilder.build(
            durationMinutes: durationMinutes,
            carbsTargetGramsPerHour: carbsPerHour,
            hydrationMlPerHour: hydrationMlPerHour,
            sodiumMgPerHour: sodiumMgPerHour,
            totalCaffeineMg: totalCaffeineMg,
            preferences: preferences
        )

        return NutritionPlan(
            id: UUID(),
            raceId: race.id,
            carbsPerHour: carbsPerHour,
            caloriesPerHour: caloriesPerHour,
            hydrationMlPerHour: hydrationMlPerHour,
            sodiumMgPerHour: sodiumMgPerHour,
            totalCaffeineMg: totalCaffeineMg,
            entries: entries,
            gutTrainingSessionIds: []
        )
    }
}

// MARK: - Numeric Targets

/// Evidence-based numeric targets. Research: Jeukendrup 2014 (g/hr tiers),
/// Burke IOC 2011 (loading), ISSN 2019 (ultra), Stellingwerff 2020 (120 g/hr),
/// Precision F&H (sweat composition), ISSN caffeine 2021.
enum NutritionTargets {

    // MARK: Carbs g/hr

    static func carbsGramsPerHour(
        durationHours: Double,
        experience: ExperienceLevel,
        goal: NutritionGoal,
        bodyWeightKg: Double,
        toleranceCeiling: Int?
    ) -> Int {
        // Duration-based base (Jeukendrup tiered)
        let base: Double
        switch durationHours {
        case ..<0.5:  base = 0
        case ..<1.0:  base = experience == .elite ? 30 : 0
        case ..<2.5:
            // 30 g/hr at 1h → 75 g/hr at 2.5h
            base = 30 + (durationHours - 1) * 30
        case ..<4:
            // 60 g/hr for beginners → 90 g/hr for elites
            base = 60 + Double(experience.rawSortOrder) * 7.5
        default:
            // Ultra/long: 70 g/hr finish-level → 100 g/hr elite-level
            base = 70 + Double(experience.rawSortOrder) * 7.5
        }

        // Goal modifier (research: finish vs target vs competitive = ±10-15%)
        var target = base * goal.carbsPerHourMultiplier

        // Body weight scaling (outliers only)
        if bodyWeightKg < 55 { target *= 0.90 }
        if bodyWeightKg > 85 { target *= 1.05 }

        // Hard safety caps — never prescribe beyond proven gut tolerance
        let absoluteCeiling: Double = 120
        target = min(target, absoluteCeiling)

        // Gut-training ceiling overrides if the athlete has proven lower tolerance
        if let toleranceCeiling {
            target = min(target, Double(toleranceCeiling))
        }

        // Round to 5
        let rounded = (target / 5).rounded() * 5
        return max(0, Int(rounded))
    }

    // MARK: Hydration ml/hr

    static func hydrationMlPerHour(
        sweatProfile: SweatProfile,
        bodyWeightKg: Double,
        weather: WeatherImpactCalculator.NutritionWeatherAdjustment?
    ) -> Int {
        // If measured sweat rate exists, replace 80% of sweat loss.
        if let sweatRate = sweatProfile.sweatRateMlPerHour {
            return max(300, min(1000, Int(Double(sweatRate) * 0.80)))
        }

        // Heuristic base: 500 ml/hr, adjusted by heat/humidity multiplier.
        var base: Double = 500
        // Size adjustment (heavier athletes lose more fluid).
        base += (bodyWeightKg - 70) * 5

        // Weather multiplier (already captures heat/humidity intensification)
        let multiplier = weather?.hydrationMultiplier ?? 1.0
        base *= multiplier

        return max(300, min(1000, Int(base)))
    }

    // MARK: Sodium mg/hr

    static func sodiumMgPerHour(
        sweatProfile: SweatProfile,
        hydrationMlPerHour: Int,
        durationHours: Double,
        weather: WeatherImpactCalculator.NutritionWeatherAdjustment?
    ) -> Int {
        // Modern model: sodium is mg per liter of fluid (matching sweat loss).
        let mgPerLiter: Int
        if let measured = sweatProfile.sweatSodiumMgPerL {
            mgPerLiter = measured
        } else if sweatProfile.heavySaltySweater {
            mgPerLiter = 1200
        } else {
            // Default average sweater ~700 mg/L, bumped 200 in heat
            var defaultConc = 700
            if let heat = weather?.sodiumMultiplier, heat > 1.1 {
                defaultConc = 900
            }
            mgPerLiter = defaultConc
        }

        // ISSN ultra floor: >= 575 mg/L for races >6h (hyponatremia prevention)
        let appliedConcentration = durationHours > 6
            ? max(mgPerLiter, 575)
            : mgPerLiter

        let mgPerHour = (hydrationMlPerHour * appliedConcentration) / 1000
        return max(200, min(1500, mgPerHour))
    }

    // MARK: Caffeine total mg

    static func caffeineTotalMg(
        for preferences: NutritionPreferences,
        bodyWeightKg: Double
    ) -> Int {
        if preferences.avoidCaffeine || preferences.caffeineSensitivity == .none {
            return 0
        }
        let target = preferences.caffeineSensitivity.targetMgPerKg * bodyWeightKg
        // ISSN hard cap 6 mg/kg for performance; we clip at 9 mg/kg absolute.
        let capped = min(target, 9 * bodyWeightKg)
        // Round to 25 mg granularity (typical gel caffeine doses).
        return Int((capped / 25).rounded() * 25)
    }
}

// MARK: - Schedule Builder

/// Lays out the in-race fueling timeline.
///
/// Strategy by duration:
/// - **<90 min**: 1-2 gels + optional water with electrolytes.
/// - **90 min - 4 h**: drink base every 60 min + gel every 30-45 min.
/// - **4 h - 8 h** (marathon / short trail): drink + gel + solid every 90 min.
/// - **8 h+** (ultra): drink + gel + solid every 60 min + savory after hour 4.
enum NutritionScheduleBuilder {

    static func build(
        durationMinutes: Int,
        carbsTargetGramsPerHour: Int,
        hydrationMlPerHour: Int,
        sodiumMgPerHour: Int,
        totalCaffeineMg: Int,
        preferences: NutritionPreferences
    ) -> [NutritionEntry] {

        let durationHours = Double(durationMinutes) / 60

        // No fueling for sub-30 min races
        guard durationMinutes >= 30 else { return [] }

        var entries: [NutritionEntry] = []

        // Short (30-90 min): 1-2 gels + maybe a drink
        if durationMinutes < 90 {
            entries.append(contentsOf: buildShort(
                durationMinutes: durationMinutes,
                preferences: preferences
            ))
        }
        // Marathon range (90 min - 4 h)
        else if durationHours < 4 {
            entries.append(contentsOf: buildStandard(
                durationMinutes: durationMinutes,
                carbsTarget: carbsTargetGramsPerHour,
                sodiumPerHour: sodiumMgPerHour,
                preferences: preferences,
                includeSolid: false
            ))
        }
        // Short trail / 50K (4-8 h)
        else if durationHours < 8 {
            entries.append(contentsOf: buildStandard(
                durationMinutes: durationMinutes,
                carbsTarget: carbsTargetGramsPerHour,
                sodiumPerHour: sodiumMgPerHour,
                preferences: preferences,
                includeSolid: true
            ))
        }
        // Long ultra (8 h+)
        else {
            entries.append(contentsOf: buildUltra(
                durationMinutes: durationMinutes,
                carbsTarget: carbsTargetGramsPerHour,
                sodiumPerHour: sodiumMgPerHour,
                preferences: preferences
            ))
        }

        // Distribute caffeine across the timeline based on total race length.
        entries.append(contentsOf: buildCaffeineSchedule(
            durationMinutes: durationMinutes,
            totalCaffeineMg: totalCaffeineMg,
            preferences: preferences
        ))

        return entries.sorted { $0.timingMinutes < $1.timingMinutes }
    }

    // MARK: Short races (30-90 min)

    private static func buildShort(
        durationMinutes: Int,
        preferences: NutritionPreferences
    ) -> [NutritionEntry] {
        var entries: [NutritionEntry] = []
        guard let gel = NutritionProductSelector.pick(
            type: .gel, caffeinated: false, preferences: preferences
        ) else { return [] }

        if durationMinutes < 60 {
            // Optional single gel at halfway for 40-60 min races
            if durationMinutes >= 40 {
                entries.append(entry(product: gel,
                                     timingMinutes: durationMinutes / 2,
                                     notes: "Optional — take only if you feel energy dropping"))
            }
        } else {
            // 60-90 min: 1 gel every 30 min
            for minute in stride(from: 30, through: durationMinutes - 15, by: 30) {
                entries.append(entry(product: gel, timingMinutes: minute,
                                     notes: "Take with a sip of water"))
            }
        }
        return entries
    }

    // MARK: Standard + trail (90 min - 8 h)

    private static func buildStandard(
        durationMinutes: Int,
        carbsTarget: Int,
        sodiumPerHour: Int,
        preferences: NutritionPreferences,
        includeSolid: Bool
    ) -> [NutritionEntry] {
        var entries: [NutritionEntry] = []

        guard let gel = NutritionProductSelector.pick(type: .gel, caffeinated: false, preferences: preferences),
              let drink = NutritionProductSelector.pick(type: .drink, caffeinated: false, preferences: preferences)
        else { return [] }

        // Drink base every 60 min provides ~40-60 g + sodium
        for minute in stride(from: 60, through: durationMinutes - 15, by: 60) {
            entries.append(entry(product: drink, timingMinutes: minute,
                                 notes: "Mix with \(drink.fluidMlPerServing ?? 500) ml water. Sip over 45-60 min."))
        }

        // Gel every 30-45 min (more frequent if carb target is high)
        let gelInterval = carbsTarget >= 75 ? 30 : 40
        for minute in stride(from: gelInterval, through: durationMinutes - 20, by: gelInterval) {
            // Skip if a drink is already delivered this minute
            if minute % 60 == 0 { continue }
            entries.append(entry(product: gel, timingMinutes: minute,
                                 notes: "Take with 150-200 ml water"))
        }

        // Solids for 4-8 h range — one every 90 min after hour 2
        if includeSolid,
           let solid = NutritionProductSelector.pickSolid(preferences: preferences) {
            for minute in stride(from: 120, through: durationMinutes - 30, by: 90) {
                entries.append(entry(product: solid, timingMinutes: minute,
                                     notes: "At aid station if possible — chew thoroughly"))
            }
        }

        // Extra salt if sodium target high and drink alone isn't enough
        if sodiumPerHour > 700,
           let salt = NutritionProductSelector.pick(type: .salt, caffeinated: false, preferences: preferences) {
            for minute in stride(from: 60, through: durationMinutes - 30, by: 60) {
                entries.append(entry(product: salt, timingMinutes: minute,
                                     notes: "Heavy salty sweater dose"))
            }
        }

        return entries
    }

    // MARK: Ultra (8 h+)

    private static func buildUltra(
        durationMinutes: Int,
        carbsTarget: Int,
        sodiumPerHour: Int,
        preferences: NutritionPreferences
    ) -> [NutritionEntry] {
        var entries: [NutritionEntry] = []

        guard let drink = NutritionProductSelector.pick(type: .drink, caffeinated: false, preferences: preferences)
        else { return [] }

        // Continuous drink base every 45 min (to hit carb + sodium target together)
        for minute in stride(from: 45, through: durationMinutes - 20, by: 45) {
            entries.append(entry(product: drink, timingMinutes: minute,
                                 notes: "Mix with \(drink.fluidMlPerServing ?? 500) ml water"))
        }

        // Gel every 45 min in first half (most athletes go off sweet after hour 4-6)
        let gelCutoff = min(durationMinutes / 2, 4 * 60)
        if let gel = NutritionProductSelector.pick(type: .gel, caffeinated: false, preferences: preferences) {
            for minute in stride(from: 30, through: gelCutoff, by: 45) {
                entries.append(entry(product: gel, timingMinutes: minute,
                                     notes: "Take with water"))
            }
        }

        // Solids every 60 min after hour 2 (transition from gels)
        if let solid = NutritionProductSelector.pickSolid(preferences: preferences) {
            for minute in stride(from: 120, through: durationMinutes - 30, by: 60) {
                entries.append(entry(product: solid, timingMinutes: minute,
                                     notes: "Real food — best at aid stations"))
            }
        }

        // Savory/salty items every 2 h after hour 4 (flavor-fatigue relief)
        if let savory = NutritionProductSelector.pickSavory(preferences: preferences) {
            for minute in stride(from: 4 * 60, through: durationMinutes - 30, by: 120) {
                entries.append(entry(product: savory, timingMinutes: minute,
                                     notes: "Savory break — eat slowly at aid station"))
            }
        }

        // Salt caps every 60 min (ultras need consistent sodium)
        if let salt = NutritionProductSelector.pick(type: .salt, caffeinated: false, preferences: preferences) {
            for minute in stride(from: 60, through: durationMinutes - 30, by: 60) {
                entries.append(entry(product: salt, timingMinutes: minute,
                                     notes: "Take with water"))
            }
        }

        return entries
    }

    // MARK: Caffeine schedule

    private static func buildCaffeineSchedule(
        durationMinutes: Int,
        totalCaffeineMg: Int,
        preferences: NutritionPreferences
    ) -> [NutritionEntry] {
        guard totalCaffeineMg >= 50 else { return [] }
        guard let caffGel = NutritionProductSelector.pick(
            type: .gel, caffeinated: true, preferences: preferences
        ) else { return [] }

        var entries: [NutritionEntry] = []
        let durationHours = Double(durationMinutes) / 60

        if durationHours < 2 {
            // Single pre-race dose only (not an in-race entry) — skip.
            return []
        } else if durationHours < 6 {
            // Split dose: 50% at halfway, 25% at 3/4, with one pre-race note.
            let halfway = durationMinutes / 2
            let threeQuarter = durationMinutes * 3 / 4
            entries.append(entry(product: caffGel, timingMinutes: halfway,
                                 notes: "Caffeinated gel — energy kick for back half"))
            entries.append(entry(product: caffGel, timingMinutes: threeQuarter,
                                 notes: "Final caffeine dose"))
        } else {
            // Ultra: back-loaded. 1 dose every 2 h starting at hour 3,
            // concentrated during predicted low points (night hours).
            let startHour = 3
            let endHour = Int(durationHours) - 1
            for hour in stride(from: startHour, through: endHour, by: 2) {
                entries.append(entry(product: caffGel, timingMinutes: hour * 60,
                                     notes: "Caffeinated gel — back-loaded dose"))
            }
        }
        return entries
    }

    // MARK: Entry helper

    private static func entry(
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

// MARK: - Product Selector

/// Picks products from the catalog that match the athlete's filters:
/// dietary restrictions, GI sensitivities, excluded products, format prefs.
/// Always returns the highest-priority match (favorites > preferred format >
/// catalog default).
enum NutritionProductSelector {

    static func pick(
        type: ProductType,
        caffeinated: Bool,
        preferences: NutritionPreferences
    ) -> NutritionProduct? {
        let candidates = DefaultProducts.all.filter { product in
            product.type == type
            && product.caffeinated == caffeinated
            && !preferences.excludedProductIds.contains(product.id)
            && passesDietaryFilter(product, preferences: preferences)
            && passesGIFilter(product, preferences: preferences)
            && passesFormatPreference(product, preferences: preferences)
        }

        // Prefer favorites first, then the first matching product.
        if let favorite = candidates.first(where: { preferences.favoriteProductIds.contains($0.id) }) {
            return favorite
        }
        return candidates.first ?? fallback(type: type, caffeinated: caffeinated, preferences: preferences)
    }

    /// Fallback ignores format preference so that an absent preferred format
    /// doesn't drop a nutritionally-required entry from the plan.
    private static func fallback(
        type: ProductType,
        caffeinated: Bool,
        preferences: NutritionPreferences
    ) -> NutritionProduct? {
        DefaultProducts.all.first { product in
            product.type == type
            && product.caffeinated == caffeinated
            && !preferences.excludedProductIds.contains(product.id)
            && passesDietaryFilter(product, preferences: preferences)
        }
    }

    /// Picks a solid real-food item preferring carbs+sodium balance (potato,
    /// rice ball, pretzels), avoiding high-fiber or high-fat by default.
    static func pickSolid(preferences: NutritionPreferences) -> NutritionProduct? {
        let candidates = DefaultProducts.solids.filter { product in
            !preferences.excludedProductIds.contains(product.id)
            && passesDietaryFilter(product, preferences: preferences)
            && passesGIFilter(product, preferences: preferences)
        }
        // Prefer items with some sodium (race-specific value)
        return candidates.sorted { $0.sodiumMgPerServing > $1.sodiumMgPerServing }.first
    }

    /// Savory/salty item for late-race flavor fatigue relief.
    static func pickSavory(preferences: NutritionPreferences) -> NutritionProduct? {
        let savoryNames: Set<String> = ["Pretzels (handful)", "Bone Broth Cup", "Boiled Potato (salted)", "Rice Ball (Onigiri)"]
        return DefaultProducts.solids.first { product in
            savoryNames.contains(product.name)
            && !preferences.excludedProductIds.contains(product.id)
            && passesDietaryFilter(product, preferences: preferences)
            && passesGIFilter(product, preferences: preferences)
        }
    }

    // MARK: Filters

    private static func passesDietaryFilter(
        _ product: NutritionProduct,
        preferences: NutritionPreferences
    ) -> Bool {
        for restriction in preferences.dietaryRestrictions {
            switch restriction {
            case .vegan:      if !product.dietaryFlags.contains(.vegan) { return false }
            case .vegetarian: if !product.dietaryFlags.contains(.vegetarian) { return false }
            case .glutenFree: if !product.dietaryFlags.contains(.glutenFree) { return false }
            case .dairyFree:  if !product.dietaryFlags.contains(.dairyFree) { return false }
            case .nutFree:    if !product.dietaryFlags.contains(.nutFree) { return false }
            }
        }
        return true
    }

    private static func passesGIFilter(
        _ product: NutritionProduct,
        preferences: NutritionPreferences
    ) -> Bool {
        for sensitivity in preferences.giSensitivities {
            switch sensitivity {
            case .lactose:  if product.dietaryFlags.contains(.containsLactose) { return false }
            case .fructose: if product.dietaryFlags.contains(.containsFructose) { return false }
            case .fiber:    if product.dietaryFlags.contains(.highFiber) { return false }
            case .fat:      if product.dietaryFlags.contains(.highFat) { return false }
            case .gluten:   if !product.dietaryFlags.contains(.glutenFree) { return false }
            case .fodmap:   if !product.dietaryFlags.contains(.lowFodmap) { return false }
            }
        }
        return true
    }

    private static func passesFormatPreference(
        _ product: NutritionProduct,
        preferences: NutritionPreferences
    ) -> Bool {
        // Empty set = no preference
        guard !preferences.preferredFormats.isEmpty else { return true }
        return preferences.preferredFormats.contains(product.type)
    }
}
