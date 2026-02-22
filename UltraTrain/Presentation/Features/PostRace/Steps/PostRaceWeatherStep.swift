import SwiftUI

struct PostRaceWeatherStep: View {
    @Bindable var viewModel: PostRaceWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            assessmentSection
            notesSection
        }
    }

    // MARK: - Assessment

    private var assessmentSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Weather Impact on Your Race?")
                .font(.headline)

            VStack(spacing: Theme.Spacing.sm) {
                weatherButton(
                    impact: .noImpact,
                    icon: "sun.max.fill",
                    title: "No Impact",
                    subtitle: "Weather was ideal"
                )
                weatherButton(
                    impact: .minor,
                    icon: "cloud.sun.fill",
                    title: "Minor",
                    subtitle: "Slightly challenging but manageable"
                )
                weatherButton(
                    impact: .significant,
                    icon: "cloud.rain.fill",
                    title: "Significant",
                    subtitle: "Weather affected performance"
                )
                weatherButton(
                    impact: .severe,
                    icon: "cloud.bolt.rain.fill",
                    title: "Severe",
                    subtitle: "Extreme conditions, major impact"
                )
            }
        }
    }

    private func weatherButton(
        impact: WeatherImpactLevel,
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {
        let isSelected = viewModel.weatherImpact == impact
        return Button {
            viewModel.weatherImpact = impact
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 32)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Colors.primary)
                        .accessibilityHidden(true)
                }
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(
                        isSelected
                            ? Theme.Colors.primary.opacity(0.15)
                            : Theme.Colors.secondaryBackground
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .stroke(
                        isSelected ? Theme.Colors.primary : .clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("weather_\(impact.rawValue)")
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Weather Notes (Optional)")
                .font(.headline)
            TextField(
                "Temperature, wind, rain details?",
                text: $viewModel.weatherNotes,
                axis: .vertical
            )
            .lineLimit(2...4)
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel("Weather notes")
            .accessibilityHint("Optionally describe weather conditions during the race")
        }
    }
}
