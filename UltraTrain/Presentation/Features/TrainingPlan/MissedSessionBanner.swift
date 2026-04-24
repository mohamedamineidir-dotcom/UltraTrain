import SwiftUI

/// Appears above the week cards when `MissedSessionPatternDetector`
/// flags sustained absenteeism, quality drift, or extended
/// inactivity in the last 14 days. Closes the loop between the plan's
/// assumptions and what the athlete has actually executed.
///
/// Dismissable per session. The regenerate-plan action is the primary
/// CTA — tapping it reruns plan generation, which will re-anchor the
/// chronic-load baseline, pace targets, and periodisation to what the
/// athlete has actually done.
struct MissedSessionBanner: View {
    let pattern: MissedSessionPatternDetector.Pattern
    let onRegenerate: () -> Void
    let onDismiss: () -> Void
    let isRegenerating: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var tint: Color {
        // Inactivity / multi-skip = warning amber (coach-level notice);
        // quality drift alone = neutral accent (informational).
        if pattern.flags.contains(.extendedInactivity)
            || pattern.flags.contains(.multiSessionSkip) {
            return Theme.Colors.warning
        }
        return Theme.Colors.accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "calendar.badge.exclamationmark")
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
                Button {
                    onRegenerate()
                } label: {
                    HStack(spacing: 6) {
                        if isRegenerating {
                            ProgressView()
                                .controlSize(.mini)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption.weight(.bold))
                        }
                        Text(isRegenerating ? "Rebuilding" : "Rebalance the plan")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(tint))
                }
                .buttonStyle(.plain)
                .disabled(isRegenerating)

                Spacer(minLength: 0)
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
        if pattern.flags.contains(.extendedInactivity) {
            return "Plan is ahead of where you actually are"
        }
        if pattern.flags.contains(.multiSessionSkip) {
            return "Missed \(pattern.skipCountRecent) sessions recently"
        }
        return "Quality work has drifted"
    }

    private var body_: String {
        var lines: [String] = []

        if pattern.flags.contains(.extendedInactivity) {
            lines.append("It's been \(pattern.daysSinceLastCompletion) days since your last completed session. The plan's later blocks assume fitness built in between. Rebalancing re-anchors the paces and load targets to what you've actually done.")
        } else if pattern.flags.contains(.multiSessionSkip) {
            lines.append("You've skipped \(pattern.skipCountRecent) sessions in the last 14 days. The plan keeps prescribing work based on the original schedule — a rebalance pulls everything into line with your current trajectory.")
        }

        if pattern.flags.contains(.qualitySessionDrift) {
            lines.append("\(pattern.qualityDriftCount) quality sessions have been skipped or under-executed. Quality is what builds the specific adaptations the later blocks assume — without it, race-pace targets may be ambitious.")
        }

        return lines.joined(separator: " ")
    }
}
