import SwiftUI

struct WeeklyReviewSheet: View {
    @Environment(\.unitPreference) private var units
    @Bindable var viewModel: WeeklyReviewViewModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            switch viewModel.phase {
            case .question:
                questionView
            case .sessionPicker:
                sessionPickerView
            case .loading:
                PlanUpdateLoadingView(
                    steps: loadingSteps,
                    onComplete: {
                        viewModel.onLoadingComplete()
                        onDismiss()
                    }
                )
            case .done:
                EmptyView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Question View

extension WeeklyReviewSheet {

    private var questionView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            headerIcon
            titleSection
            optionButtons
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.Colors.accentColor.opacity(0.25), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Theme.Colors.accentColor)
                .shadow(color: Theme.Colors.accentColor.opacity(0.3), radius: 12)
        }
    }

    private var titleSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("How was last week?")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Week \(viewModel.previousWeekNumber) had \(viewModel.nonRestSessions.count) planned sessions with no recorded runs.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
    }

    private var optionButtons: some View {
        VStack(spacing: Theme.Spacing.md) {
            reviewOptionButton(
                icon: "checkmark.circle.fill",
                title: "I completed them all",
                subtitle: "I just forgot to validate in the app",
                color: Theme.Colors.success
            ) {
                Task { await viewModel.handleAllCompleted() }
            }

            reviewOptionButton(
                icon: "xmark.circle.fill",
                title: "I didn't do any",
                subtitle: "Skip them and adapt my plan",
                color: Theme.Colors.danger
            ) {
                Task { await viewModel.handleNoneCompleted() }
            }

            reviewOptionButton(
                icon: "checklist",
                title: "I missed some sessions",
                subtitle: "Let me pick which ones I did",
                color: Theme.Colors.warning
            ) {
                viewModel.showSessionPicker()
            }
        }
    }

    private func reviewOptionButton(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .padding(Theme.Spacing.md)
            .futuristicGlassStyle()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Session Picker View

extension WeeklyReviewSheet {

    private var sessionPickerView: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    Text("Which sessions did you complete?")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Theme.Spacing.md)

                    ForEach(viewModel.nonRestSessions) { session in
                        sessionRow(session)
                    }

                    confirmButton
                        .padding(.top, Theme.Spacing.md)
                }
                .padding(.vertical, Theme.Spacing.md)
            }
            .navigationTitle("Select Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { viewModel.phase = .question }
                }
            }
        }
    }

    private func sessionRow(_ session: TrainingSession) -> some View {
        let isSelected = viewModel.selectedCompletedIds.contains(session.id)
        return Button {
            if isSelected {
                viewModel.selectedCompletedIds.remove(session.id)
            } else {
                viewModel.selectedCompletedIds.insert(session.id)
            }
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.Colors.success : Theme.Colors.secondaryLabel)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text(session.type.rawValue.capitalized)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        if session.isKeySession {
                            Text("KEY")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.warning.opacity(0.2))
                                .foregroundStyle(Theme.Colors.warning)
                                .clipShape(Capsule())
                        }
                    }
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(session.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        Text("•")
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        Text(UnitFormatter.formatDistance(session.plannedDistanceKm, unit: units))
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
                Spacer()
            }
            .padding(Theme.Spacing.md)
            .glassCardStyle(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.md)
    }

    private var confirmButton: some View {
        Button {
            Task { await viewModel.handlePartialCompleted() }
        } label: {
            Text("Confirm")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Gradients.warmCoralCTA)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.selectedCompletedIds.isEmpty)
        .opacity(viewModel.selectedCompletedIds.isEmpty ? 0.5 : 1)
        .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - Loading Steps

extension WeeklyReviewSheet {

    private var loadingSteps: [(icon: String, title: String, subtitle: String)] {
        [
            ("checkmark.circle", "Recording your week", "Marking sessions complete or skipped"),
            ("chart.line.uptrend.xyaxis", "Analyzing training load", "Adjusting upcoming intensity"),
            ("calendar.badge.clock", "Optimizing your plan", "Fine-tuning next weeks")
        ]
    }
}
