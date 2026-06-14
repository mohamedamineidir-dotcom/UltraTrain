import SwiftUI

// MARK: - Entitlement coordinator

/// Shared premium-entitlement state for the authenticated app, injected
/// into the tab hierarchy so any feature can gate itself and trigger the
/// upgrade paywall. `isUnlocked` is true for paying subscribers AND athletes
/// inside the 7-day free trial; false for free-tier users (never subscribed,
/// cancelled, or trial expired). Defaults to unlocked so previews/tests and
/// any not-yet-wired context don't accidentally lock content.
@MainActor
@Observable
final class PremiumGate {
    var isUnlocked: Bool
    var showPaywall = false

    /// Server-granted free-access window from the referral reward. Held here
    /// so it can be fetched off the critical path (a slow/failed network call
    /// must never delay the StoreKit entitlement check). `nil` = no bonus.
    var referralBonusUntil: Date?

    init(isUnlocked: Bool = true) {
        self.isUnlocked = isUnlocked
    }

    func presentPaywall() {
        showPaywall = true
    }
}

#if DEBUG
/// DEBUG-only override to preview the free tier in the simulator without
/// fiddling with StoreKit. When on, the app treats the user as free
/// (features locked, scenario picker shown) regardless of real status.
/// Toggled from Settings ▸ Debug.
enum DebugEntitlement {
    private static let key = "debug_simulateFreeTier"
    static var simulateFreeTier: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    /// DEBUG-only: reveal EVERY week of the plan regardless of subscription
    /// status, so the full training schedule can be inspected on the simulator
    /// (a StoreKit-test purchase comes through as a trial, which otherwise caps
    /// the preview to 3 weeks). Toggled from Settings ▸ Debug.
    private static let allWeeksKey = "debug_unlockAllWeeks"
    static var unlockAllWeeks: Bool {
        get { UserDefaults.standard.bool(forKey: allWeeksKey) }
        set { UserDefaults.standard.set(newValue, forKey: allWeeksKey) }
    }
}
#endif

// MARK: - Premium lock modifier

/// Gates a premium feature for free users with a blurred teaser + an
/// "Unlock with Premium" overlay (soft paywall). The underlying view still
/// renders (and computes) so the athlete sees what they're missing, which
/// converts better than hiding it outright; it's blurred and non-interactive
/// until they upgrade. No effect for unlocked (paying / trial) users, or
/// when no gate is injected (previews / tests).
struct PremiumLockModifier: ViewModifier {
    @Environment(PremiumGate.self) private var gate: PremiumGate?

    let title: String
    let message: String

    func body(content: Content) -> some View {
        if gate?.isUnlocked ?? true {
            content
        } else {
            content
                .blur(radius: 8)
                .allowsHitTesting(false)
                .overlay {
                    PremiumLockOverlay(title: title, message: message) {
                        gate?.presentPaywall()
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(title). Premium feature."))
                .accessibilityHint(Text("Double-tap to unlock with Premium."))
                .accessibilityAddTraits(.isButton)
        }
    }
}

extension View {
    /// Locks this view behind Premium for free-tier users (see
    /// `PremiumLockModifier`).
    func premiumLocked(title: String, message: String) -> some View {
        modifier(PremiumLockModifier(title: title, message: message))
    }
}

// MARK: - Overlay

struct PremiumLockOverlay: View {
    let title: String
    let message: String
    let action: () -> Void

    var body: some View {
        ZStack {
            // Dim the blurred content so the card and text stay legible.
            Color.black.opacity(0.28)

            VStack(spacing: Theme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.goldAccent.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: "lock.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.Colors.goldAccent)
                }
                .shadow(color: Theme.Colors.goldAccent.opacity(0.35), radius: 8, y: 2)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                        Text(String(localized: "premium.unlock.cta", defaultValue: "Unlock with Premium"))
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Capsule().fill(Theme.Gradients.goldPremium))
                    .shadow(color: Theme.Colors.goldAccent.opacity(0.4), radius: 6, y: 2)
                }
                .padding(.top, 2)
                .accessibilityIdentifier("premium.unlockButton")
            }
            .padding(Theme.Spacing.lg)
        }
    }
}
