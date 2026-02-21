import SwiftUI

struct FriendRow: View {
    let connection: FriendConnection

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            profilePhoto
            Text(connection.friendDisplayName)
                .font(.body)
                .lineLimit(1)
            Spacer()
            statusBadge
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.vertical, Theme.Spacing.xs)
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

    // MARK: - Status Badge

    private var statusBadge: some View {
        Text(connection.status.rawValue.capitalized)
            .font(.caption2)
            .foregroundStyle(connection.status == .accepted ? Theme.Colors.success : Theme.Colors.warning)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 2)
            .background(
                (connection.status == .accepted ? Theme.Colors.success : Theme.Colors.warning)
                    .opacity(0.15),
                in: Capsule()
            )
    }
}
