import SwiftUI

struct ChallengeDefinitionCard: View {
    let definition: ChallengeDefinition
    let onStart: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: definition.iconName)
                .font(.title3)
                .foregroundStyle(Theme.Colors.primary)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(definition.name)
                    .font(.subheadline.bold())

                Text(definition.descriptionText)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)

                Text(definition.duration.displayName)
                    .font(.caption2.bold())
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .clipShape(Capsule())
            }

            Spacer()

            Button("Start") {
                onStart()
            }
            .buttonStyle(.bordered)
            .tint(Theme.Colors.primary)
            .accessibilityHint("Starts the \(definition.name) challenge")
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}
