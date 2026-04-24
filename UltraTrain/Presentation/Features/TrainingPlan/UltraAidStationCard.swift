import SwiftUI

/// Aid-station strategy card for ultra races. Consumes the athlete's
/// self-reported palate-timing answer (when sweet gels stop being
/// palatable) and translates it into concrete fuelling choices at the
/// aid stations they'll actually hit.
///
/// Research basis:
///   • Costa 2017 — "Systematic review: exercise-induced GI syndrome"
///     in ultra endurance. Flavour fatigue and sweet-aversion are
///     recurring mid-race GI symptoms; solutions are individualised
///     and rehearsed in training.
///   • Jeukendrup ISSN 2017 — during races ≥ 2h, 60-90 g carbs/hr from
///     multiple transportable carb sources (glucose + fructose) beats
///     a gel-only approach once palate resistance hits.
///
/// Only renders when:
///   1. session is the race itself,
///   2. race distance ≥ 60 km (shorter races rarely push an athlete
///      past the sweet-only window),
///   3. the athlete answered the palate-timing question.
struct UltraAidStationCard: View {
    let palateTiming: UltraPalateTiming
    let raceDistanceKm: Double

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            header
            Text(headline)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.Colors.label)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            ForEach(Array(strategyBullets.enumerated()), id: \.offset) { _, bullet in
                bulletRow(bullet)
            }

            Text(footer)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(LinearGradient(
                    colors: [
                        NutritionPalette.tint.opacity(colorScheme == .dark ? 0.22 : 0.12),
                        NutritionPalette.tint.opacity(colorScheme == .dark ? 0.06 : 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(colorScheme == .dark ? 0.10 : 0.40), location: 0.0),
                        .init(color: Color.clear, location: 0.55)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(NutritionPalette.tint.opacity(0.28), lineWidth: 0.75)
        )
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "flag.checkered")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NutritionPalette.tint)
            Text("AID STATION STRATEGY")
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(NutritionPalette.tint)
            Spacer()
            Text(palateTiming.chipLabel)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.Colors.tertiaryLabel)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Theme.Colors.tertiaryLabel.opacity(0.1)))
        }
    }

    private func bulletRow(_ bullet: StrategyBullet) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: bullet.icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(NutritionPalette.tint)
                .frame(width: 18, alignment: .center)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(bullet.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.label)
                Text(bullet.detail)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(1)
            }
        }
    }

    // MARK: - Copy

    private struct StrategyBullet {
        let icon: String
        let title: String
        let detail: String
    }

    private var isHundredPlus: Bool { raceDistanceKm >= 100 }

    private var headline: String {
        switch palateTiming {
        case .early:
            return "You hit sweet-fatigue early. Plan real food from the first aid stations, not as a late-race backup."
        case .mid:
            return "You shift off sweet mid-race. Front-load gels, then transition to real food + salty options at the mid-race aid stations."
        case .late:
            return isHundredPlus
                ? "You tolerate sweet deep into a race, but 100 km+ will still push you past that window. Keep real food available for the final third."
                : "You tolerate sweet through most of a race this length. Gel-led with real food as a final-stretch backup."
        case .never:
            return "Your palate handles sweet at any distance. Stay gel-centric — but still stop at aid stations for fluid + sodium top-ups."
        }
    }

    private var strategyBullets: [StrategyBullet] {
        switch palateTiming {
        case .early:
            return [
                StrategyBullet(
                    icon: "1.circle.fill",
                    title: "First 60-90 minutes",
                    detail: "One gel to start the fuelling clock, then pivot. Don't try to grind down 4+ gels before flavour fatigue hits you."
                ),
                StrategyBullet(
                    icon: "fork.knife",
                    title: "Early aid stations (from ~km 20)",
                    detail: "Savoury-first: boiled potatoes with salt, pretzels, broth, crackers. Chews for portable carbs between aid stations."
                ),
                StrategyBullet(
                    icon: "drop.fill",
                    title: "Hydration + sodium",
                    detail: "Electrolyte drink, not plain water. 500-700 mg sodium/hr — easier to hit when you're already eating salty real food."
                )
            ]
        case .mid:
            return [
                StrategyBullet(
                    icon: "1.circle.fill",
                    title: "First half",
                    detail: "Gels + electrolyte drink on your normal 30-45 min cadence. This is where you bank carbs while your stomach is still cooperative."
                ),
                StrategyBullet(
                    icon: "2.circle.fill",
                    title: "Around the 2-3 hour mark",
                    detail: "Start introducing real food at aid stations before you feel forced to. Pretzels, boiled potatoes, banana, broth — whatever's served."
                ),
                StrategyBullet(
                    icon: "3.circle.fill",
                    title: "Back half",
                    detail: "Mix real food at aid stations with chews/bars between. Drop gel frequency; keep carb rate at 60-90 g/hr from mixed sources."
                )
            ]
        case .late:
            return [
                StrategyBullet(
                    icon: "1.circle.fill",
                    title: "First two-thirds",
                    detail: "Gel-led. Stick to your trained cadence and flavours. Electrolyte drink alongside to spread the sweet load."
                ),
                StrategyBullet(
                    icon: "fork.knife",
                    title: "Final third",
                    detail: isHundredPlus
                        ? "Swap to real food at aid stations: broth, boiled potatoes, salted snacks. Even a strong palate fatigues past 4-5 hr."
                        : "Have real food available as a plan-B. If gels still taste fine, stay on them — but don't force sweet if your gut resists."
                ),
                StrategyBullet(
                    icon: "drop.fill",
                    title: "Hydration",
                    detail: "Watch for warning signs of palate fatigue: gels tasting too sweet, stomach slosh. Both are cues to switch."
                )
            ]
        case .never:
            return [
                StrategyBullet(
                    icon: "bolt.fill",
                    title: "Gel cadence",
                    detail: "Stay on the cadence you've trained — 30-45 min. Alternate flavours to avoid monotony rather than palate fatigue."
                ),
                StrategyBullet(
                    icon: "drop.fill",
                    title: "At aid stations",
                    detail: "Use them for fluid + sodium top-ups and to refill flasks. You don't need the food tables but you still need the electrolytes."
                ),
                StrategyBullet(
                    icon: "exclamationmark.triangle.fill",
                    title: "Stay honest mid-race",
                    detail: "Rare palates can still shift under heat or nausea. If anything feels off, a few salty crackers or broth buys you back the stomach."
                )
            ]
        }
    }

    private var footer: String {
        "Rehearse this on your longest training runs — palate-fatigue strategy is individual and has to be tested before race day, not discovered on it."
    }
}

private extension UltraPalateTiming {
    var chipLabel: String {
        switch self {
        case .early:  return "Early palate shift"
        case .mid:    return "Mid-race shift"
        case .late:   return "Late shift"
        case .never:  return "No palate fatigue"
        }
    }
}
