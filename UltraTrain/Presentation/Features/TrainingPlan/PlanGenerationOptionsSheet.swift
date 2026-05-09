import SwiftUI

/// Pre-plan options sheet shown when the athlete clicks "Generate plan".
/// Plan-scoped: the answers can differ per prep cycle, so we ask each
/// time rather than freezing them on the athlete profile.
struct PlanGenerationOptionsSheet: View {

    let targetRace: Race
    let athlete: Athlete
    let planTotalWeeks: Int
    let onGenerate: (PlanGenerationOptions) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var includeFitnessTest: Bool
    @State private var recentFitnessChange: RecentFitnessChange = .none
    @State private var headerPulse = false

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
        _includeFitnessTest = State(initialValue: FitnessTestScheduler.defaultOptIn(
            targetRace: targetRace,
            athlete: athlete,
            planTotalWeeks: planTotalWeeks
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: Theme.Spacing.xl) {
                            header
                            fitnessChangeSection
                            if FitnessTestScheduler.shouldOfferTest(
                                targetRace: targetRace, planTotalWeeks: planTotalWeeks
                            ) {
                                fitnessTestSection
                            }
                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)
                    }

                    bottomBar
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Plan options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel(); dismiss()
                    }
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.Colors.warmCoral.opacity(0.35), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(headerPulse ? 1.06 : 1.0)
                    .blur(radius: 4)

                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Theme.Gradients.warmCoralCTA))
                    .shadow(color: Theme.Colors.warmCoral.opacity(0.5), radius: 12, y: 6)
            }

            VStack(spacing: 6) {
                Text("Tune your plan")
                    .font(.title.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("Two quick checks so your plan starts where you really are.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.md)
            }
        }
        .padding(.top, Theme.Spacing.md)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                headerPulse = true
            }
        }
    }

    // MARK: - Recent fitness change

    private var fitnessChangeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(
                icon: "calendar.badge.clock",
                tint: Theme.Colors.warmCoral,
                title: "How were the last 4 weeks?",
                subtitle: "Injury, illness, or time off changes how aggressively we should ramp."
            )

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(RecentFitnessChange.allCases, id: \.self) { option in
                    fitnessChangeRow(option)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: Theme.Colors.warmCoral)
    }

    private func fitnessChangeRow(_ option: RecentFitnessChange) -> some View {
        let isSelected = recentFitnessChange == option
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                recentFitnessChange = option
            }
        } label: {
            HStack(alignment: .center, spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.Colors.warmCoral : Color.white.opacity(0.07))
                        .frame(width: 36, height: 36)
                    Image(systemName: optionIcon(option))
                        .font(.body.bold())
                        .foregroundStyle(isSelected ? .white : Theme.Colors.secondaryLabel)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(optionTitle(option))
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text(optionEffect(option))
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.Colors.warmCoral)
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(isSelected ? Theme.Colors.warmCoral.opacity(0.13) : Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(
                        isSelected ? Theme.Colors.warmCoral.opacity(0.6) : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Fitness test

    private var fitnessTestSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(
                icon: "speedometer",
                tint: Theme.Colors.primary,
                title: "Mid-prep fitness test",
                subtitle: testTypeBlurb
            )

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    includeFitnessTest.toggle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(includeFitnessTest ? "Scheduled around week 4–5" : "Skip the test")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text(includeFitnessTest ? "Recalibrates your pace targets" : "Plan keeps current pace anchors")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                    Spacer()
                    customToggle
                }
                .padding(.vertical, Theme.Spacing.sm)
                .padding(.horizontal, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if includeFitnessTest {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.primary)
                    Text(testDetailBlurb)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(Theme.Colors.primary.opacity(0.10))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: Theme.Colors.primary)
    }

    private var customToggle: some View {
        ZStack(alignment: includeFitnessTest ? .trailing : .leading) {
            Capsule()
                .fill(includeFitnessTest ? Theme.Colors.primary : Color.white.opacity(0.18))
                .frame(width: 50, height: 30)
            Circle()
                .fill(.white)
                .frame(width: 26, height: 26)
                .padding(.horizontal, 2)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
        }
    }

    // MARK: - Section header

    private func sectionHeader(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(tint))
                .shadow(color: tint.opacity(0.4), radius: 6, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Bottom CTA

    private var bottomBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Theme.Colors.background.opacity(0), Theme.Colors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)

            Button {
                let options = PlanGenerationOptions(
                    includeFitnessTest: includeFitnessTest,
                    recentFitnessChange: recentFitnessChange == .none ? nil : recentFitnessChange
                )
                onGenerate(options)
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Text("Generate plan")
                        .font(.headline.bold())
                    Image(systemName: "sparkles")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(Theme.Gradients.warmCoralCTA)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                .shadow(color: Theme.Colors.warmCoral.opacity(0.4), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.md)
            .background(Theme.Colors.background)
        }
    }

    // MARK: - Option presentation

    private func optionTitle(_ option: RecentFitnessChange) -> String {
        switch option {
        case .none:        "Training as usual"
        case .minor:       "Light setback"
        case .moderate:    "Moderate setback"
        case .significant: "Major setback"
        }
    }

    private func optionEffect(_ option: RecentFitnessChange) -> String {
        switch option {
        case .none:        "Plan ramps as designed."
        case .minor:       "1–2 weeks reduced. Plan eases the first 1–2 weeks."
        case .moderate:    "2–4 weeks off or managed injury. Conservative ramp."
        case .significant: "4+ weeks off. Plan rebuilds gradually from the base."
        }
    }

    private func optionIcon(_ option: RecentFitnessChange) -> String {
        switch option {
        case .none:        "checkmark"
        case .minor:       "leaf.fill"
        case .moderate:    "cross.case.fill"
        case .significant: "arrow.uturn.left"
        }
    }

    private var testTypeBlurb: String {
        let variant = FitnessTestScheduler.pickVariant(targetRace: targetRace, athlete: athlete)
        return "Around week 4–5 we'll schedule a \(variant.displayName.lowercased()) to recalibrate your training paces."
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
            return "4 × 6–8 min uphill at threshold effort, jog-down recovery. Threshold calibration when you don't have a 30-min sustained climb."
        case .uphillRepeats6x4:
            return "5–6 × 4 min uphill at threshold effort. Threshold calibration for shorter hills."
        case .treadmillIncline30Min:
            return "30 min on a treadmill at 8–12% incline at threshold effort. House & Johnston's pick for flat-region athletes."
        }
    }
}
