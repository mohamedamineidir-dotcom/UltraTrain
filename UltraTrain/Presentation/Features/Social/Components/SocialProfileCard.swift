import SwiftUI

struct SocialProfileCard: View {
    let profile: SocialProfile

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            profilePhoto
            profileInfo
            Spacer()
        }
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(profile.displayName), \(profile.experienceLevel.rawValue.capitalized). \(profile.totalRuns) runs, \(Int(profile.totalDistanceKm)) kilometers, \(Int(profile.totalElevationGainM)) meters elevation gain")
    }

    // MARK: - Photo

    private var profilePhoto: some View {
        Group {
            if let photoData = profile.profilePhotoData,
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
        .frame(width: 48, height: 48)
        .clipShape(Circle())
    }

    // MARK: - Info

    private var profileInfo: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(profile.displayName)
                .font(.headline)
                .lineLimit(1)

            Text(profile.experienceLevel.rawValue.capitalized)
                .font(.caption)
                .foregroundStyle(Theme.Colors.primary)

            HStack(spacing: Theme.Spacing.md) {
                Label("\(profile.totalRuns) runs", systemImage: "figure.run")
                Label(
                    String(format: "%.0f km", profile.totalDistanceKm),
                    systemImage: "point.topleft.down.to.point.bottomright.curvepath"
                )
                Label(
                    String(format: "%.0f m D+", profile.totalElevationGainM),
                    systemImage: "mountain.2"
                )
            }
            .font(.caption2)
            .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }
}
