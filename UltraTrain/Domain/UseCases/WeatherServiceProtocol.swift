import Foundation

protocol WeatherServiceProtocol: Sendable {
    func currentWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot
    func hourlyForecast(latitude: Double, longitude: Double, hours: Int) async throws -> [WeatherSnapshot]
    func dailyForecast(latitude: Double, longitude: Double, days: Int) async throws -> [DailyWeatherForecast]
}
