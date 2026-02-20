import SwiftUI

struct DashboardFitnessCard: View {
    let snapshot: FitnessSnapshot?
    let fitnessStatus: FitnessStatus
    let formDescription: String
    let fitnessHistory: [FitnessSnapshot]
    let onSeeTrend: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Fitness")
                    .font(.headline)
                Spacer()
                if snapshot != nil {
                    Button("See trend", action: onSeeTrend)
                        .font(.caption)
                }
            }

            if let snapshot {
                HStack(spacing: Theme.Spacing.md) {
                    StatCard(title: "Fitness", value: String(format: "%.0f", snapshot.fitness), unit: "CTL")
                    StatCard(title: "Fatigue", value: String(format: "%.0f", snapshot.fatigue), unit: "ATL")
                    StatCard(title: "Form", value: formDescription, unit: "")
                }

                if fitnessHistory.count >= 2 {
                    MiniFormSparkline(snapshots: fitnessHistory)
                }

                acrStatusRow(snapshot: snapshot)
            } else {
                Text("Start training to see your fitness trend")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - ACR

    private func acrStatusRow(snapshot: FitnessSnapshot) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: acrIcon)
                .foregroundStyle(acrColor)
                .accessibilityHidden(true)
            Text("ACR: \(snapshot.acuteToChronicRatio, specifier: "%.2f")")
                .font(.caption)
            Text(acrLabel)
                .font(.caption.bold())
                .foregroundStyle(acrColor)
        }
        .accessibilityElement(children: .combine)
    }

    private var acrIcon: String {
        switch fitnessStatus {
        case .injuryRisk: "exclamationmark.triangle.fill"
        case .detraining: "arrow.down.circle.fill"
        case .optimal: "checkmark.circle.fill"
        case .noData: "minus.circle"
        }
    }

    private var acrColor: Color {
        switch fitnessStatus {
        case .injuryRisk: Theme.Colors.danger
        case .detraining: Theme.Colors.warning
        case .optimal: Theme.Colors.success
        case .noData: Theme.Colors.secondaryLabel
        }
    }

    private var acrLabel: String {
        switch fitnessStatus {
        case .injuryRisk: "Injury Risk"
        case .detraining: "Detraining"
        case .optimal: "Optimal"
        case .noData: ""
        }
    }
}
