import SwiftUI

/// Shown while a captured food photo is being analyzed. Used both inside
/// the still-open camera capture flow (so there's no visible gap between
/// "photo taken" and "results shown" — see `FoodPhotoCaptureFlow`) and as
/// a defensive fallback inside `FoodPhotoResultsView`.
struct AnalyzingFoodPhotoView: View {
    let photoData: Data?

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            if let photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                            .stroke(Theme.Colors.warmCoral.opacity(0.4), lineWidth: 2)
                    )
                    .shadow(color: Theme.Colors.warmCoral.opacity(0.25), radius: 16, y: 6)
            }

            VStack(spacing: Theme.Spacing.sm) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.Colors.warmCoral)

                Text(String(localized: "Analyzing your food..."))
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(String(localized: "AI is identifying items and estimating nutrition"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
