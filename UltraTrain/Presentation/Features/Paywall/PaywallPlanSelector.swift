import SwiftUI

struct PaywallPlanSelector: View {
    let plans: [SubscriptionPlan]
    @Binding var selectedPlanId: String?

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(plans) { plan in
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
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Theme.Spacing.sm) {
                    Text(plan.period.displayNameLocalized)
                        .font(.headline)
                        .foregroundStyle(.white)

                    if plan.trialDays != nil {
                        Text("paywall.freeWeek")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    if let savings = plan.savingsPercent {
                        Text("paywall.save \(savings)")
                            .font(.caption2.bold())
                            .foregroundStyle(.black)
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Theme.Gradients.goldPremium)
                            .clipShape(Capsule())
                    }
                }
                Text("paywall.perWeek \(plan.displayPricePerWeek)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Text(plan.displayPrice)
                .font(.title3.bold())
                .foregroundStyle(.white)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(.ultraThinMaterial)
                .opacity(isSelected ? 1.0 : 0.6)
        )
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(
                    isSelected ? Theme.Colors.warmCoral : Color.white.opacity(0.12),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(color: isSelected ? Theme.Colors.warmCoral.opacity(0.3) : .clear, radius: 8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
