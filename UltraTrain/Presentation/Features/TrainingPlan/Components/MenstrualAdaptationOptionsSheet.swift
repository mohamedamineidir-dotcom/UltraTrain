import SwiftUI

/// Sheet shown when the athlete taps the action on a menstrual-cycle
/// adaptation recommendation. Presents the symptom-appropriate options
/// (defer / reduce / swap / keep) as buttons that perform the actual
/// session edit when chosen.
///
/// Per the menstrual MVP spec:
/// - "Keep the plan" is always shown as a first-class option, never
///   hidden behind a tap
/// - Copy uses "could / might" framing, never "should"
/// - Visual treatment matches the rest of the app — no different
///   styling for this feature beyond the cluster's indigo accent
struct MenstrualAdaptationOptionsSheet: View {
    let recommendation: PlanAdjustmentRecommendation
    let onChoose: (Choice) -> Void
    @Environment(\.dismiss) private var dismiss

    /// What the athlete picked. Mirrored on the ViewModel side via
    /// `applyMenstrualChoice(_:choice:)` to perform the concrete plan edit.
    enum Choice: Equatable, Sendable {
        /// Push the affected session forward by N days. 2 days for
        /// bleed-day (matches the typical 24-48h symptom window),
        /// 3 days for pre-period (push past expected period start).
        case deferDays(Int)
        /// Multiply distance/elevation/duration by `factor`. When
        /// `lowerToEasy` is true, also set intensity to .easy
        /// (used for bleed-day "keep structure, dial it back").
        case reduceVolume(factor: Double, lowerToEasy: Bool)
        /// Replace with a recovery run (changes session type).
        case swapToEasy
        /// No plan change. Athlete deliberately chose to keep the
        /// session as-is. Always available — McNulty 2020.
        case keep
    }

    private struct Option: Identifiable {
        var id: String { title }
        let icon: String
        let title: String
        let detail: String
        let choice: Choice
    }

    private var options: [Option] {
        switch recommendation.type {
        case .menstrualBleedDayOptions:
            return [
                Option(
                    icon: "calendar.badge.plus",
                    title: "Defer by 2 days",
                    detail: "Move this session forward — symptoms typically settle within 24-48h.",
                    choice: .deferDays(2)
                ),
                Option(
                    icon: "arrow.down.circle",
                    title: "Reduce ~25%, easy effort",
                    detail: "Cut volume and dial intensity to easy. Light aerobic actually helps cramps.",
                    choice: .reduceVolume(factor: 0.75, lowerToEasy: true)
                ),
                Option(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Swap to recovery run",
                    detail: "Replace today's session with an easy recovery run.",
                    choice: .swapToEasy
                ),
                Option(
                    icon: "checkmark",
                    title: "Keep the plan",
                    detail: "Many runners train through bleed days without issue.",
                    choice: .keep
                ),
            ]
        case .menstrualPrePeriodOptions:
            return [
                Option(
                    icon: "calendar.badge.plus",
                    title: "Defer by 3 days",
                    detail: "Push past expected period start — PMS often resolves once bleeding begins.",
                    choice: .deferDays(3)
                ),
                Option(
                    icon: "arrow.down.circle",
                    title: "Drop intensity ~12%",
                    detail: "Same session, slightly less hard. Heat-sensitive efforts are most affected.",
                    choice: .reduceVolume(factor: 0.88, lowerToEasy: false)
                ),
                Option(
                    icon: "checkmark",
                    title: "Keep the plan",
                    detail: "Listen to your body — adjust on the day if needed.",
                    choice: .keep
                ),
            ]
        default:
            return []
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text(recommendation.title)
                        .font(.headline)
                        .padding(.horizontal, Theme.Spacing.md)

                    Text(recommendation.message)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .padding(.horizontal, Theme.Spacing.md)

                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(options) { option in
                            optionRow(option)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
                .padding(.vertical, Theme.Spacing.md)
            }
            .navigationTitle("Choose what fits today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func optionRow(_ option: Option) -> some View {
        Button {
            onChoose(option.choice)
            dismiss()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: option.icon)
                    .font(.title3)
                    .foregroundStyle(Color.indigo)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.Colors.label)
                    Text(option.detail)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.secondaryBackground)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .accessibilityHint(option.detail)
    }
}
