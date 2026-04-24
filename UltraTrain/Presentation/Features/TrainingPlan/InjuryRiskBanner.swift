import SwiftUI

/// Appears above the week cards when the next 7 days of the plan push
/// ACWR above 1.5 or monotony above 2.0 — both evidence-backed injury
/// predictors (Gabbett 2016 for ACWR, Foster 1998 for monotony). Gives
/// the athlete a chance to rebalance BEFORE executing the week rather
/// than finding out after.
///
/// Dismissable per session — the projection still recomputes next load,
/// so dismissing now doesn't suppress a future week that re-breaches.
struct InjuryRiskBanner: View {
    let projection: PlanInjuryRiskProjector.Projection
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var tint: Color {
        // ACWR spike is the most actionable injury flag — colour the
        // banner warning. Detraining or pure-monotony alone get the
        // softer neutral-info treatment.
        if projection.flags.contains(.acwrSpike) {
            return Theme.Colors.warning
        }
        return Theme.Colors.accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
                Text(headline)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.label)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.Colors.tertiaryLabel)
                        .padding(4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }

            Text(body_)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(1)

            HStack(spacing: 8) {
                metricChip(
                    label: "ACWR",
                    value: String(format: "%.2f", projection.projectedACWR),
                    isBreached: projection.flags.contains(.acwrSpike)
                                || projection.flags.contains(.acwrDetraining)
                )
                metricChip(
                    label: "Monotony",
                    value: String(format: "%.1f", projection.projectedMonotony),
                    isBreached: projection.flags.contains(.highMonotony)
                )
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(LinearGradient(
                    colors: [
                        tint.opacity(colorScheme == .dark ? 0.22 : 0.12),
                        tint.opacity(colorScheme == .dark ? 0.06 : 0.03)
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
                .stroke(tint.opacity(0.28), lineWidth: 0.75)
        )
    }

    // MARK: - Copy

    private var headline: String {
        if projection.flags.contains(.acwrSpike) {
            return "High injury-risk week ahead"
        }
        if projection.flags.contains(.highMonotony) {
            return "Week load looks monotonous"
        }
        if projection.flags.contains(.acwrDetraining) {
            return "Load drop this week"
        }
        return "Plan load notice"
    }

    private var body_: String {
        var parts: [String] = []
        if projection.flags.contains(.acwrSpike) {
            parts.append("Your next 7 days are set to jump \(acwrPercentDelta)% over your recent 4-week average. Gabbett's research links ACWR >1.5 to a 2-4× injury risk — consider trimming a session or softening intensity.")
        } else if projection.flags.contains(.acwrDetraining) {
            parts.append("Next 7 days sit ~\(abs(acwrPercentDelta))% below your recent average. Fine as a cutback, worth watching if it's unplanned.")
        }
        if projection.flags.contains(.highMonotony) {
            parts.append("Daily loads are too similar this week. Build in at least one true easy day to contrast the harder ones (Foster's monotony model).")
        }
        return parts.joined(separator: " ")
    }

    private var acwrPercentDelta: Int {
        // Positive when acute > chronic.
        let delta = ((projection.projectedACWR - 1.0) * 100).rounded()
        return Int(delta)
    }

    private func metricChip(label: String, value: String, isBreached: Bool) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.Colors.tertiaryLabel)
            Text(value)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(isBreached ? tint : Theme.Colors.secondaryLabel)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(
                isBreached ? tint.opacity(0.15) : Theme.Colors.tertiaryLabel.opacity(0.08)
            )
        )
        .overlay(
            Capsule().stroke(
                isBreached ? tint.opacity(0.28) : Color.clear,
                lineWidth: 0.5
            )
        )
    }
}
