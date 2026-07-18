import Foundation
import Testing
@testable import UltraTrain

@Suite("WeatherSnapshot Tests")
struct WeatherSnapshotTests {

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
}
