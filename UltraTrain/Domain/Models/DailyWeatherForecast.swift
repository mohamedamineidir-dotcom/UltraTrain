import Foundation

struct DailyWeatherForecast: Equatable, Sendable, Codable {
    var date: Date
    var highTemperatureCelsius: Double
    var lowTemperatureCelsius: Double
    var condition: WeatherConditionType
    var precipitationChance: Double
    var windSpeedKmh: Double
    var uvIndex: Int
    var symbolName: String
}
