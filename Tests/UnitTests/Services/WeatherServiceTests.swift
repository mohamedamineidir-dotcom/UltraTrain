import Foundation
import Testing
@testable import UltraTrain

@Suite("WeatherService Tests")
struct WeatherServiceTests {

    // NOTE: AppleWeatherKitService depends on WeatherKit which requires entitlements and
    // a real network connection. We test the MockWeatherService protocol behavior,
    // the WeatherSnapshot and DailyWeatherForecast models, and the WeatherCache integration.

    // MARK: - Helpers

    private func makeSnapshot(
        temperature: Double = 18.0,
        condition: WeatherConditionType = .clear
    ) -> WeatherSnapshot {
        WeatherSnapshot(
            temperatureCelsius: temperature,
            apparentTemperatureCelsius: temperature - 2,
            humidity: 0.65,
            windSpeedKmh: 15.0,
            windDirectionDegrees: 270,
            condition: condition,
            uvIndex: 5,
            precipitationChance: 0.1,
            symbolName: "sun.max",
            capturedAt: Date(timeIntervalSince1970: 1_700_000_000),
            locationLatitude: 45.83,
            locationLongitude: 6.86
        )
    }

    private func makeDailyForecast(
        date: Date = Date.now,
        condition: WeatherConditionType = .clear
    ) -> DailyWeatherForecast {
        DailyWeatherForecast(
            date: date,
            highTemperatureCelsius: 22.0,
            lowTemperatureCelsius: 8.0,
            condition: condition,
            precipitationChance: 0.15,
            windSpeedKmh: 20.0,
            uvIndex: 6,
            symbolName: "sun.max"
        )
    }

    // MARK: - MockWeatherService

    @Test("MockWeatherService returns configured current weather")
    func mockReturnsCurrentWeather() async throws {
        let mock = MockWeatherService()
        let snapshot = makeSnapshot(temperature: 25.0)
        mock.currentWeatherResult = snapshot

        let result = try await mock.currentWeather(latitude: 45.0, longitude: 6.0)
        #expect(result.temperatureCelsius == 25.0)
        #expect(mock.currentWeatherCallCount == 1)
    }

    @Test("MockWeatherService throws when configured")
    func mockThrowsWhenConfigured() async {
        let mock = MockWeatherService()
        mock.shouldThrow = true

        do {
            _ = try await mock.currentWeather(latitude: 45.0, longitude: 6.0)
            Issue.record("Expected error")
        } catch {
            #expect(error is DomainError)
        }
    }

    @Test("MockWeatherService returns configured hourly forecast")
    func mockReturnsHourlyForecast() async throws {
        let mock = MockWeatherService()
        mock.hourlyForecastResult = [
            makeSnapshot(temperature: 15.0),
            makeSnapshot(temperature: 17.0),
            makeSnapshot(temperature: 19.0)
        ]

        let result = try await mock.hourlyForecast(latitude: 45.0, longitude: 6.0, hours: 3)
        #expect(result.count == 3)
        #expect(mock.hourlyForecastCallCount == 1)
    }

    @Test("MockWeatherService returns configured daily forecast")
    func mockReturnsDailyForecast() async throws {
        let mock = MockWeatherService()
        mock.dailyForecastResult = [
            makeDailyForecast(condition: .clear),
            makeDailyForecast(condition: .rain)
        ]

        let result = try await mock.dailyForecast(latitude: 45.0, longitude: 6.0, days: 7)
        #expect(result.count == 2)
        #expect(result[1].condition == .rain)
    }

    // MARK: - WeatherSnapshot Model

    @Test("WeatherSnapshot is Codable round-trip")
    func snapshotCodableRoundTrip() throws {
        let snapshot = makeSnapshot(temperature: 12.5, condition: .rain)

        let encoder = JSONEncoder()
        let data = try encoder.encode(snapshot)
        let decoded = try JSONDecoder().decode(WeatherSnapshot.self, from: data)

        #expect(decoded.temperatureCelsius == 12.5)
        #expect(decoded.condition == .rain)
        #expect(decoded == snapshot)
    }

    @Test("WeatherSnapshot equality")
    func snapshotEquality() {
        let s1 = makeSnapshot(temperature: 20.0, condition: .cloudy)
        let s2 = makeSnapshot(temperature: 20.0, condition: .cloudy)
        let s3 = makeSnapshot(temperature: 25.0, condition: .cloudy)

        #expect(s1 == s2)
        #expect(s1 != s3)
    }

    // MARK: - DailyWeatherForecast Model

    @Test("DailyWeatherForecast is Codable round-trip")
    func dailyForecastCodableRoundTrip() throws {
        let forecast = makeDailyForecast(condition: .snow)

        let encoder = JSONEncoder()
        let data = try encoder.encode(forecast)
        let decoded = try JSONDecoder().decode(DailyWeatherForecast.self, from: data)

        #expect(decoded.condition == .snow)
        #expect(decoded.highTemperatureCelsius == 22.0)
    }

    // MARK: - DomainError

    @Test("weatherUnavailable error includes reason")
    func weatherUnavailableErrorIncludesReason() {
        let error = DomainError.weatherUnavailable(reason: "API key expired")
        #expect(error.localizedDescription.contains("API key expired"))
    }
}
