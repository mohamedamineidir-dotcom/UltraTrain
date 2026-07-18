import Foundation
@testable import UltraTrain

final class MockWeatherService: WeatherServiceProtocol, @unchecked Sendable {
    var currentWeatherResult: WeatherSnapshot?
    var hourlyForecastResult: [WeatherSnapshot] = []
    var dailyForecastResult: [DailyWeatherForecast] = []
    var shouldThrow = false
    var currentWeatherCallCount = 0
    var hourlyForecastCallCount = 0
    var dailyForecastCallCount = 0

    func currentWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot {
        currentWeatherCallCount += 1
        if shouldThrow { throw DomainError.weatherUnavailable(reason: "Mock error") }
        guard let result = currentWeatherResult else {
            throw DomainError.weatherUnavailable(reason: "No mock data")
        }
        return result
    }

    func hourlyForecast(latitude: Double, longitude: Double, hours: Int) async throws -> [WeatherSnapshot] {
        hourlyForecastCallCount += 1
        if shouldThrow { throw DomainError.weatherUnavailable(reason: "Mock error") }
        return hourlyForecastResult
    }

    func dailyForecast(latitude: Double, longitude: Double, days: Int) async throws -> [DailyWeatherForecast] {
        dailyForecastCallCount += 1
        if shouldThrow { throw DomainError.weatherUnavailable(reason: "Mock error") }
        return dailyForecastResult
    }
}
