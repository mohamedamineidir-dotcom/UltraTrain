import SwiftUI

// MARK: - Notes, Share, Linked Session, Auto Match & Strava

extension RunSummarySheet {

    // MARK: - Notes Section

    var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // RPE
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Rate of Perceived Exertion")
                    .font(.subheadline.bold())
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(1...10, id: \.self) { value in
                        Button {
                            rpe = rpe == value ? nil : value
                        } label: {
                            Text("\(value)")
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                        .fill(
                                            rpe == value
                                                ? rpeColor(value)
                                                : Theme.Colors.secondaryBackground
                                        )
                                )
                                .foregroundStyle(
                                    rpe == value
                                        ? .white
                                        : Theme.Colors.label
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("RPE \(value)\(rpe == value ? ", selected" : "")")
                    }
                }
            }

            // Feeling
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("How Did It Feel?")
                    .font(.subheadline.bold())
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(PerceivedFeeling.allCases, id: \.self) { feeling in
                        Button {
                            perceivedFeeling = perceivedFeeling == feeling
                                ? nil
                                : feeling
                        } label: {
                            VStack(spacing: 2) {
                                Text(feelingEmoji(feeling))
                                    .font(.title3)
                                Text(feelingLabel(feeling))
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                    .fill(
                                        perceivedFeeling == feeling
                                            ? Theme.Colors.primary.opacity(0.15)
                                            : Theme.Colors.secondaryBackground
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                    .stroke(
                                        perceivedFeeling == feeling
                                            ? Theme.Colors.primary
                                            : .clear,
                                        lineWidth: 1.5
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(feelingLabel(feeling))\(perceivedFeeling == feeling ? ", selected" : "")")
                    }
                }
            }

            // Terrain
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Terrain")
                    .font(.subheadline.bold())
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(TerrainType.allCases, id: \.self) { terrain in
                        Button {
                            terrainType = terrainType == terrain
                                ? nil
                                : terrain
                        } label: {
                            Text(terrainLabel(terrain))
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                        .fill(
                                            terrainType == terrain
                                                ? Theme.Colors.primary.opacity(0.15)
                                                : Theme.Colors.secondaryBackground
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                        .stroke(
                                            terrainType == terrain
                                                ? Theme.Colors.primary
                                                : .clear,
                                            lineWidth: 1.5
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(terrainLabel(terrain))\(terrainType == terrain ? ", selected" : "")")
                    }
                }
            }

            // Notes
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Notes")
                    .font(.subheadline.bold())
                TextField("How did it feel?", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Share Button

    var shareButton: some View {
        Button {
            Task { await exportAndShare() }
        } label: {
            Label("Share as GPX", systemImage: "square.and.arrow.up")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
        }
        .buttonStyle(.bordered)
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Linked Session Banner

    @ViewBuilder
    var linkedSessionBanner: some View {
        if let session = viewModel.linkedSession {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "link.circle.fill")
                    .foregroundStyle(Theme.Colors.primary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Linked Session")
                        .font(.caption.bold())
                    Text("\(session.type.rawValue.capitalized) — \(UnitFormatter.formatDistance(session.plannedDistanceKm, unit: units))")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundStyle(Theme.Colors.success)
                    .accessibilityHidden(true)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.primary.opacity(0.08))
            )
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    // MARK: - Auto Match Banner

    @ViewBuilder
    var autoMatchBanner: some View {
        if didSave, let match = viewModel.autoMatchedSession, viewModel.linkedSession == nil {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.Colors.primary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Linked to Session")
                        .font(.caption.bold())
                    Text("\(match.session.type.rawValue.capitalized) — \(UnitFormatter.formatDistance(match.session.plannedDistanceKm, unit: units))")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundStyle(Theme.Colors.success)
                    .accessibilityHidden(true)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.primary.opacity(0.08))
            )
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    // MARK: - Strava Upload

    @ViewBuilder
    var stravaUploadBanner: some View {
        switch viewModel.connectivityHandler.stravaUploadStatus {
        case .idle:
            EmptyView()
        case .uploading, .processing:
            HStack(spacing: Theme.Spacing.sm) {
                ProgressView()
                Text("Uploading to Strava...")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Color.orange.opacity(0.1))
            )
            .padding(.horizontal, Theme.Spacing.md)
            .accessibilityElement(children: .combine)
        case .success:
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
                Text("Uploaded to Strava")
                    .font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Color.green.opacity(0.1))
            )
            .padding(.horizontal, Theme.Spacing.md)
            .accessibilityElement(children: .combine)
        case .failed(let reason):
            VStack(spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.Colors.warning)
                        .accessibilityHidden(true)
                    Text("Strava upload failed")
                        .font(.subheadline.bold())
                }
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Button("Retry") {
                    Task { await viewModel.uploadToStrava() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityHint("Retry uploading run to Strava")
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.warning.opacity(0.1))
            )
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}
