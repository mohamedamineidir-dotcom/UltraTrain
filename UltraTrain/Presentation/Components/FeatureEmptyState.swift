import SwiftUI

/// Shared "nothing here yet" view. One component for the ~30 empty-state
/// branches scattered across features so every "no plan", "no runs",
/// "no friends", "nothing to import" state looks and feels the same.
///
/// Visual language:
///   • A concentric circle badge with a tinted SF Symbol (matches the
///     Training-plan and Nutrition empty states that already felt
///     premium).
///   • Title + optional message, centred.
///   • Optional primary CTA rendered as a gradient capsule in the
///     provided tint; optional secondary action rendered as a plain-
///     text link beneath.
///
/// Use at the root of a ScrollView, or wrapped in a Group where a
/// feature shows it instead of content. Not designed for List rows
/// (use `CompactEmptyRow` there if a row-scale variant is needed later).
struct FeatureEmptyState: View {

    let icon: String
    let title: String
    var message: String? = nil
    var tint: Color = Theme.Colors.accentColor
    var primaryAction: Action? = nil
    var secondaryAction: Action? = nil
    /// When true the primary button shows a ProgressView and is
    /// disabled — used by "Generate Plan"-style buttons that kick off
    /// async work.
    var isPrimaryLoading: Bool = false

    struct Action {
        let title: String
        var systemImage: String? = nil
        let handler: () -> Void
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer(minLength: Theme.Spacing.lg)

            iconBadge

            VStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                if let message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)

            if primaryAction != nil || secondaryAction != nil {
                VStack(spacing: Theme.Spacing.sm) {
                    if let primary = primaryAction {
                        primaryButton(primary)
                    }
                    if let secondary = secondaryAction {
                        secondaryButton(secondary)
                    }
                }
            }

            Spacer(minLength: Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.05))
                .frame(width: 140, height: 140)
            Circle()
                .fill(tint.opacity(0.10))
                .frame(width: 100, height: 100)
            Image(systemName: icon)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(tint)
                .shadow(color: tint.opacity(0.3), radius: 8)
        }
    }

    private func primaryButton(_ action: Action) -> some View {
        Button {
            action.handler()
        } label: {
            Group {
                if isPrimaryLoading {
                    ProgressView()
                        .tint(.white)
                } else if let systemImage = action.systemImage {
                    Label(action.title, systemImage: systemImage)
                        .font(.headline)
                } else {
                    Text(action.title)
                        .font(.headline)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                LinearGradient(
                    colors: [tint, tint.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: tint.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(isPrimaryLoading)
        .buttonStyle(.plain)
    }

    private func secondaryButton(_ action: Action) -> some View {
        Button {
            action.handler()
        } label: {
            Group {
                if let systemImage = action.systemImage {
                    Label(action.title, systemImage: systemImage)
                } else {
                    Text(action.title)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .buttonStyle(.plain)
    }
}
