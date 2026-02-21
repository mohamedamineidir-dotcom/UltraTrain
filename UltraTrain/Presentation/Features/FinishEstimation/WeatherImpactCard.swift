import SwiftUI

struct WeatherImpactCard: View {
    let impact: WeatherImpactCalculator.WeatherImpact
    let snapshot: WeatherSnapshot?
    let forecast: DailyWeatherForecast?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            header
            conditionRow
            if impact.severity != .none {
                impactBreakdown
            }
            totalImpactBadge
        }
        .cardStyle()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "cloud.sun.fill")
                .foregroundStyle(severityColor)
                .accessibilityHidden(true)
            Text("Weather Impact")
                .font(.headline)
            Spacer()
            Text(impact.severity.rawValue.capitalized)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.xs)
                .padding(.vertical, 2)
                .background(severityColor)
                .clipShape(Capsule())
        }
    }

    // MARK: - Condition

    private var conditionRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            if let snapshot {
                Label(
                    String(format: "%.0f\u{00B0}C", snapshot.temperatureCelsius),
                    systemImage: "thermometer.medium"
                )
                Label(
                    snapshot.condition.displayName,
                    systemImage: snapshot.symbolName
                )
                Label(
                    String(format: "%.0f km/h", snapshot.windSpeedKmh),
                    systemImage: "wind"
                )
            } else if let forecast {
                Label(
                    String(format: "%.0f-%.0f\u{00B0}C", forecast.lowTemperatureCelsius, forecast.highTemperatureCelsius),
                    systemImage: "thermometer.medium"
                )
                Label(
                    forecast.condition.displayName,
                    systemImage: forecast.symbolName
                )
                Label(
                    String(format: "%.0f km/h", forecast.windSpeedKmh),
                    systemImage: "wind"
                )
            }
        }
        .font(.caption)
        .foregroundStyle(Theme.Colors.secondaryLabel)
    }

    // MARK: - Breakdown

    private var impactBreakdown: some View {
        VStack(alignment: .leading, spacing: 4) {
            if impact.heatImpactPercent > 0 {
                factorRow("Heat", percent: impact.heatImpactPercent, icon: "sun.max.fill")
            }
            if impact.humidityCompoundPercent > 0 {
                factorRow("Humidity", percent: impact.humidityCompoundPercent, icon: "humidity.fill")
            }
            if impact.rainImpactPercent > 0 {
                factorRow("Rain", percent: impact.rainImpactPercent, icon: "cloud.rain.fill")
            }
            if impact.windImpactPercent > 0 {
                factorRow("Wind", percent: impact.windImpactPercent, icon: "wind")
            }
            if impact.coldImpactPercent > 0 {
                factorRow("Cold", percent: impact.coldImpactPercent, icon: "snowflake")
            }
        }
    }

    private func factorRow(_ label: String, percent: Double, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            Text(label)
                .font(.caption)
            Spacer()
            Text(String(format: "+%.1f%%", percent))
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(Theme.Colors.warning)
        }
    }

    // MARK: - Total Badge

    private var totalImpactBadge: some View {
        let totalPercent = (impact.multiplier - 1.0) * 100
        return HStack {
            Text("Total Impact")
                .font(.caption.bold())
            Spacer()
            Text(totalPercent > 0 ? String(format: "+%.1f%%", totalPercent) : "None")
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(totalPercent > 0 ? severityColor : Theme.Colors.success)
        }
        .padding(.top, Theme.Spacing.xs)
    }

    // MARK: - Helpers

    private var severityColor: Color {
        switch impact.severity {
        case .none: Theme.Colors.success
        case .minor: Theme.Colors.primary
        case .moderate: Theme.Colors.warning
        case .significant, .severe: Theme.Colors.danger
        }
    }
}
