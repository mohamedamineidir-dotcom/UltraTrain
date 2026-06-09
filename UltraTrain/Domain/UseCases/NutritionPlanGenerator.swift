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

        // Hard safety caps, never prescribe beyond proven gut tolerance
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
        let raw: Int
        if let sweatRate = sweatProfile.sweatRateMlPerHour {
            // If measured sweat rate exists, replace 80% of sweat loss.
            raw = max(300, min(1000, Int(Double(sweatRate) * 0.80)))
        } else {
            // Heuristic base: 500 ml/hr, adjusted by heat/humidity multiplier.
            var base: Double = 500
            // Size adjustment (heavier athletes lose more fluid).
            base += (bodyWeightKg - 70) * 5
            // Weather multiplier (already captures heat/humidity intensification)
            let multiplier = weather?.hydrationMultiplier ?? 1.0
            base *= multiplier
            raw = max(300, min(1000, Int(base)))
        }
        // Round to nearest 25 ml so values read as 500 / 525 / 550 rather
        // than the jagged 502 / 517 / 548 that the raw formula produces.
        return roundToNearest(raw, step: 25)
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
        let clamped = max(200, min(1500, mgPerHour))
        // Round to nearest 25 mg for the same reason we round hydration
        // jagged values like 351 / 487 read as arbitrary precision when
        // they're really heuristic targets.
        return roundToNearest(clamped, step: 25)
    }

    // MARK: Helpers

    /// Rounds a value to the nearest multiple of `step`. Used on targets
    /// that the athlete sees directly, jagged digits erode trust in the
    /// recommendation by signalling false precision.
    fileprivate static func roundToNearest(_ value: Int, step: Int) -> Int {
        guard step > 1 else { return value }
        let half = step / 2
        return ((value + half) / step) * step
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

        // Post-process: merge near-clashes and enforce a minimum gap
        // between adjacent carb intakes so the timeline never ships
        // two gels 10 minutes apart. Caffeine-gel placement is
        // computed independently from the base gel/drink schedule, so
        // without this pass a 50%-of-duration caffeine gel can land
        // right next to a 30-minute base gel (the original bug:
        // gel @ 1h20, gel @ 1h30 on a sub-2h40 marathon).
        return enforceCarbTimingSpacing(
            entries.sorted { $0.timingMinutes < $1.timingMinutes },
            durationMinutes: durationMinutes
        )
    }

    /// Minimum gap (minutes) between two *discrete* carb intakes
    /// (gel-to-gel, gel-to-caffeine-gel, solid-to-solid). Anchored on:
    /// - Jeukendrup 2010 / 2014: small frequent doses better tolerated
    ///   than boluses; 20-25 min between gels is the working norm.
    /// - ACSM/IOC 2016: 60-90 g/h split across the hour.
    /// - Stellingwerff & Cox 2014: 20-25 g every 20 min = 60-75 g/h.
    /// - Costa et al. 2017 (gut-training meta): GI tolerance drops
    ///   sharply when intra-bolus interval falls below ~15 min.
    /// 18 min sits in the comfortable middle: up to ~3.3 intakes / h
    /// (≈ 80 g/h with 25 g gels) without crossing the GI-risk line.
    ///
    /// Items at *exactly* the same minute (a drink and a caffeine gel
    /// both placed at the halfway mark, say) are preserved, athletes
    /// routinely take both with the same sip of water and showing them
    /// as a single timestamp on the timeline is the correct UX.
    private static let minDiscreteGapMinutes: Int = 18

    /// Minimum gap when one of the two items is a drink. Drinks are
    /// a continuous sipping vehicle, not a bolus event, so they don't
    /// compete with gels for GI capacity at the same instant. 5 min
    /// is enough to read as a separate timeline event without
    /// crowding the athlete's mid-race attention.
    private static let minDrinkAdjacencyGapMinutes: Int = 5

    /// Cutoff for the *last* carb intake. Marathon-and-shorter races
    /// stop fuelling 15 min before the finish so a gel's absorption
    /// window (10-20 min for glucose to hit the bloodstream, Coyle
    /// 1992, Jentjens 2004) starts before the finish line. Ultras
    /// stop 30 min out, late carbs there are largely psychological
    /// rather than ergogenic.
    private static func lastIntakeCutoffMinutes(_ duration: Int) -> Int {
        if duration >= 4 * 60 { return max(0, duration - 30) }
        return max(0, duration - 15)
    }

    /// Walks the sorted timeline and shifts later entries forward so
    /// adjacent intakes that occur at *different* minutes never sit
    /// closer than the minimum gap. Caffeine and base schedules are
    /// computed independently, which produced timelines like "gel @
    /// 1h20, gel @ 1h30", too tight for the gut and pointless for
    /// blood-glucose stability. We *shift* rather than *drop* so the
    /// total carb load stays at the prescribed target rate, and round
    /// shifted times up to the nearest 5-minute boundary so the
    /// timeline reads as "1h40" rather than "1h38".
    private static func enforceCarbTimingSpacing(
        _ entries: [NutritionEntry],
        durationMinutes: Int
    ) -> [NutritionEntry] {
        guard entries.count > 1 else { return entries }
        var result = entries

        for idx in 1..<result.count {
            let prev = result[idx - 1]
            let current = result[idx]
            let gap = current.timingMinutes - prev.timingMinutes
            let minGap = minGapBetween(prev, current)
            if gap > 0 && gap < minGap {
                result[idx].timingMinutes = roundedToFiveMinutes(prev.timingMinutes + minGap)
            }
        }

        // Drop anything past the race-class-aware cutoff so a gel
        // taken inside the final absorption window doesn't make it
        // to the timeline.
        let cutoff = lastIntakeCutoffMinutes(durationMinutes)
        return result.filter { $0.timingMinutes <= cutoff }
    }

    /// Drink ↔ anything pairs use the relaxed 5-min adjacency rule;
    /// discrete-bolus pairs (gel, caffeine gel, solid) use 18 min.
    private static func minGapBetween(_ a: NutritionEntry, _ b: NutritionEntry) -> Int {
        if a.product.type == .drink || b.product.type == .drink {
            return minDrinkAdjacencyGapMinutes
        }
        return minDiscreteGapMinutes
    }

    /// Rounds a minute value UP to the next 5-minute boundary. Used
    /// by the spacing pass when shifting a tight intake forward, the
    /// shifted time must remain ≥ `prev + minGap`, so we round up.
    private static func roundedToFiveMinutes(_ minutes: Int) -> Int {
        ((minutes + 4) / 5) * 5
    }

    /// Rounds to the NEAREST 5-minute boundary. Used for caffeine
    /// anchors where the target percentage is a *suggestion* (45% /
    /// 75% of duration), so rounding to the closer multiple gives a
    /// cleaner number, 72 → 70 instead of 75, 112 → 110 instead of
    /// 115. The spacing pass still uses up-rounding so any
    /// subsequent shift can't violate the min-gap rule.
    private static func roundedToNearestFiveMinutes(_ minutes: Int) -> Int {
        ((minutes + 2) / 5) * 5
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
                                     notes: String(localized: "npg.note.optional", defaultValue: "Optional, take only if you feel energy dropping")))
            }
        } else {
            // 60-90 min: 1 gel every 30 min
            for minute in stride(from: 30, through: durationMinutes - 15, by: 30) {
                entries.append(entry(product: gel, timingMinutes: minute,
                                     notes: String(localized: "npg.note.sipWater", defaultValue: "Take with a sip of water")))
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
                                 notes: String(localized: "npg.note.mixSip", defaultValue: "Mix with \(drink.fluidMlPerServing ?? 500) ml water. Sip over 45-60 min.")))
        }

        // Gel every 30-45 min (more frequent if carb target is high)
        let gelInterval = carbsTarget >= 75 ? 30 : 40
        for minute in stride(from: gelInterval, through: durationMinutes - 20, by: gelInterval) {
            // Skip if a drink is already delivered this minute
            if minute % 60 == 0 { continue }
            entries.append(entry(product: gel, timingMinutes: minute,
                                 notes: String(localized: "npg.note.with150", defaultValue: "Take with 150-200 ml water")))
        }

        // Solids for 4-8 h range, one every 90 min after hour 2
        if includeSolid,
           let solid = NutritionProductSelector.pickSolid(preferences: preferences) {
            for minute in stride(from: 120, through: durationMinutes - 30, by: 90) {
                entries.append(entry(product: solid, timingMinutes: minute,
                                     notes: String(localized: "npg.note.aidChew", defaultValue: "At aid station if possible, chew thoroughly")))
            }
        }

        // Extra salt if sodium target high and drink alone isn't enough
        if sodiumPerHour > 700,
           let salt = NutritionProductSelector.pick(type: .salt, caffeinated: false, preferences: preferences) {
            for minute in stride(from: 60, through: durationMinutes - 30, by: 60) {
                entries.append(entry(product: salt, timingMinutes: minute,
                                     notes: String(localized: "npg.note.saltySweater", defaultValue: "Heavy salty sweater dose")))
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
                                 notes: String(localized: "npg.note.mix", defaultValue: "Mix with \(drink.fluidMlPerServing ?? 500) ml water")))
        }

        // Gel every 45 min in first half (most athletes go off sweet after hour 4-6)
        let gelCutoff = min(durationMinutes / 2, 4 * 60)
        if let gel = NutritionProductSelector.pick(type: .gel, caffeinated: false, preferences: preferences) {
            for minute in stride(from: 30, through: gelCutoff, by: 45) {
                entries.append(entry(product: gel, timingMinutes: minute,
                                     notes: String(localized: "npg.note.withWater", defaultValue: "Take with water")))
            }
        }

        // Solids every 60 min after hour 2 (transition from gels)
        if let solid = NutritionProductSelector.pickSolid(preferences: preferences) {
            for minute in stride(from: 120, through: durationMinutes - 30, by: 60) {
                entries.append(entry(product: solid, timingMinutes: minute,
                                     notes: String(localized: "npg.note.realFood", defaultValue: "Real food, best at aid stations")))
            }
        }

        // Savory/salty items every 2 h after hour 4 (flavor-fatigue relief)
        if let savory = NutritionProductSelector.pickSavory(preferences: preferences) {
            for minute in stride(from: 4 * 60, through: durationMinutes - 30, by: 120) {
                entries.append(entry(product: savory, timingMinutes: minute,
                                     notes: String(localized: "npg.note.savory", defaultValue: "Savory break, eat slowly at aid station")))
            }
        }

        // Salt caps every 60 min (ultras need consistent sodium)
        if let salt = NutritionProductSelector.pick(type: .salt, caffeinated: false, preferences: preferences) {
            for minute in stride(from: 60, through: durationMinutes - 30, by: 60) {
                entries.append(entry(product: salt, timingMinutes: minute,
                                     notes: String(localized: "npg.note.withWater", defaultValue: "Take with water")))
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
            // Single pre-race dose only (not an in-race entry), skip.
            return []
        } else if durationHours < 6 {
            // Caffeine peaks in plasma 30-60 min after ingestion
            // (Graham & Spriet 1995; Burke 2008). Anchor the first
            // dose at 45% of duration so its peak lands during the
            // back-half suffer zone (60-75% of the race). Anchor the
            // second dose at 75%, for a 2h40 marathon (160 min) that
            // places it at exactly 2h00, with the effect peaking
            // ~2h30 just before the finish surge. Round to NEAREST
            // 5 min (not up) so anchors land on clean round numbers
            // ("2h00", "1h10") instead of computed precision
            // ("1h55", "1h12") that reads as machine output.
            let halfway = roundedToNearestFiveMinutes(durationMinutes * 45 / 100)
            let threeQuarter = roundedToNearestFiveMinutes(durationMinutes * 75 / 100)
            entries.append(entry(product: caffGel, timingMinutes: halfway,
                                 notes: String(localized: "npg.note.caffPeak", defaultValue: "Caffeinated gel, peaks ~45 min later, hits the back-half suffer zone")))
            entries.append(entry(product: caffGel, timingMinutes: threeQuarter,
                                 notes: String(localized: "npg.note.caffFinal", defaultValue: "Final caffeine dose, peaks near the finish surge")))
        } else {
            // Ultra: back-loaded. 1 dose every 2 h starting at hour 3,
            // concentrated during predicted low points (night hours).
            let startHour = 3
            let endHour = Int(durationHours) - 1
            for hour in stride(from: startHour, through: endHour, by: 2) {
                entries.append(entry(product: caffGel, timingMinutes: hour * 60,
                                     notes: String(localized: "npg.note.caffBack", defaultValue: "Caffeinated gel, back-loaded dose")))
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

        // Prefer favorites first.
        if let favorite = candidates.first(where: { preferences.favoriteProductIds.contains($0.id) }) {
            return favorite
        }
        // Then prefer products from a brand the athlete chose for this format.
        if let brandMatch = candidates.first(where: { matchesBrandPreference($0, type: type, preferences: preferences) }) {
            return brandMatch
        }
        return candidates.first ?? fallback(type: type, caffeinated: caffeinated, preferences: preferences)
    }

    /// True when the athlete set a brand preference for this format and
    /// the product belongs to one of those brands. False (permissive) when
    /// no brand preference is set, the selector treats that as "any brand".
    private static func matchesBrandPreference(
        _ product: NutritionProduct,
        type: ProductType,
        preferences: NutritionPreferences
    ) -> Bool {
        guard let preferredBrands = preferences.brandPreferences[type],
              !preferredBrands.isEmpty else {
            return false
        }
        guard let brand = product.brand else { return false }
        return preferredBrands.contains(brand)
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
