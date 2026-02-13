import SwiftUI
import CoreLocation

struct RunDetailView: View {
    let run: CompletedRun

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if !run.gpsTrack.isEmpty {
                    RunMapView(
                        coordinates: run.gpsTrack.map {
                            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                        },
                        showsUserLocation: false,
                        height: 250
                    )
                    .padding(.horizontal, Theme.Spacing.md)
                }

                statsGrid
                    .padding(.horizontal, Theme.Spacing.md)

                if !run.splits.isEmpty {
                    splitsSection
                        .padding(.horizontal, Theme.Spacing.md)
                }

                if let notes = run.notes, !notes.isEmpty {
                    notesSection(notes)
                        .padding(.horizontal, Theme.Spacing.md)
                }
            }
            .padding(.vertical, Theme.Spacing.md)
        }
        .navigationTitle(run.date.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: Theme.Spacing.md
        ) {
            detailTile(label: "Distance", value: String(format: "%.2f km", run.distanceKm))
            if run.pausedDuration > 0 {
                detailTile(label: "Moving Time", value: RunStatisticsCalculator.formatDuration(run.duration))
                detailTile(label: "Total Time", value: RunStatisticsCalculator.formatDuration(run.totalDuration))
            } else {
                detailTile(label: "Duration", value: RunStatisticsCalculator.formatDuration(run.duration))
            }
            detailTile(label: "Avg Pace", value: run.paceFormatted)
            detailTile(label: "Elevation", value: String(format: "+%.0f / -%.0f m", run.elevationGainM, run.elevationLossM))
            if let avgHR = run.averageHeartRate {
                detailTile(label: "Avg HR", value: "\(avgHR) bpm")
            }
            if let maxHR = run.maxHeartRate {
                detailTile(label: "Max HR", value: "\(maxHR) bpm")
            }
        }
    }

    // MARK: - Splits

    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Splits")
                .font(.headline)

            ForEach(run.splits) { split in
                HStack {
                    Text("KM \(split.kilometerNumber)")
                        .font(.subheadline.bold())
                        .frame(width: 50, alignment: .leading)

                    Text(RunStatisticsCalculator.formatPace(split.duration))
                        .font(.subheadline.monospacedDigit())

                    Spacer()

                    if split.elevationChangeM != 0 {
                        Text(String(format: "%+.0f m", split.elevationChangeM))
                            .font(.caption)
                            .foregroundStyle(
                                split.elevationChangeM > 0
                                    ? Theme.Colors.danger
                                    : Theme.Colors.success
                            )
                    }

                    if let hr = split.averageHeartRate {
                        Text("\(hr) bpm")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)

                if split.id != run.splits.last?.id {
                    Divider()
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    // MARK: - Notes

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Notes")
                .font(.headline)
            Text(notes)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    // MARK: - Helper

    private func detailTile(label: String, value: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(value)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }
}
