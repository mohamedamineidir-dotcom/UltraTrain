import SwiftUI

struct WeekCardView: View {
    let week: TrainingWeek
    let weekIndex: Int
    let onToggleSession: (Int) -> Void

    @State private var isExpanded: Bool

    init(week: TrainingWeek, weekIndex: Int, isCurrentWeek: Bool = false, onToggleSession: @escaping (Int) -> Void) {
        self.week = week
        self.weekIndex = weekIndex
        self.onToggleSession = onToggleSession
        _isExpanded = State(initialValue: isCurrentWeek)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerButton
            if isExpanded {
                sessionsList
            }
        }
        .cardStyle()
    }

    private var headerButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text("Week \(week.weekNumber)")
                            .font(.headline)
                            .foregroundStyle(Theme.Colors.label)
                        PhaseBadge(phase: week.phase)
                        if week.isRecoveryWeek {
                            Text("Recovery")
                                .font(.caption2)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.green.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: Theme.Spacing.md) {
                        Label("\(week.targetVolumeKm, specifier: "%.0f") km", systemImage: "figure.run")
                        Label("\(week.targetElevationGainM, specifier: "%.0f") m", systemImage: "mountain.2.fill")
                        Text(progressText)
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
        }
        .buttonStyle(.plain)
    }

    private var sessionsList: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.vertical, Theme.Spacing.sm)

            ForEach(Array(week.sessions.enumerated()), id: \.element.id) { sessionIndex, session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    SessionRowView(session: session) {
                        onToggleSession(sessionIndex)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var progressText: String {
        let active = week.sessions.filter { $0.type != .rest }
        let done = active.filter(\.isCompleted).count
        return "\(done)/\(active.count) done"
    }
}
