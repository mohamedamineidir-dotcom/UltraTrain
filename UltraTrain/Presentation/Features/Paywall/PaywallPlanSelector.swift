import SwiftUI

struct PaywallPlanSelector: View {
    let plans: [SubscriptionPlan]
    @Binding var selectedPlanId: String?

    private var sortedPlans: [SubscriptionPlan] {
        let order: [SubscriptionPeriod] = [.monthly, .quarterly, .yearly]
        return plans.sorted { a, b in
            let ai = order.firstIndex(of: a.period) ?? 99
            let bi = order.firstIndex(of: b.period) ?? 99
            return ai < bi
        }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm + 2) {
            ForEach(sortedPlans) { plan in
                PaywallPlanCard(
                    plan: plan,
                    isSelected: selectedPlanId == plan.id,
                    isRecommended: plan.period == .yearly
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPlanId = plan.id
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
}

// MARK: - Plan Card

struct PaywallPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let isRecommended: Bool

    var body: some View {
        VStack(spacing: 0) {
            if isRecommended {
                bestValuePill
            }

            HStack(spacing: Theme.Spacing.md) {
                // Left: plan name + small total
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(plan.period.displayNameLocalized)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if let savings = plan.savingsPercent {
                            savingsBadge(savings: savings)
                        }
                    }

                    Text(plan.displayPrice)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: Theme.Spacing.sm)

                // Right: per-week price as the hero number
                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.displayPricePerWeek)
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(.primary)
                        .fixedSize()
                    Text("paywall.perWeekLabel")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(.ultraThinMaterial)
                .opacity(isSelected ? 1.0 : 0.55)
        )
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Color.primary.opacity(isSelected ? 0.08 : 0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(
                    isSelected ? Theme.Colors.warmCoral : Color.primary.opacity(0.12),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(
            color: isSelected ? Theme.Colors.warmCoral.opacity(0.32) : .clear,
            radius: 10, y: 4
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// "BEST VALUE" pill that sits flush at the top of the recommended
    /// card so the eye lands on it before reading the row. Gold gradient
    /// keeps the premium feel without competing with the coral selection
    /// border.
    private var bestValuePill: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption2.bold())
            Text("paywall.bestValue")
                .font(.caption2.bold())
                .tracking(0.6)
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(Theme.Gradients.goldPremium)
        )
        .offset(y: 10)
        .zIndex(1)
        .padding(.top, -10)
    }

    /// Compact "Save N%" badge inline with the plan name. Uses a tinted
    /// fill rather than the loud gold gradient so it doesn't fight the
    /// BEST VALUE pill on the yearly card.
    private func savingsBadge(savings: Int) -> some View {
        Text(String(localized: "paywall.save \(savings)"))
            .font(.caption2.bold())
            .foregroundStyle(Theme.Colors.success)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(Theme.Colors.success.opacity(0.16))
            )
    }
}
