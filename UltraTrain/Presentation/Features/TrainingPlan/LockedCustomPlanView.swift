import SwiftUI

/// Shown on the Plan tab when a free user has a preserved custom (premium)
/// plan. The plan + all its progress are kept untouched; this is the FOMO
/// teaser ("resubscribe to continue") plus an escape hatch to start a free
/// 12-week plan instead.
struct LockedCustomPlanView: View {
    @Environment(\.colorScheme) private var colorScheme

    let weekCount: Int
    let planName: String?
    let onResubscribe: () -> Void
    let onStartFreePlan: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.goldAccent.opacity(0.16))
                            .frame(width: 64, height: 64)
                        Image(systemName: "lock.fill")
                            .font(.title)
                            .foregroundStyle(Theme.Colors.goldAccent)
                    }
                    .shadow(color: Theme.Colors.goldAccent.opacity(0.35), radius: 10, y: 3)

                    Text(planName ?? String(localized: "lockedPlan.defaultName",
                                            defaultValue: "Your training plan"))
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)

                    Text(String(
                        format: String(localized: "lockedPlan.weeks",
                                       defaultValue: "%d-week plan · progress saved"),
                        weekCount
                    ))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.goldAccent)

                    Text(String(localized: "lockedPlan.body",
                                defaultValue: "Your plan and everything you've completed are saved. Resubscribe to pick up exactly where you left off."))
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .futuristicGlassStyle(phaseTint: Theme.Colors.goldAccent)

                Button(action: onResubscribe) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                        Text(String(localized: "lockedPlan.resubscribe", defaultValue: "Resubscribe to continue"))
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Capsule().fill(Theme.Gradients.goldPremium))
                    .shadow(color: Theme.Colors.goldAccent.opacity(0.4), radius: 8, y: 3)
                }
                .accessibilityIdentifier("lockedPlan.resubscribeButton")

                Button(action: onStartFreePlan) {
                    Text(String(localized: "lockedPlan.startFree", defaultValue: "Start a free 12-week plan instead"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Colors.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                }
            }
            .padding(Theme.Spacing.md)
            .padding(.top, Theme.Spacing.xl)
        }
    }
}
