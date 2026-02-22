import SwiftUI

struct SegmentDetailPopup: View {
    let detail: SegmentDetail
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text("Km \(detail.kilometerNumber)")
                    .font(.subheadline.bold())
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                .accessibilityLabel("Dismiss")
                .accessibilityHint("Dismiss segment details")
            }

            Divider()

            HStack(spacing: Theme.Spacing.md) {
                statItem(
                    icon: "speedometer",
                    value: RunStatisticsCalculator.formatPace(detail.paceSecondsPerKm),
                    unit: "/km"
                )
                statItem(
                    icon: "arrow.up.right",
                    value: String(format: "%+.0f", detail.elevationChangeM),
                    unit: "m"
                )
            }

            if let hr = detail.averageHeartRate {
                HStack(spacing: Theme.Spacing.md) {
                    statItem(
                        icon: "heart.fill",
                        value: "\(hr)",
                        unit: "bpm"
                    )
                    if let zone = detail.zone {
                        HStack(spacing: Theme.Spacing.xs) {
                            Circle()
                                .fill(zoneColor(zone))
                                .frame(width: 8, height: 8)
                            Text("Z\(zone)")
                                .font(.caption.bold())
                        }
                    }
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .frame(width: 180)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
        .shadow(radius: 4)
    }

    private func statItem(icon: String, value: String, unit: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            Text(value)
                .font(.caption.bold().monospacedDigit())
            Text(unit)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .accessibilityElement(children: .combine)
    }

    private func zoneColor(_ zone: Int) -> Color {
        switch zone {
        case 1: Theme.Colors.zone1
        case 2: Theme.Colors.zone2
        case 3: Theme.Colors.zone3
        case 4: Theme.Colors.zone4
        default: Theme.Colors.zone5
        }
    }
}
