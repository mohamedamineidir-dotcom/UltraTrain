import SwiftUI

struct PreRunWeatherCard: View {
    let weather: WeatherSnapshot?
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
            Image(systemName: "cloud.sun.fill")
                .foregroundStyle(Theme.Colors.primary)
                .accessibilityHidden(true)
            Text("Conditions")
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
        if let weather {
            weatherRow(for: weather)
            statsRow(for: weather)
            tipsSection(for: weather)
        } else if !isLoading {
            Text("Checking conditions...")
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

            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(weather.temperatureCelsius.rounded()))°C")
                    .font(.title3.bold())
                Text(weather.condition.displayName)
                    .fontWeight(.medium)
            }

            Spacer()

            Text("Feels like \(Int(weather.apparentTemperatureCelsius.rounded()))°C")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
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

    // MARK: - Tips Section

    @ViewBuilder
    private func tipsSection(for weather: WeatherSnapshot) -> some View {
        let tips = WeatherRunningTips.tips(for: weather)
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
        .accessibilityLabel("\(label), \(value)")
    }
}
