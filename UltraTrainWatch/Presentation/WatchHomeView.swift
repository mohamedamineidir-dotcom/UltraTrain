import SwiftUI

struct WatchHomeView: View {
    let sessionData: WatchSessionData?
    let isPhoneReachable: Bool
    let runHistory: [WatchRunHistoryData]
    let locationAuthStatus: WatchLocationAuthStatus
    let onStartRun: () -> Void
    let onRequestLocationPermission: () -> Void

    private var isStartDisabled: Bool {
        locationAuthStatus != .authorized
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                locationBanner

                if let session = sessionData {
                    sessionCard(session)
                } else {
                    noSessionPlaceholder
                }

                startButton

                if !runHistory.isEmpty {
                    NavigationLink {
                        WatchRunHistoryView(runs: runHistory)
                    } label: {
                        Label("History (\(runHistory.count))", systemImage: "clock.arrow.circlepath")
                            .font(.caption)
                    }
                }

                connectionStatus
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Session Card

    private func sessionCard(_ session: WatchSessionData) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: sessionIcon(for: session.type))
                    .foregroundStyle(.green)
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(session.sessionTypeLabel)
                .font(.headline)

            HStack(spacing: 12) {
                Label(
                    String(format: "%.1f km", session.plannedDistanceKm),
                    systemImage: "figure.run"
                )
                .font(.caption)

                if session.plannedElevationGainM > 0 {
                    Label(
                        "+\(Int(session.plannedElevationGainM)) m",
                        systemImage: "mountain.2.fill"
                    )
                    .font(.caption)
                }
            }
            .foregroundStyle(.secondary)

            Text(session.intensityLabel)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(intensityColor(session.intensity).opacity(0.2))
                .foregroundStyle(intensityColor(session.intensity))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Placeholder

    private var noSessionPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("No session today")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Location Banner

    @ViewBuilder
    private var locationBanner: some View {
        switch locationAuthStatus {
        case .notDetermined:
            Button(action: onRequestLocationPermission) {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text("Allow location to track runs")
                        .font(.caption2)
                        .lineLimit(2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(.blue.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        case .denied:
            HStack(spacing: 6) {
                Image(systemName: "location.slash.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                Text("Location denied. Enable in Settings.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(.red.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        case .authorized:
            EmptyView()
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button(action: onStartRun) {
            Label("Start Run", systemImage: "play.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .tint(.green)
        .disabled(isStartDisabled)
        .opacity(isStartDisabled ? 0.5 : 1)
    }

    // MARK: - Connection Status

    @ViewBuilder
    private var connectionStatus: some View {
        if !isPhoneReachable {
            Label("iPhone not connected", systemImage: "iphone.slash")
                .font(.caption2)
                .foregroundStyle(.orange)
        }
    }

    // MARK: - Helpers

    private func sessionIcon(for type: String) -> String {
        switch type {
        case "longRun": return "figure.run"
        case "tempo": return "gauge.with.needle.fill"
        case "intervals": return "timer"
        case "verticalGain": return "mountain.2.fill"
        case "backToBack": return "repeat"
        case "recovery": return "heart.fill"
        default: return "figure.run"
        }
    }

    private func intensityColor(_ intensity: String) -> Color {
        switch intensity {
        case "easy": return .green
        case "moderate": return .yellow
        case "hard": return .orange
        case "maxEffort": return .red
        default: return .secondary
        }
    }
}
