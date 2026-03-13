import SwiftUI

struct ValidateSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let session: TrainingSession
    let recentRuns: [CompletedRun]
    let connectedServices: Set<ExternalService>
    let onManualComplete: () -> Void
    let onLinkRun: (UUID) -> Void
    let onConnectService: (ExternalService) -> Void

    var body: some View {
        NavigationStack {
            List {
                manualSection
                if !recentRuns.isEmpty {
                    recentActivitiesSection
                }
                connectServicesSection
            }
            .navigationTitle("Validate Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Manual Complete

    private var manualSection: some View {
        Section {
            Button {
                onManualComplete()
                dismiss()
            } label: {
                Label("Mark Complete Manually", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Theme.Colors.success)
            }
        } footer: {
            Text("Mark this session as done without linking to a recorded activity.")
        }
    }

    // MARK: - Recent Activities

    private var recentActivitiesSection: some View {
        Section("Recent Activities") {
            ForEach(recentRuns) { run in
                Button {
                    onLinkRun(run.id)
                    dismiss()
                } label: {
                    recentRunRow(run)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func recentRunRow(_ run: CompletedRun) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            sourceIcon(for: run)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(run.date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                    .font(.subheadline.weight(.medium))
                HStack(spacing: Theme.Spacing.xs) {
                    Text(formatDuration(run.duration))
                    if run.distanceKm > 0 {
                        Text("·")
                        Text(String(format: "%.1f km", run.distanceKm))
                    }
                    if run.elevationGainM > 0 {
                        Text("·")
                        Text(String(format: "%.0fm D+", run.elevationGainM))
                    }
                }
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            Image(systemName: "link.badge.plus")
                .foregroundStyle(Theme.Colors.accentColor)
        }
    }

    @ViewBuilder
    private func sourceIcon(for run: CompletedRun) -> some View {
        let service = run.importSource ?? inferService(from: run)
        Image(systemName: service?.icon ?? "figure.run")
            .font(.caption)
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(serviceColor(service))
            )
    }

    // MARK: - Connect Services

    private var connectServicesSection: some View {
        Section("Connect More Services") {
            ForEach(ExternalService.allCases, id: \.self) { service in
                let isConnected = connectedServices.contains(service)
                HStack {
                    Image(systemName: service.icon)
                        .foregroundStyle(isConnected ? Theme.Colors.success : Theme.Colors.secondaryLabel)
                        .frame(width: 24)
                    Text(service.displayName)
                        .font(.subheadline)
                    Spacer()
                    if isConnected {
                        Text("Connected")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.success)
                    } else {
                        Button("Connect") {
                            onConnectService(service)
                        }
                        .font(.caption.bold())
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func inferService(from run: CompletedRun) -> ExternalService? {
        if run.isStravaImport { return .strava }
        if run.isHealthKitImport { return .appleHealth }
        return nil
    }

    private func serviceColor(_ service: ExternalService?) -> Color {
        switch service {
        case .strava:        .orange
        case .appleHealth:   .red
        case .garminConnect: .blue
        case .coros:         .indigo
        case .suunto:        .teal
        case nil:            Theme.Colors.secondaryLabel
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return hours > 0 ? "\(hours)h\(String(format: "%02d", minutes))" : "\(minutes)min"
    }
}
