import SwiftUI

struct DashboardWeatherCard: View {
    let currentWeather: WeatherSnapshot?
    let sessionForecast: WeatherSnapshot?
    let sessionDate: Date?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            headerRow
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("Weather")
                .font(.headline)
            Spacer()
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let currentWeather {
            weatherRow(for: currentWeather)
            statsRow(for: currentWeather)

            if let sessionForecast, let sessionDate {
                Divider()
                sessionForecastSection(forecast: sessionForecast, date: sessionDate)
            }
        } else if !isLoading {
            Text("Location needed for weather data")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Weather Row

    private func weatherRow(for weather: WeatherSnapshot) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: weather.symbolName)
                .font(.title2)
                .foregroundStyle(Theme.Colors.primary)
                .accessibilityHidden(true)

            Text(weather.condition.displayName)
                .fontWeight(.medium)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(weather.temperatureCelsius.rounded()))°C")
                    .font(.title3.bold())
                Text("Feels like \(Int(weather.apparentTemperatureCelsius.rounded()))°C")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(weather.condition.displayName), \(Int(weather.temperatureCelsius.rounded())) degrees, feels like \(Int(weather.apparentTemperatureCelsius.rounded())) degrees")
    }

    // MARK: - Stats Row

    private func statsRow(for weather: WeatherSnapshot) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            statColumn(
                value: "\(Int(weather.windSpeedKmh.rounded())) km/h",
                label: "Wind"
            )
            statColumn(
                value: "\(Int(weather.precipitationChance * 100))%",
                label: "Rain"
            )
            statColumn(
                value: "\(weather.uvIndex)",
                label: "UV"
            )
        }
    }

    // MARK: - Session Forecast

    private func sessionForecastSection(
        forecast: WeatherSnapshot,
        date: Date
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("For your next session")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            weatherRow(for: forecast)
            statsRow(for: forecast)
        }
    }

    // MARK: - Stat Column

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}
