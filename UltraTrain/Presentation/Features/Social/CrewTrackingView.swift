import SwiftUI

struct CrewTrackingView: View {

    @State private var viewModel: CrewTrackingViewModel
    @State private var joinSessionIdText = ""
    @State private var showingSharingSheet = false
    private let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    init(
        crewService: any CrewTrackingServiceProtocol,
        profileRepository: any SocialProfileRepository
    ) {
        _viewModel = State(initialValue: CrewTrackingViewModel(
            crewService: crewService,
            profileRepository: profileRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(Theme.Spacing.xl)
                } else if let session = viewModel.session {
                    activeSessionView(session)
                } else {
                    noSessionView
                }
            }
            .padding(Theme.Spacing.md)
        }
        .navigationTitle("Crew Tracking")
        .onReceive(timer) { _ in
            Task { await viewModel.refreshSession() }
        }
        .sheet(isPresented: $showingSharingSheet) {
            if let session = viewModel.session {
                StartCrewSharingSheet(session: session)
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    // MARK: - No Session View

    private var noSessionView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Colors.primary)
                .padding(.top, Theme.Spacing.xl)

            Text("Track your crew's location in real time during a run or race.")
                .font(.body)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)

            Button {
                Task { await viewModel.startSession() }
            } label: {
                Label("Start New Session", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            VStack(spacing: Theme.Spacing.sm) {
                Text("Or join an existing session:")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)

                TextField("Session ID", text: $joinSessionIdText)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()

                Button {
                    guard let uuid = UUID(uuidString: joinSessionIdText) else { return }
                    Task { await viewModel.joinSession(id: uuid) }
                } label: {
                    Text("Join Session")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(UUID(uuidString: joinSessionIdText) == nil)
            }
            .cardStyle()
        }
    }

    // MARK: - Active Session View

    private func activeSessionView(_ session: CrewTrackingSession) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            mapPlaceholder

            sessionInfoCard(session)

            participantsList(session.participants)

            sessionActions(session)
        }
    }

    private var mapPlaceholder: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
            .fill(Theme.Colors.secondaryBackground)
            .frame(height: 200)
            .overlay {
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "map")
                        .font(.largeTitle)
                    Text("Map would show participants here")
                        .font(.caption)
                }
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }
    }

    private func sessionInfoCard(_ session: CrewTrackingSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Session ID")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(session.id.uuidString.prefix(8) + "...")
                    .font(.footnote.monospaced())
            }
            Spacer()
            Button {
                showingSharingSheet = true
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.subheadline)
            }
        }
        .cardStyle()
    }

    private func participantsList(_ participants: [CrewParticipant]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Participants (\(participants.count))")
                .font(.headline)

            ForEach(participants) { participant in
                participantRow(participant)
            }
        }
        .cardStyle()
    }

    private func participantRow(_ participant: CrewParticipant) -> some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(Theme.Colors.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(participant.displayName)
                    .font(.subheadline.bold())
                Text(String(format: "%.1f km", participant.distanceKm))
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedPace(participant.currentPaceSecondsPerKm))
                    .font(.caption.monospacedDigit())
                Text(relativeTime(participant.lastUpdated))
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private func sessionActions(_ session: CrewTrackingSession) -> some View {
        Group {
            if viewModel.isHost {
                Button(role: .destructive) {
                    Task { await viewModel.endSession() }
                } label: {
                    Label("End Session", systemImage: "stop.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.Colors.danger)
            } else {
                Button(role: .destructive) {
                    Task { await viewModel.leaveSession() }
                } label: {
                    Label("Leave Session", systemImage: "arrow.left.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Formatting Helpers

    private func formattedPace(_ secondsPerKm: Double) -> String {
        guard secondsPerKm > 0 else { return "--:-- /km" }
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date.now)
    }
}
