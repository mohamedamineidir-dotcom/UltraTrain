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
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(sortedPlans) { plan in
                PaywallPlanCard(
                    plan: plan,
                    isSelected: selectedPlanId == plan.id
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

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Left: plan info
            VStack(alignment: .leading, spacing: 4) {
                // Row 1: Plan name
                HStack(spacing: 6) {
                    Text(plan.period.displayNameLocalized)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if plan.trialDays != nil {
                        badge(
                            text: String(localized: "paywall.freeWeek"),
                            foreground: Theme.Colors.warmCoral,
                            background: Theme.Colors.warmCoral.opacity(0.12)
                        )
                    }
                }

                // Row 2: Save badge + per-week price
                HStack(spacing: 6) {
                    if let savings = plan.savingsPercent {
                        badge(
                            text: String(localized: "paywall.save \(savings)"),
                            foreground: .black,
                            background: nil,
                            gradient: Theme.Gradients.goldPremium
                        )
                    }

                    Text("paywall.perWeek \(plan.displayPricePerWeek)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: Theme.Spacing.sm)

            // Right: total price
            Text(plan.displayPrice)
                .font(.title3.bold())
                .foregroundStyle(.primary)
                .fixedSize()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(.ultraThinMaterial)
                .opacity(isSelected ? 1.0 : 0.6)
        )
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Color.primary.opacity(isSelected ? 0.1 : 0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(
                    isSelected ? Theme.Colors.warmCoral : Color.primary.opacity(0.12),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(color: isSelected ? Theme.Colors.warmCoral.opacity(0.3) : .clear, radius: 8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func badge(
        text: String,
        foreground: Color,
        background: Color? = nil,
        gradient: LinearGradient? = nil
    ) -> some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(foreground)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background {
                if let gradient {
                    Capsule().fill(gradient)
                } else if let bg = background {
                    Capsule().fill(bg)
                }
            }
    }
}
