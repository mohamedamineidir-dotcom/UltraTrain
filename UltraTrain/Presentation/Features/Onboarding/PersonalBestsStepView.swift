import SwiftUI

struct PersonalBestsStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection
                pbCard(
                    title: "5K",
                    hours: $viewModel.pb5kHours,
                    minutes: $viewModel.pb5kMinutes,
                    seconds: $viewModel.pb5kSeconds,
                    date: $viewModel.pb5kDate,
                    maxHours: 2
                )
                pbCard(
                    title: "10K",
                    hours: $viewModel.pb10kHours,
                    minutes: $viewModel.pb10kMinutes,
                    seconds: $viewModel.pb10kSeconds,
                    date: $viewModel.pb10kDate,
                    maxHours: 3
                )
                pbCard(
                    title: "Half Marathon",
                    hours: $viewModel.pbHalfHours,
                    minutes: $viewModel.pbHalfMinutes,
                    seconds: $viewModel.pbHalfSeconds,
                    date: $viewModel.pbHalfDate,
                    maxHours: 6
                )
                pbCard(
                    title: "Marathon",
                    hours: $viewModel.pbMarathonHours,
                    minutes: $viewModel.pbMarathonMinutes,
                    seconds: $viewModel.pbMarathonSeconds,
                    date: $viewModel.pbMarathonDate,
                    maxHours: 12
                )
                suggestionSection
            }
            .padding()
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Your Race Times")
                .font(.title2.bold())
            Text("Help us calibrate your training paces. Recent results are weighted more heavily.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
    }

    private func pbCard(
        title: String,
        hours: Binding<Int>,
        minutes: Binding<Int>,
        seconds: Binding<Int>,
        date: Binding<Date>,
        maxHours: Int
    ) -> some View {
        PBEntryCard(
            title: title,
            hours: hours,
            minutes: minutes,
            seconds: seconds,
            date: date,
            maxHours: maxHours
        )
    }

    @ViewBuilder
    private var suggestionSection: some View {
        if !hasAnyPB {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Never raced? A 5K time trial will help calibrate your training paces.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .padding()
            .background(Theme.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        }
    }

    private var hasAnyPB: Bool {
        let total5k = viewModel.pb5kHours * 3600 + viewModel.pb5kMinutes * 60 + viewModel.pb5kSeconds
        let total10k = viewModel.pb10kHours * 3600 + viewModel.pb10kMinutes * 60 + viewModel.pb10kSeconds
        let totalHalf = viewModel.pbHalfHours * 3600 + viewModel.pbHalfMinutes * 60 + viewModel.pbHalfSeconds
        let totalMarathon = viewModel.pbMarathonHours * 3600 + viewModel.pbMarathonMinutes * 60 + viewModel.pbMarathonSeconds
        return (total5k + total10k + totalHalf + totalMarathon) > 0
    }
}

private struct PBEntryCard: View {
    let title: String
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    @Binding var date: Date
    let maxHours: Int

    @State private var isExpanded = false

    private var hasTime: Bool {
        (hours * 3600 + minutes * 60 + seconds) > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.label)
                    Spacer()
                    if hasTime {
                        Text(formattedTime)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Theme.Colors.accentColor)
                    } else {
                        Text("Not set")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.tertiaryLabel)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .padding(.vertical, Theme.Spacing.sm)

                VStack(spacing: Theme.Spacing.md) {
                    HStack(spacing: Theme.Spacing.sm) {
                        LabeledIntStepper(label: "Hours", value: $hours, range: 0...maxHours, unit: "h")
                        LabeledIntStepper(label: "Min", value: $minutes, range: 0...59, unit: "m")
                        LabeledIntStepper(label: "Sec", value: $seconds, range: 0...59, unit: "s")
                    }

                    DatePicker(
                        "Date achieved",
                        selection: $date,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }
            }
        }
        .cardStyle()
        .accessibilityIdentifier("onboarding.pb.\(title)")
    }

    private var formattedTime: String {
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
