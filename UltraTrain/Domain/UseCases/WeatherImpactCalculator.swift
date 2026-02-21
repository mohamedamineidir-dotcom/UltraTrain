import Foundation

enum WeatherImpactCalculator {

    struct WeatherImpact: Equatable, Sendable {
        let multiplier: Double
        let heatImpactPercent: Double
        let humidityCompoundPercent: Double
        let rainImpactPercent: Double
        let windImpactPercent: Double
        let coldImpactPercent: Double
        let summary: String
        let severity: WeatherImpactSeverity
    }

    enum WeatherImpactSeverity: String, Sendable, Equatable {
        case none, minor, moderate, significant, severe
    }

    struct NutritionWeatherAdjustment: Equatable, Sendable {
        let hydrationMultiplier: Double
        let sodiumMultiplier: Double
        let caloriesMultiplier: Double
        let notes: [String]
    }

    // MARK: - Impact Calculation
    static func calculateImpact(weather: WeatherSnapshot) -> WeatherImpact {
        calculateImpactFromComponents(
            temperatureCelsius: weather.temperatureCelsius,
            humidity: weather.humidity,
            windSpeedKmh: weather.windSpeedKmh,
            condition: weather.condition
        )
    }

    static func calculateImpact(forecast: DailyWeatherForecast) -> WeatherImpact {
        let avgTemp = (forecast.highTemperatureCelsius + forecast.lowTemperatureCelsius) / 2.0
        return calculateImpactFromComponents(
            temperatureCelsius: avgTemp,
            humidity: 0.5,
            windSpeedKmh: forecast.windSpeedKmh,
            condition: forecast.condition
        )
    }

    // MARK: - Nutrition Adjustment
    static func nutritionAdjustment(weather: WeatherSnapshot) -> NutritionWeatherAdjustment {
        nutritionAdjustmentFromComponents(
            temperatureCelsius: weather.temperatureCelsius,
            humidity: weather.humidity,
            condition: weather.condition
        )
    }

    static func nutritionAdjustment(forecast: DailyWeatherForecast) -> NutritionWeatherAdjustment {
        let avgTemp = (forecast.highTemperatureCelsius + forecast.lowTemperatureCelsius) / 2.0
        return nutritionAdjustmentFromComponents(
            temperatureCelsius: avgTemp,
            humidity: 0.5,
            condition: forecast.condition
        )
    }

    // MARK: - Private Core Logic
    private static func calculateImpactFromComponents(
        temperatureCelsius: Double,
        humidity: Double,
        windSpeedKmh: Double,
        condition: WeatherConditionType
    ) -> WeatherImpact {
        let config = AppConfiguration.WeatherImpact.self

        // Heat impact
        var heatPercent = 0.0
        if temperatureCelsius > config.heatBaselineCelsius {
            heatPercent = (temperatureCelsius - config.heatBaselineCelsius) * config.heatImpactPerDegree * 100
            heatPercent = min(heatPercent, config.maxHeatImpact * 100)
        }

        // Humidity compounding (only when heat impact exists)
        var humidityCompoundPercent = 0.0
        if heatPercent > 0 && humidity > config.humidityCompoundingThreshold {
            var humidityFactor = 1.0 + (humidity - config.humidityCompoundingThreshold)
                / (1.0 - config.humidityCompoundingThreshold)
                * (config.humidityCompoundingMax - 1.0)
            humidityFactor = min(humidityFactor, config.humidityCompoundingMax)
            humidityCompoundPercent = heatPercent * (humidityFactor - 1.0)
        }

        // Rain impact
        let rainPercent: Double = switch condition {
        case .heavyRain, .thunderstorm: config.heavyRainImpact * 100
        case .rain: config.moderateRainImpact * 100
        case .drizzle: config.lightRainImpact * 100
        default: 0
        }

        // Wind impact
        let windPercent: Double
        if windSpeedKmh >= config.strongWindThresholdKmh {
            windPercent = config.strongWindImpact * 100
        } else if windSpeedKmh >= config.windThresholdKmh {
            windPercent = config.windImpact * 100
        } else {
            windPercent = 0
        }

        // Cold impact
        var coldPercent = 0.0
        if temperatureCelsius < config.coldThresholdCelsius {
            coldPercent = (config.coldThresholdCelsius - temperatureCelsius) * config.coldImpactPerDegree * 100
            coldPercent = min(coldPercent, config.maxColdImpact * 100)
        }

        let totalPercent = heatPercent + humidityCompoundPercent + rainPercent + windPercent + coldPercent
        let multiplier = 1.0 + totalPercent / 100.0
        let severity = severity(for: totalPercent)
        let summary = buildSummary(
            heatPercent: heatPercent,
            humidityCompoundPercent: humidityCompoundPercent,
            rainPercent: rainPercent,
            windPercent: windPercent,
            coldPercent: coldPercent
        )

        return WeatherImpact(
            multiplier: multiplier,
            heatImpactPercent: heatPercent,
            humidityCompoundPercent: humidityCompoundPercent,
            rainImpactPercent: rainPercent,
            windImpactPercent: windPercent,
            coldImpactPercent: coldPercent,
            summary: summary,
            severity: severity
        )
    }

    private static func severity(for totalPercent: Double) -> WeatherImpactSeverity {
        switch totalPercent {
        case 0: .none
        case ...3: .minor
        case ...8: .moderate
        case ...15: .significant
        default: .severe
        }
    }

    private static func buildSummary(
        heatPercent: Double, humidityCompoundPercent: Double,
        rainPercent: Double, windPercent: Double, coldPercent: Double
    ) -> String {
        var parts: [String] = []
        if heatPercent > 0 { parts.append("Heat (+\(String(format: "%.1f", heatPercent))%)") }
        if humidityCompoundPercent > 0 { parts.append("Humidity (+\(String(format: "%.1f", humidityCompoundPercent))%)") }
        if rainPercent > 0 { parts.append("Rain (+\(String(format: "%.1f", rainPercent))%)") }
        if windPercent > 0 { parts.append("Wind (+\(String(format: "%.1f", windPercent))%)") }
        if coldPercent > 0 { parts.append("Cold (+\(String(format: "%.1f", coldPercent))%)") }
        return parts.isEmpty ? "No significant weather impact" : parts.joined(separator: ", ")
    }

    // MARK: - Private Nutrition Logic

    private static func nutritionAdjustmentFromComponents(
        temperatureCelsius: Double,
        humidity: Double,
        condition: WeatherConditionType
    ) -> NutritionWeatherAdjustment {
        let config = AppConfiguration.WeatherImpact.self
        let isHot = temperatureCelsius > config.heatBaselineCelsius
        let isCold = temperatureCelsius < config.coldThresholdCelsius

        let hydrationMultiplier = isHot ? config.heatHydrationMultiplier : 1.0
        let sodiumMultiplier = isHot ? config.heatSodiumMultiplier : 1.0
        let caloriesMultiplier = isCold ? config.coldCalorieMultiplier : 1.0

        var notes: [String] = []
        if isHot {
            notes.append("Increase fluid intake — expect higher sweat rate in warm conditions")
        }
        if isHot && humidity > config.humidityCompoundingThreshold {
            notes.append("High heat and humidity — consider ice/cold sponges at aid stations")
        }
        if isCold {
            notes.append("Increase calorie intake — your body burns more energy in cold weather")
        }
        let isRainy = condition == .rain || condition == .heavyRain
            || condition == .drizzle || condition == .thunderstorm
        if isRainy {
            notes.append("Protect nutrition supplies from moisture")
        }

        return NutritionWeatherAdjustment(
            hydrationMultiplier: hydrationMultiplier,
            sodiumMultiplier: sodiumMultiplier,
            caloriesMultiplier: caloriesMultiplier,
            notes: notes
        )
    }
}
