import SwiftUI

struct FriendRequestCard: View {
    let connection: FriendConnection
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            profilePhoto
            nameLabel
            Spacer()
            actionButtons
        }
        .cardStyle()
    }

    // MARK: - Photo

    private var profilePhoto: some View {
        Group {
            if let photoData = connection.friendPhotoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }

    // MARK: - Name

    private var nameLabel: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(connection.friendDisplayName)
                .font(.subheadline.bold())
                .lineLimit(1)
            Text("Wants to be your friend")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Button(action: onAccept) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.success)
            }
            .buttonStyle(.plain)

            Button(action: onDecline) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.danger)
            }
            .buttonStyle(.plain)
        }
    }
}
