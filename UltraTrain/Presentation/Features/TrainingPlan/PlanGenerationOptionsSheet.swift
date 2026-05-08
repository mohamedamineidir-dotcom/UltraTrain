import SwiftUI

/// Pre-plan options sheet shown when the athlete clicks "Generate plan".
/// Mirrors the nutrition-plan onboarding pattern but compact (3 small
/// sections on one screen rather than a stepped flow). Plan-scoped: the
/// answers can differ per prep cycle, so we ask each time rather than
/// freezing them on the athlete profile.
struct PlanGenerationOptionsSheet: View {

    let targetRace: Race
    let athlete: Athlete
    let planTotalWeeks: Int
    let onGenerate: (PlanGenerationOptions) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var includeFitnessTest: Bool
    @State private var recentFitnessChange: RecentFitnessChange = .none

    init(
        targetRace: Race,
        athlete: Athlete,
        planTotalWeeks: Int,
        onGenerate: @escaping (PlanGenerationOptions) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.targetRace = targetRace
        self.athlete = athlete
        self.planTotalWeeks = planTotalWeeks
        self.onGenerate = onGenerate
        self.onCancel = onCancel
        // Smart default for fitness-test toggle.
        _includeFitnessTest = State(initialValue: FitnessTestScheduler.defaultOptIn(
            targetRace: targetRace,
            athlete: athlete,
            planTotalWeeks: planTotalWeeks
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    header
                    fitnessChangeSection
                    if FitnessTestScheduler.shouldOfferTest(
                        targetRace: targetRace, planTotalWeeks: planTotalWeeks
                    ) {
                        fitnessTestSection
                    }
                    Spacer(minLength: Theme.Spacing.xl)
                }
                .padding(Theme.Spacing.lg)
            }
            .navigationTitle("Plan options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel(); dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        let options = PlanGenerationOptions(
                            includeFitnessTest: includeFitnessTest,
                            recentFitnessChange: recentFitnessChange == .none ? nil : recentFitnessChange
                        )
                        onGenerate(options)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 28))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Theme.Gradients.warmCoralCTA))
                .shadow(color: Theme.Colors.warmCoral.opacity(0.3), radius: 8, y: 4)

            Text("Quick check before we build")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text("Two short questions to tune the plan to your situation right now.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Recent fitness change

    private var fitnessChangeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Anything affected your training in the last 4 weeks?")
                .font(.headline)
            Text("Injury, illness, or extended time off changes the volume we can prescribe in early weeks.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(RecentFitnessChange.allCases, id: \.self) { option in
                    fitnessChangeRow(option)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    private func fitnessChangeRow(_ option: RecentFitnessChange) -> some View {
        Button {
            recentFitnessChange = option
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: recentFitnessChange == option ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(recentFitnessChange == option ? Theme.Colors.warmCoral : Theme.Colors.secondaryLabel)
                Text(option.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(
                recentFitnessChange == option
                    ? AnyShapeStyle(Theme.Colors.warmCoral.opacity(0.10))
                    : AnyShapeStyle(Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Fitness test

    private var fitnessTestSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Toggle(isOn: $includeFitnessTest) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Include a mid-prep fitness test")
                        .font(.headline)
                    Text(testTypeBlurb)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Theme.Colors.warmCoral)

            if includeFitnessTest {
                Text(testDetailBlurb)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .padding(Theme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                            .fill(Theme.Colors.warmCoral.opacity(0.08))
                    )
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    private var testTypeBlurb: String {
        let variant = FitnessTestScheduler.pickVariant(targetRace: targetRace, athlete: athlete)
        return "Around week 4-5 we'll schedule a \(variant.displayName.lowercased()) to recalibrate your training paces."
    }

    private var testDetailBlurb: String {
        switch FitnessTestScheduler.pickVariant(targetRace: targetRace, athlete: athlete) {
        case .vmaFlat6Min:
            return "6 min all-out on flat (track ideal). Distance covered ÷ 100 = your VMA. Re-anchors all training paces."
        case .fiveKTT:
            return "5K time trial all-out. Result re-anchors your pace targets via Daniels VDOT."
        case .uphillSustained30Min:
            return "30 min uphill at threshold effort on a sustained climb. Calibrates your trail threshold zones."
        case .uphillRepeats4x8:
            return "4 × 6-8 min uphill at threshold effort, jog-down recovery. Threshold calibration when you don't have a 30-min sustained climb."
        case .uphillRepeats6x4:
            return "5-6 × 4 min uphill at threshold effort. Threshold calibration for shorter hills."
        case .treadmillIncline30Min:
            return "30 min on a treadmill at 8-12% incline at threshold effort. House & Johnston's pick for flat-region athletes."
        }
    }
}
