import Foundation

struct WeatherSnapshot: Equatable, Sendable {
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

enum WeatherConditionType: String, CaseIterable, Sendable {
    case clear
    case partlyCloudy
    case cloudy
    case rain
    case heavyRain
    case drizzle
    case snow
    case thunderstorm
    case fog
    case windy
    case hot
    case frigid
    case unknown

    var displayName: String {
        switch self {
        case .clear: "Clear"
        case .partlyCloudy: "Partly Cloudy"
        case .cloudy: "Cloudy"
        case .rain: "Rain"
        case .heavyRain: "Heavy Rain"
        case .drizzle: "Drizzle"
        case .snow: "Snow"
        case .thunderstorm: "Thunderstorm"
        case .fog: "Fog"
        case .windy: "Windy"
        case .hot: "Hot"
        case .frigid: "Frigid"
        case .unknown: "Unknown"
        }
    }
}
