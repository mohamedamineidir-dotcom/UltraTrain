import SwiftUI

struct StravaImportView: View {
    @State private var activities: [StravaActivity] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var currentPage = 1
    @State private var hasMore = true
    @State private var importingId: Int?

    let importService: any StravaImportServiceProtocol
    let athleteId: UUID
    let onImport: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && activities.isEmpty {
                    ProgressView("Loading Strava activities...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if activities.isEmpty {
                    emptyState
                } else {
                    activityList
                }
            }
            .navigationTitle("Import from Strava")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: .init(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("OK") { error = nil }
            } message: {
                Text(error ?? "")
            }
            .task { await loadActivities() }
        }
    }

    // MARK: - List

    private var activityList: some View {
        List {
            ForEach(activities) { activity in
                StravaActivityRow(
                    activity: activity,
                    isImporting: importingId == activity.id
                ) {
                    Task { await importActivity(activity) }
                }
            }

            if hasMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .task { await loadMore() }
            }
        }
        .listStyle(.plain)
        .refreshable { await refresh() }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            Text("No run activities found")
                .font(.headline)
            Text("Only runs and trail runs from Strava are shown here.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Actions

    private func loadActivities() async {
        guard !isLoading else { return }
        isLoading = true
        do {
            let fetched = try await importService.fetchActivities(page: 1, perPage: 30)
            activities = fetched
            currentPage = 1
            hasMore = fetched.count == 30
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func loadMore() async {
        guard !isLoading, hasMore else { return }
        isLoading = true
        let nextPage = currentPage + 1
        do {
            let fetched = try await importService.fetchActivities(page: nextPage, perPage: 30)
            activities.append(contentsOf: fetched)
            currentPage = nextPage
            hasMore = fetched.count == 30
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func refresh() async {
        activities = []
        currentPage = 1
        hasMore = true
        await loadActivities()
    }

    private func importActivity(_ activity: StravaActivity) async {
        importingId = activity.id
        do {
            _ = try await importService.importActivity(activity, athleteId: athleteId)
            if let index = activities.firstIndex(where: { $0.id == activity.id }) {
                activities[index].isImported = true
            }
            onImport()
        } catch {
            self.error = error.localizedDescription
        }
        importingId = nil
    }
}

// MARK: - Row

private struct StravaActivityRow: View {
    @Environment(\.unitPreference) private var units
    let activity: StravaActivity
    let isImporting: Bool
    let onImport: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(activity.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: Theme.Spacing.md) {
                    Text(activity.startDate, style: .date)
                    Text(UnitFormatter.formatDistance(activity.distanceKm, unit: units))
                    Text(activity.formattedDuration)
                }
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)

                if activity.totalElevationGain > 0 {
                    HStack(spacing: Theme.Spacing.md) {
                        Label(
                            "+" + UnitFormatter.formatElevation(activity.totalElevationGain, unit: units),
                            systemImage: "arrow.up.right"
                        )
                        if let avgHR = activity.averageHeartRate {
                            Label("\(Int(avgHR)) bpm", systemImage: "heart.fill")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }

            Spacer()

            if activity.isImported {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.Colors.success)
                    .accessibilityLabel("Already imported")
            } else if isImporting {
                ProgressView()
            } else {
                Button("Import") { onImport() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.orange)
                    .accessibilityHint("Imports this activity from Strava")
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}
