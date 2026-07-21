import SwiftUI

struct PaywallPlanSelector: View {
    let plans: [SubscriptionPlan]
    @Binding var selectedPlanId: String?

    private var sortedPlans: [SubscriptionPlan] {
        let order: [SubscriptionPeriod] = [.monthly, .yearly]
        return plans.sorted { a, b in
            let ai = order.firstIndex(of: a.period) ?? 99
            let bi = order.firstIndex(of: b.period) ?? 99
            return ai < bi
        }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm + 4) {
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
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            // Left column: plan name + badges
            VStack(alignment: .leading, spacing: 6) {
                Text(plan.period.displayNameLocalized)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let savings = plan.savingsPercent {
                        savingsBadge(savings: savings)
                    }
                }
            }

            Spacer(minLength: Theme.Spacing.sm)

            // Right column: total price hero + small per-week line
            VStack(alignment: .trailing, spacing: 2) {
                Text(plan.displayPrice)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.primary)
                    .fixedSize()
                Text("paywall.perWeek \(plan.displayPricePerWeek)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                // Trail-specific price anchor, yearly only — a concrete,
                // honest comparison lands better than a bare percentage.
                if plan.period == .yearly {
                    Text("paywall.yearlyAnchor")
                        .font(.caption2.italic())
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(minHeight: 72)
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
        .overlay(alignment: .topTrailing) {
            if isRecommended {
                bestValuePill
                    .offset(x: -Theme.Spacing.md, y: -9)
            }
        }
        .shadow(
            color: isSelected ? Theme.Colors.warmCoral.opacity(0.32) : .clear,
            radius: 10, y: 4
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Small corner badge notched into the card's top-right border, away
    /// from the savings pill in the lower-left so the two no longer crowd
    /// each other. Floats above the border so it doesn't change the card's
    /// measured height. Lives on the recommended (yearly) plan only.
    private var bestValuePill: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 7, weight: .bold))
            Text("paywall.bestValue")
                .font(.system(size: 8, weight: .bold))
                .tracking(0.3)
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule().fill(Theme.Gradients.goldPremium)
        )
        .shadow(color: Theme.Colors.goldAccent.opacity(0.4), radius: 4, y: 1)
    }

    /// Gold-gradient savings badge. Loud on purpose because savings %
    /// is the strongest conversion signal we have alongside BEST VALUE.
    private func savingsBadge(savings: Int) -> some View {
        Text(String(localized: "paywall.save \(savings)"))
            .font(.caption2.bold())
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(Theme.Gradients.goldPremium)
            )
    }
}
