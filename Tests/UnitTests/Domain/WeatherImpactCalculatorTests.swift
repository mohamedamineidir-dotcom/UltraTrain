import Foundation
import Testing
@testable import UltraTrain

@Suite("Weather Impact Calculator Tests")
struct WeatherImpactCalculatorTests {

    // MARK: - Helpers

    private func makeSnapshot(
        temperature: Double = 15,
        humidity: Double = 0.5,
        windSpeedKmh: Double = 10,
        condition: WeatherConditionType = .clear
    ) -> WeatherSnapshot {
        WeatherSnapshot(
            temperatureCelsius: temperature,
            apparentTemperatureCelsius: temperature,
            humidity: humidity,
            windSpeedKmh: windSpeedKmh,
            windDirectionDegrees: 180,
            condition: condition,
            uvIndex: 5,
            precipitationChance: 0,
            symbolName: "sun.max.fill",
            capturedAt: .now,
            locationLatitude: 45.0,
            locationLongitude: 6.0
        )
    }

    private func makeForecast(
        highTemp: Double = 20,
        lowTemp: Double = 10,
        windSpeedKmh: Double = 10,
        condition: WeatherConditionType = .clear
    ) -> DailyWeatherForecast {
        DailyWeatherForecast(
            date: .now,
            highTemperatureCelsius: highTemp,
            lowTemperatureCelsius: lowTemp,
            condition: condition,
            precipitationChance: 0.1,
            windSpeedKmh: windSpeedKmh,
            uvIndex: 5,
            symbolName: "sun.max.fill"
        )
    }

    // MARK: - Baseline (No Impact)

    @Test("Mild conditions produce no impact")
    func mildConditionsNoImpact() {
        let snapshot = makeSnapshot(temperature: 15, humidity: 0.5, windSpeedKmh: 10, condition: .clear)
        let impact = WeatherImpactCalculator.calculateImpact(weather: snapshot)

        #expect(impact.multiplier == 1.0)
        #expect(impact.severity == .none)
        #expect(impact.heatImpactPercent == 0)
        #expect(impact.coldImpactPercent == 0)
        #expect(impact.windImpactPercent == 0)
        #expect(impact.rainImpactPercent == 0)
    }

    @Test("Exactly at baseline temperature produces no heat impact")
    func baselineTemperatureNoHeat() {
        let snapshot = makeSnapshot(temperature: AppConfiguration.WeatherImpact.heatBaselineCelsius)
        let impact = WeatherImpactCalculator.calculateImpact(weather: snapshot)

        #expect(impact.heatImpactPercent == 0)
    }

    // MARK: - Heat Impact

    @Test("Hot weather increases multiplier")
    func hotWeatherIncreasesMultiplier() {
        let snapshot = makeSnapshot(temperature: 35) // 20°C above baseline
        let impact = WeatherImpactCalculator.calculateImpact(weather: snapshot)

        #expect(impact.multiplier > 1.0)
        #expect(impact.heatImpactPercent > 0)
        // 20 * 0.004 * 100 = 8.0%
        #expect(abs(impact.heatImpactPercent - 8.0) < 0.01)
    }

    @Test("Heat impact is capped at max")
    func heatImpactCapped() {
        let snapshot = makeSnapshot(temperature: 100) // Extreme heat
        let impact = WeatherImpactCalculator.calculateImpact(weather: snapshot)

        #expect(impact.heatImpactPercent <= AppConfiguration.WeatherImpact.maxHeatImpact * 100)
    }

    // MARK: - Humidity Compounding

    @Test("High humidity compounds heat impact")
    func humidityCompoundsHeat() {
        let hotDry = makeSnapshot(temperature: 30, humidity: 0.5)
        let hotHumid = makeSnapshot(temperature: 30, humidity: 0.9)

        let dryImpact = WeatherImpactCalculator.calculateImpact(weather: hotDry)
        let humidImpact = WeatherImpactCalculator.calculateImpact(weather: hotHumid)

        #expect(humidImpact.multiplier > dryImpact.multiplier)
        #expect(humidImpact.humidityCompoundPercent > 0)
        #expect(dryImpact.humidityCompoundPercent == 0)
    }

    @Test("Humidity has no effect without heat")
    func humidityNoEffectWithoutHeat() {
        let snapshot = makeSnapshot(temperature: 10, humidity: 0.95)
        let impact = WeatherImpactCalculator.calculateImpact(weather: snapshot)

        #expect(impact.humidityCompoundPercent == 0)
    }

    // MARK: - Rain Impact

    @Test("Heavy rain produces higher impact than drizzle")
    func rainImpactScales() {
        let drizzle = makeSnapshot(condition: .drizzle)
        let rain = makeSnapshot(condition: .rain)
        let heavy = makeSnapshot(condition: .heavyRain)

        let drizzleImpact = WeatherImpactCalculator.calculateImpact(weather: drizzle)
        let rainImpact = WeatherImpactCalculator.calculateImpact(weather: rain)
        let heavyImpact = WeatherImpactCalculator.calculateImpact(weather: heavy)

        #expect(heavyImpact.rainImpactPercent > rainImpact.rainImpactPercent)
        #expect(rainImpact.rainImpactPercent > drizzleImpact.rainImpactPercent)
        #expect(drizzleImpact.rainImpactPercent > 0)
    }

    @Test("Thunderstorm has same impact as heavy rain")
    func thunderstormImpact() {
        let thunderstorm = makeSnapshot(condition: .thunderstorm)
        let heavyRain = makeSnapshot(condition: .heavyRain)

        let tsImpact = WeatherImpactCalculator.calculateImpact(weather: thunderstorm)
        let hrImpact = WeatherImpactCalculator.calculateImpact(weather: heavyRain)

        #expect(tsImpact.rainImpactPercent == hrImpact.rainImpactPercent)
    }

    // MARK: - Wind Impact

    @Test("Strong wind produces higher impact than moderate wind")
    func windImpactScales() {
        let moderate = makeSnapshot(windSpeedKmh: 30) // Above threshold
        let strong = makeSnapshot(windSpeedKmh: 45) // Above strong threshold

        let modImpact = WeatherImpactCalculator.calculateImpact(weather: moderate)
        let strongImpact = WeatherImpactCalculator.calculateImpact(weather: strong)

        #expect(strongImpact.windImpactPercent > modImpact.windImpactPercent)
        #expect(modImpact.windImpactPercent > 0)
    }

    @Test("Below wind threshold produces no impact")
    func belowWindThreshold() {
        let snapshot = makeSnapshot(windSpeedKmh: 15)
        let impact = WeatherImpactCalculator.calculateImpact(weather: snapshot)

        #expect(impact.windImpactPercent == 0)
    }

    // MARK: - Cold Impact

    @Test("Cold weather produces cold impact")
    func coldWeatherImpact() {
        let snapshot = makeSnapshot(temperature: 0)
        let impact = WeatherImpactCalculator.calculateImpact(weather: snapshot)

        #expect(impact.coldImpactPercent > 0)
        // 5 * 0.005 * 100 = 2.5%
        #expect(abs(impact.coldImpactPercent - 2.5) < 0.01)
    }

    @Test("Cold impact is capped at max")
    func coldImpactCapped() {
        let snapshot = makeSnapshot(temperature: -30)
        let impact = WeatherImpactCalculator.calculateImpact(weather: snapshot)

        #expect(impact.coldImpactPercent <= AppConfiguration.WeatherImpact.maxColdImpact * 100)
    }

    // MARK: - Severity

    @Test("Severity matches impact level")
    func severityMatchesImpact() {
        let none = makeSnapshot(temperature: 15, condition: .clear)
        let minor = makeSnapshot(temperature: 20, condition: .drizzle) // ~3%
        let significant = makeSnapshot(temperature: 35, humidity: 0.8, condition: .rain) // >8%

        let noneImpact = WeatherImpactCalculator.calculateImpact(weather: none)
        let minorImpact = WeatherImpactCalculator.calculateImpact(weather: minor)
        let sigImpact = WeatherImpactCalculator.calculateImpact(weather: significant)

        #expect(noneImpact.severity == .none)
        #expect(minorImpact.severity == .minor || minorImpact.severity == .moderate)
        #expect(sigImpact.severity == .significant || sigImpact.severity == .severe)
    }

    // MARK: - Daily Forecast

    @Test("Forecast uses average temperature")
    func forecastUsesAvgTemp() {
        let forecast = makeForecast(highTemp: 35, lowTemp: 25) // avg = 30
        let snapshot = makeSnapshot(temperature: 30, humidity: 0.5) // same temp

        let forecastImpact = WeatherImpactCalculator.calculateImpact(forecast: forecast)
        let snapshotImpact = WeatherImpactCalculator.calculateImpact(weather: snapshot)

        // Heat should be the same since avg matches
        #expect(abs(forecastImpact.heatImpactPercent - snapshotImpact.heatImpactPercent) < 0.1)
    }

    // MARK: - Nutrition Adjustments

    @Test("Hot weather increases hydration and sodium multipliers")
    func hotWeatherNutrition() {
        let snapshot = makeSnapshot(temperature: 30)
        let adj = WeatherImpactCalculator.nutritionAdjustment(weather: snapshot)

        #expect(adj.hydrationMultiplier > 1.0)
        #expect(adj.sodiumMultiplier > 1.0)
        #expect(adj.caloriesMultiplier == 1.0)
        #expect(!adj.notes.isEmpty)
    }

    @Test("Cold weather increases calorie multiplier")
    func coldWeatherNutrition() {
        let snapshot = makeSnapshot(temperature: 0)
        let adj = WeatherImpactCalculator.nutritionAdjustment(weather: snapshot)

        #expect(adj.caloriesMultiplier > 1.0)
        #expect(adj.hydrationMultiplier == 1.0)
        #expect(adj.sodiumMultiplier == 1.0)
    }

    @Test("Mild weather produces no nutrition adjustments")
    func mildWeatherNutrition() {
        let snapshot = makeSnapshot(temperature: 15, condition: .clear)
        let adj = WeatherImpactCalculator.nutritionAdjustment(weather: snapshot)

        #expect(adj.hydrationMultiplier == 1.0)
        #expect(adj.sodiumMultiplier == 1.0)
        #expect(adj.caloriesMultiplier == 1.0)
        #expect(adj.notes.isEmpty)
    }

    @Test("Rainy weather adds moisture protection note")
    func rainyWeatherNutritionNote() {
        let snapshot = makeSnapshot(condition: .rain)
        let adj = WeatherImpactCalculator.nutritionAdjustment(weather: snapshot)

        #expect(adj.notes.contains { $0.contains("moisture") })
    }
}
