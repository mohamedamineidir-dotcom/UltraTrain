import SwiftUI

struct SocialProfileView: View {
    @State private var viewModel: SocialProfileViewModel

    init(
        profileRepository: any SocialProfileRepository,
        athleteRepository: any AthleteRepository,
        runRepository: any RunRepository
    ) {
        _viewModel = State(initialValue: SocialProfileViewModel(
            profileRepository: profileRepository,
            athleteRepository: athleteRepository,
            runRepository: runRepository
        ))
    }

    var body: some View {
        Form {
            if viewModel.isLoading {
                ProgressView()
            } else {
                profileFieldsSection
                privacySection
                if let profile = viewModel.profile {
                    statsSection(profile)
                }
                saveSection
            }
        }
        .navigationTitle("Social Profile")
        .task {
            await viewModel.load()
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

    // MARK: - Profile Fields

    private var profileFieldsSection: some View {
        Section("Profile") {
            TextField("Display Name", text: $viewModel.displayName)
                .textContentType(.name)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Bio")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                TextEditor(text: $viewModel.bio)
                    .frame(minHeight: 60)
                    .overlay(alignment: .bottomTrailing) {
                        Text("\(viewModel.bio.count)/160")
                            .font(.caption2)
                            .foregroundStyle(
                                viewModel.bio.count > 160
                                    ? Theme.Colors.danger
                                    : Theme.Colors.secondaryLabel
                            )
                            .padding(Theme.Spacing.xs)
                    }
                    .onChange(of: viewModel.bio) { _, newValue in
                        if newValue.count > 160 {
                            viewModel.bio = String(newValue.prefix(160))
                        }
                    }
            }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        Section("Privacy") {
            Toggle("Public Profile", isOn: $viewModel.isPublicProfile)
            if viewModel.isPublicProfile {
                Label(
                    "Your stats and activity will be visible to all users.",
                    systemImage: "eye"
                )
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }

    // MARK: - Stats

    private func statsSection(_ profile: SocialProfile) -> some View {
        Section("Stats") {
            HStack(spacing: Theme.Spacing.lg) {
                statColumn(value: "\(profile.totalRuns)", label: "Runs")
                Divider()
                statColumn(
                    value: String(format: "%.0f km", profile.totalDistanceKm),
                    label: "Distance"
                )
                Divider()
                statColumn(
                    value: String(format: "%.0f m", profile.totalElevationGainM),
                    label: "Elevation"
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
        }
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(value)
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Save

    private var saveSection: some View {
        Section {
            Button {
                Task { await viewModel.save() }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Text("Save Profile")
                    }
                    Spacer()
                }
            }
            .disabled(viewModel.displayName.isEmpty || viewModel.isSaving)
        }
    }
}
