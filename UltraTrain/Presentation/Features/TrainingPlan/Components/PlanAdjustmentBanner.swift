import SwiftUI

struct PlanAdjustmentBanner: View {
    let recommendations: [PlanAdjustmentRecommendation]
    let isApplying: Bool
    let onApply: (PlanAdjustmentRecommendation) -> Void
    let onDismiss: (PlanAdjustmentRecommendation) -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(recommendations) { rec in
                adjustmentCard(rec)
            }
        }
    }

    private func adjustmentCard(_ rec: PlanAdjustmentRecommendation) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon(for: rec.type))
                    .foregroundStyle(color(for: rec.severity))
                Text(rec.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                Spacer()
                Button {
                    onDismiss(rec)
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                .buttonStyle(.plain)
            }

            Text(rec.message)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            Button {
                onApply(rec)
            } label: {
                if isApplying {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(rec.actionLabel)
                }
            }
            .font(.caption.bold())
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(isApplying)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(color(for: rec.severity).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(color(for: rec.severity).opacity(0.3), lineWidth: 1)
        )
    }

    private func icon(for type: PlanAdjustmentType) -> String {
        switch type {
        case .rescheduleKeySession: "arrow.right.circle.fill"
        case .reduceVolumeAfterLowAdherence: "arrow.down.right.circle.fill"
        case .convertToRecoveryWeek: "bed.double.fill"
        case .bulkMarkMissedAsSkipped: "checklist"
        }
    }

    private func color(for severity: AdjustmentSeverity) -> Color {
        switch severity {
        case .urgent: Theme.Colors.danger
        case .recommended: Theme.Colors.warning
        case .suggestion: Theme.Colors.primary
        }
    }
}
