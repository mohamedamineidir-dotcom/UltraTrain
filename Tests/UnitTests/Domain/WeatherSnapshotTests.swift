import Foundation
import Testing
@testable import UltraTrain

@Suite("WeatherSnapshot & Running Tips Tests")
struct WeatherSnapshotTests {

    private func makeSnapshot(
        temperatureCelsius: Double = 20,
        apparentTemperatureCelsius: Double = 20,
        humidity: Double = 0.5,
        windSpeedKmh: Double = 10,
        precipitationChance: Double = 0.1,
        uvIndex: Int = 3,
        condition: WeatherConditionType = .clear
    ) -> WeatherSnapshot {
        WeatherSnapshot(
            temperatureCelsius: temperatureCelsius,
            apparentTemperatureCelsius: apparentTemperatureCelsius,
            humidity: humidity,
            windSpeedKmh: windSpeedKmh,
            windDirectionDegrees: 180,
            condition: condition,
            uvIndex: uvIndex,
            precipitationChance: precipitationChance,
            symbolName: "sun.max.fill",
            capturedAt: .now,
            locationLatitude: 45.0,
            locationLongitude: 6.0
        )
    }

    // MARK: - WeatherConditionType Display Names

    @Test("All condition types have a display name")
    func allConditionTypesHaveDisplayName() {
        for condition in WeatherConditionType.allCases {
            #expect(!condition.displayName.isEmpty)
        }
    }

    @Test("Clear condition display name is correct")
    func clearDisplayName() {
        #expect(WeatherConditionType.clear.displayName == "Clear")
    }

    @Test("Partly cloudy display name is correct")
    func partlyCloudyDisplayName() {
        #expect(WeatherConditionType.partlyCloudy.displayName == "Partly Cloudy")
    }

    @Test("Heavy rain display name is correct")
    func heavyRainDisplayName() {
        #expect(WeatherConditionType.heavyRain.displayName == "Heavy Rain")
    }

    // MARK: - Running Tips: Temperature

    @Test("Hot conditions trigger hydration tip")
    func hotConditionsTip() {
        let snapshot = makeSnapshot(temperatureCelsius: 32)
        let tips = WeatherRunningTips.tips(for: snapshot)
        #expect(tips.contains { $0.contains("Hot conditions") })
    }

    @Test("Warm conditions trigger extra water tip")
    func warmConditionsTip() {
        let snapshot = makeSnapshot(temperatureCelsius: 27)
        let tips = WeatherRunningTips.tips(for: snapshot)
        #expect(tips.contains { $0.contains("Warm conditions") })
    }

    @Test("Freezing conditions trigger thermal layers tip")
    func freezingConditionsTip() {
        let snapshot = makeSnapshot(temperatureCelsius: -2)
        let tips = WeatherRunningTips.tips(for: snapshot)
        #expect(tips.contains { $0.contains("Freezing conditions") })
    }

    @Test("Cold conditions trigger layering tip")
    func coldConditionsTip() {
        let snapshot = makeSnapshot(temperatureCelsius: 3)
        let tips = WeatherRunningTips.tips(for: snapshot)
        #expect(tips.contains { $0.contains("Cold conditions") })
    }

    @Test("Moderate temperature produces no temperature tips")
    func moderateTemperatureNoTips() {
        let snapshot = makeSnapshot(temperatureCelsius: 15)
        let tips = WeatherRunningTips.tips(for: snapshot)
        let tempTips = tips.filter { $0.contains("Hot") || $0.contains("Warm") || $0.contains("Cold") || $0.contains("Freezing") }
        #expect(tempTips.isEmpty)
    }

    // MARK: - Running Tips: Rain

    @Test("High precipitation chance triggers waterproof tip")
    func highRainTip() {
        let snapshot = makeSnapshot(precipitationChance: 0.8)
        let tips = WeatherRunningTips.tips(for: snapshot)
        #expect(tips.contains { $0.contains("Rain likely") })
    }

    @Test("Moderate precipitation chance triggers lightweight waterproof tip")
    func moderateRainTip() {
        let snapshot = makeSnapshot(precipitationChance: 0.5)
        let tips = WeatherRunningTips.tips(for: snapshot)
        #expect(tips.contains { $0.contains("Chance of rain") })
    }

    @Test("Low precipitation chance produces no rain tips")
    func lowRainNoTips() {
        let snapshot = makeSnapshot(precipitationChance: 0.1)
        let tips = WeatherRunningTips.tips(for: snapshot)
        let rainTips = tips.filter { $0.contains("rain") || $0.contains("Rain") }
        #expect(rainTips.isEmpty)
    }

    // MARK: - Running Tips: Wind

    @Test("Very strong wind triggers caution tip")
    func veryStrongWindTip() {
        let snapshot = makeSnapshot(windSpeedKmh: 45)
        let tips = WeatherRunningTips.tips(for: snapshot)
        #expect(tips.contains { $0.contains("Very strong wind") })
    }

    @Test("Moderate wind triggers effort warning")
    func moderateWindTip() {
        let snapshot = makeSnapshot(windSpeedKmh: 30)
        let tips = WeatherRunningTips.tips(for: snapshot)
        #expect(tips.contains { $0.contains("Windy conditions") })
    }

    // MARK: - Running Tips: UV

    @Test("Very high UV triggers strong sun protection tip")
    func veryHighUvTip() {
        let snapshot = makeSnapshot(uvIndex: 9)
        let tips = WeatherRunningTips.tips(for: snapshot)
        #expect(tips.contains { $0.contains("Very high UV") })
    }

    @Test("High UV triggers sunscreen tip")
    func highUvTip() {
        let snapshot = makeSnapshot(uvIndex: 6)
        let tips = WeatherRunningTips.tips(for: snapshot)
        #expect(tips.contains { $0.contains("High UV") })
    }

    // MARK: - Running Tips: Combined

    @Test("Perfect conditions produce no tips")
    func perfectConditionsNoTips() {
        let snapshot = makeSnapshot(
            temperatureCelsius: 15,
            windSpeedKmh: 5,
            precipitationChance: 0.05,
            uvIndex: 2
        )
        let tips = WeatherRunningTips.tips(for: snapshot)
        #expect(tips.isEmpty)
    }

    @Test("Harsh conditions produce multiple tips")
    func harshConditionsMultipleTips() {
        let snapshot = makeSnapshot(
            temperatureCelsius: 35,
            windSpeedKmh: 50,
            precipitationChance: 0.9,
            uvIndex: 10
        )
        let tips = WeatherRunningTips.tips(for: snapshot)
        #expect(tips.count >= 3)
    }
}
