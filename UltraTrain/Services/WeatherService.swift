import CoreLocation
import Foundation
import os
import WeatherKit

final class AppleWeatherKitService: WeatherServiceProtocol, @unchecked Sendable {

    private let weatherService = WeatherKit.WeatherService.shared
    private let cache = WeatherCache()

    // MARK: - Current Weather

    func currentWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot {
        let cacheKey = WeatherCache.Key(lat: latitude, lon: longitude, type: .current)
        if let cached: WeatherSnapshot = await cache.get(for: cacheKey) {
            return cached
        }

        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let weather = try await weatherService.weather(for: location, including: .current)
            let snapshot = mapCurrentWeather(weather, latitude: latitude, longitude: longitude)
            await cache.set(snapshot, for: cacheKey, ttl: AppConfiguration.Weather.currentCacheTTL)
            return snapshot
        } catch {
            Logger.weather.error("WeatherKit current weather failed: \(error)")
            throw DomainError.weatherUnavailable(reason: error.localizedDescription)
        }
    }

    // MARK: - Hourly Forecast

    func hourlyForecast(latitude: Double, longitude: Double, hours: Int) async throws -> [WeatherSnapshot] {
        let cacheKey = WeatherCache.Key(lat: latitude, lon: longitude, type: .hourly)
        if let cached: [WeatherSnapshot] = await cache.get(for: cacheKey) {
            return Array(cached.prefix(hours))
        }

        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let forecast = try await weatherService.weather(for: location, including: .hourly)
            let snapshots = forecast.prefix(hours).map {
                mapHourWeather($0, latitude: latitude, longitude: longitude)
            }
            await cache.set(snapshots, for: cacheKey, ttl: AppConfiguration.Weather.hourlyCacheTTL)
            return snapshots
        } catch {
            Logger.weather.error("WeatherKit hourly forecast failed: \(error)")
            throw DomainError.weatherUnavailable(reason: error.localizedDescription)
        }
    }

    // MARK: - Daily Forecast

    func dailyForecast(latitude: Double, longitude: Double, days: Int) async throws -> [DailyWeatherForecast] {
        let cacheKey = WeatherCache.Key(lat: latitude, lon: longitude, type: .daily)
        if let cached: [DailyWeatherForecast] = await cache.get(for: cacheKey) {
            return Array(cached.prefix(days))
        }

        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let forecast = try await weatherService.weather(for: location, including: .daily)
            let days = forecast.prefix(days).map { mapDayWeather($0) }
            await cache.set(days, for: cacheKey, ttl: AppConfiguration.Weather.dailyCacheTTL)
            return days
        } catch {
            Logger.weather.error("WeatherKit daily forecast failed: \(error)")
            throw DomainError.weatherUnavailable(reason: error.localizedDescription)
        }
    }

    // MARK: - Mapping

    private func mapCurrentWeather(
        _ weather: CurrentWeather,
        latitude: Double,
        longitude: Double
    ) -> WeatherSnapshot {
        WeatherSnapshot(
            temperatureCelsius: weather.temperature.converted(to: .celsius).value,
            apparentTemperatureCelsius: weather.apparentTemperature.converted(to: .celsius).value,
            humidity: weather.humidity,
            windSpeedKmh: weather.wind.speed.converted(to: .kilometersPerHour).value,
            windDirectionDegrees: weather.wind.direction.converted(to: .degrees).value,
            condition: mapCondition(weather.condition),
            uvIndex: weather.uvIndex.value,
            precipitationChance: 0,
            symbolName: weather.symbolName,
            capturedAt: weather.date,
            locationLatitude: latitude,
            locationLongitude: longitude
        )
    }

    private func mapHourWeather(
        _ weather: HourWeather,
        latitude: Double,
        longitude: Double
    ) -> WeatherSnapshot {
        WeatherSnapshot(
            temperatureCelsius: weather.temperature.converted(to: .celsius).value,
            apparentTemperatureCelsius: weather.apparentTemperature.converted(to: .celsius).value,
            humidity: weather.humidity,
            windSpeedKmh: weather.wind.speed.converted(to: .kilometersPerHour).value,
            windDirectionDegrees: weather.wind.direction.converted(to: .degrees).value,
            condition: mapCondition(weather.condition),
            uvIndex: weather.uvIndex.value,
            precipitationChance: weather.precipitationChance,
            symbolName: weather.symbolName,
            capturedAt: weather.date,
            locationLatitude: latitude,
            locationLongitude: longitude
        )
    }

    private func mapDayWeather(_ weather: DayWeather) -> DailyWeatherForecast {
        DailyWeatherForecast(
            date: weather.date,
            highTemperatureCelsius: weather.highTemperature.converted(to: .celsius).value,
            lowTemperatureCelsius: weather.lowTemperature.converted(to: .celsius).value,
            condition: mapCondition(weather.condition),
            precipitationChance: weather.precipitationChance,
            windSpeedKmh: weather.wind.speed.converted(to: .kilometersPerHour).value,
            uvIndex: weather.uvIndex.value,
            symbolName: weather.symbolName
        )
    }

    private func mapCondition(_ condition: WeatherKit.WeatherCondition) -> WeatherConditionType {
        switch condition {
        case .clear, .mostlyClear: .clear
        case .partlyCloudy: .partlyCloudy
        case .cloudy, .mostlyCloudy: .cloudy
        case .rain: .rain
        case .heavyRain: .heavyRain
        case .drizzle: .drizzle
        case .snow, .heavySnow, .flurries: .snow
        case .thunderstorms, .strongStorms, .isolatedThunderstorms: .thunderstorm
        case .foggy, .haze, .smoky: .fog
        case .windy, .breezy: .windy
        case .hot: .hot
        case .frigid, .freezingRain, .freezingDrizzle: .frigid
        default: .unknown
        }
    }
}
