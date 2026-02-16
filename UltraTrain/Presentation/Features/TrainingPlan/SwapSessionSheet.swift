import SwiftUI

struct SwapSessionSheet: View {
    let currentSession: TrainingSession
    let availableSessions: [SwapCandidate]
    let onSwap: (SwapCandidate) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if availableSessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions Available",
                        systemImage: "arrow.triangle.swap",
                        description: Text("There are no other sessions to swap with this week.")
                    )
                } else {
                    Section {
                        ForEach(availableSessions) { candidate in
                            Button {
                                onSwap(candidate)
                                dismiss()
                            } label: {
                                candidateRow(candidate)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Swap \"\(currentSession.type.displayName)\" with:")
                    }
                }
            }
            .navigationTitle("Swap Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func candidateRow(_ candidate: SwapCandidate) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: candidate.session.type.icon)
                .foregroundStyle(candidate.session.intensity.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.session.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: Theme.Spacing.sm) {
                    if candidate.session.plannedDistanceKm > 0 {
                        Text("\(candidate.session.plannedDistanceKm, specifier: "%.1f") km")
                    }
                    Text(candidate.session.date.formatted(.dateTime.weekday(.wide).month().day()))
                }
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            Image(systemName: "arrow.triangle.swap")
                .foregroundStyle(Theme.Colors.primary)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

struct SwapCandidate: Identifiable {
    let id: UUID
    let session: TrainingSession
    let weekIndex: Int
    let sessionIndex: Int

    init(session: TrainingSession, weekIndex: Int, sessionIndex: Int) {
        self.id = session.id
        self.session = session
        self.weekIndex = weekIndex
        self.sessionIndex = sessionIndex
    }
}
