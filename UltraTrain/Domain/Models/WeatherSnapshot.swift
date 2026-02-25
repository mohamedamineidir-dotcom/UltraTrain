import Foundation

struct WeatherSnapshot: Equatable, Sendable, Codable {
    var temperatureCelsius: Double
    var apparentTemperatureCelsius: Double
    var humidity: Double
    var windSpeedKmh: Double
    var windDirectionDegrees: Double
    var condition: WeatherConditionType
    var uvIndex: Int
    var precipitationChance: Double
    var symbolName: String
    var capturedAt: Date
    var locationLatitude: Double
    var locationLongitude: Double
}
