import SwiftUI

struct StartCrewSharingSheet: View {

    let session: CrewTrackingSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                sessionIdSection

                participantsSection

                shareButton

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .navigationTitle("Share Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Session ID

    private var sessionIdSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Session ID")
                .font(.headline)

            Text(session.id.uuidString)
                .font(.footnote.monospaced())
                .textSelection(.enabled)
                .padding(Theme.Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))

            Text("Share this ID so others can join your session.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .cardStyle()
    }

    // MARK: - Participants

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Current Participants (\(session.participants.count))")
                .font(.subheadline.bold())

            ForEach(session.participants) { participant in
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(Theme.Colors.primary)
                        .accessibilityHidden(true)
                    Text(participant.displayName)
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Share Button

    private var shareButton: some View {
        ShareLink(
            item: session.id.uuidString,
            subject: Text("Join my crew tracking session"),
            message: Text("Join my crew tracking session on UltraTrain! Session ID: \(session.id.uuidString)")
        ) {
            Label("Share Session ID", systemImage: "square.and.arrow.up")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityHint("Shares the session ID via the system share sheet")
    }
}
