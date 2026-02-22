import SwiftUI

struct RaceDayWeatherCard: View {
    let forecast: DailyWeatherForecast?
    let raceDate: Date
    let isAvailable: Bool
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
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "cloud.sun.rain.fill")
                .foregroundStyle(Theme.Colors.primary)
                .accessibilityHidden(true)
            Text("Race Day Weather")
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
        if !isAvailable {
            Text("Forecast available 10 days before race day")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        } else if let forecast {
            forecastContent(forecast)
        } else if !isLoading {
            Text("Could not load forecast")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Forecast Content

    private func forecastContent(_ forecast: DailyWeatherForecast) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            temperatureRow(forecast)
            conditionRow(forecast)
            statsRow(forecast)
            tipsSection(forecast)
        }
    }

    // MARK: - Temperature Row

    private func temperatureRow(_ forecast: DailyWeatherForecast) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("High")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text("\(Int(forecast.highTemperatureCelsius.rounded()))°C")
                    .font(.title3.bold())
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("High temperature: \(Int(forecast.highTemperatureCelsius.rounded())) degrees Celsius")
            VStack(alignment: .leading, spacing: 2) {
                Text("Low")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text("\(Int(forecast.lowTemperatureCelsius.rounded()))°C")
                    .font(.title3.bold())
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Low temperature: \(Int(forecast.lowTemperatureCelsius.rounded())) degrees Celsius")
            Spacer()
        }
    }

    // MARK: - Condition Row

    private func conditionRow(_ forecast: DailyWeatherForecast) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: forecast.symbolName)
                .font(.title2)
                .foregroundStyle(Theme.Colors.primary)
                .accessibilityHidden(true)
            Text(forecast.condition.displayName)
                .fontWeight(.medium)
        }
    }

    // MARK: - Stats Row

    private func statsRow(_ forecast: DailyWeatherForecast) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            statColumn(
                value: "\(Int(forecast.precipitationChance * 100))%",
                label: "Rain"
            )
            statColumn(
                value: "\(Int(forecast.windSpeedKmh.rounded())) km/h",
                label: "Wind"
            )
            statColumn(
                value: "\(forecast.uvIndex)",
                label: "UV"
            )
        }
    }

    // MARK: - Tips Section

    @ViewBuilder
    private func tipsSection(_ forecast: DailyWeatherForecast) -> some View {
        let snapshot = WeatherSnapshot(
            temperatureCelsius: forecast.highTemperatureCelsius,
            apparentTemperatureCelsius: forecast.highTemperatureCelsius,
            humidity: 0,
            windSpeedKmh: forecast.windSpeedKmh,
            windDirectionDegrees: 0,
            condition: forecast.condition,
            uvIndex: forecast.uvIndex,
            precipitationChance: forecast.precipitationChance,
            symbolName: forecast.symbolName,
            capturedAt: forecast.date,
            locationLatitude: 0,
            locationLongitude: 0
        )
        let tips = WeatherRunningTips.tips(for: snapshot)
        if !tips.isEmpty {
            Divider()
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                ForEach(tips, id: \.self) { tip in
                    Text("\u{2022} \(tip)")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
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
