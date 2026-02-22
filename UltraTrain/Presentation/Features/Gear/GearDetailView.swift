import SwiftUI

struct GearDetailView: View {
    @Environment(\.unitPreference) private var units
    @State private var item: GearItem
    @State private var recentRuns: [CompletedRun] = []
    @State private var isLoading = false
    @State private var showingEdit = false

    private let gearRepository: any GearRepository
    private let runRepository: any RunRepository

    init(item: GearItem, gearRepository: any GearRepository, runRepository: any RunRepository) {
        _item = State(initialValue: item)
        self.gearRepository = gearRepository
        self.runRepository = runRepository
    }

    var body: some View {
        List {
            statsSection
            lifespanSection
            if !recentRuns.isEmpty {
                runsSection
            }
            if let notes = item.notes, !notes.isEmpty {
                notesSection(notes)
            }
        }
        .navigationTitle(item.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .task { await loadRuns() }
        .sheet(isPresented: $showingEdit) {
            EditGearSheet(mode: .edit(item)) { updated in
                Task {
                    do {
                        try await gearRepository.updateGearItem(updated)
                        item = updated
                    } catch {}
                }
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        Section("Overview") {
            LabeledContent("Type", value: item.type.displayName)
            LabeledContent("Brand", value: item.brand)
            LabeledContent("Purchased", value: item.purchaseDate.formatted(date: .abbreviated, time: .omitted))
            if item.isRetired {
                Label("Retired", systemImage: "archivebox.fill")
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Lifespan

    private var lifespanSection: some View {
        Section("Lifespan") {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ProgressView(value: item.usagePercentage)
                    .tint(progressColor)

                HStack {
                    Text("\(UnitFormatter.formatDistance(item.totalDistanceKm, unit: units)) used")
                        .font(.subheadline.bold())
                    Spacer()
                    Text("\(UnitFormatter.formatDistance(item.remainingKm, unit: units, decimals: 0)) remaining")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }

            let hours = Int(item.totalDuration) / 3600
            let minutes = (Int(item.totalDuration) % 3600) / 60
            LabeledContent("Total Duration", value: "\(hours)h \(minutes)m")

            if item.needsReplacement {
                Label("Time to replace this gear!", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Warning: Time to replace this gear")
            }
        }
    }

    // MARK: - Runs

    private var runsSection: some View {
        Section("Recent Runs (\(recentRuns.count))") {
            ForEach(recentRuns.prefix(10)) { run in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(run.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                        Text(UnitFormatter.formatDistance(run.distanceKm, unit: units))
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                    Spacer()
                    Text(run.paceFormatted)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
    }

    // MARK: - Notes

    private func notesSection(_ notes: String) -> some View {
        Section("Notes") {
            Text(notes)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Helpers

    private var progressColor: Color {
        if item.usagePercentage >= 1.0 { return .red }
        if item.usagePercentage >= 0.8 { return .orange }
        return .green
    }

    private func loadRuns() async {
        isLoading = true
        do {
            let allRuns = try await runRepository.getRecentRuns(limit: 1000)
            let gearId = item.id
            recentRuns = allRuns
                .filter { $0.gearIds.contains(gearId) }
                .sorted { $0.date > $1.date }
        } catch {}
        isLoading = false
    }
}
