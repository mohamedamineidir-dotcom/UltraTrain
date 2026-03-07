import SwiftUI

struct ReferralSettingsView: View {
    @State private var viewModel: ReferralSettingsViewModel
    @State private var showingShareSheet = false

    init(referralRepository: any ReferralRepository) {
        _viewModel = State(initialValue: ReferralSettingsViewModel(
            referralRepository: referralRepository
        ))
    }

    var body: some View {
        List {
            if viewModel.isLoading {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            } else if let code = viewModel.referralCode {
                codeSection(code: code)
                statsSection
            }
        }
        .navigationTitle("Refer a Friend")
        .task { await viewModel.load() }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [viewModel.shareText])
        }
    }

    private func codeSection(code: String) -> some View {
        Section {
            VStack(spacing: Theme.Spacing.md) {
                Text("Your Referral Code")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)

                Text(code)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .kerning(4)

                Text("Share this code with friends to invite them to UltraTrain.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)

            Button {
                UIPasteboard.general.string = code
            } label: {
                Label("Copy Code", systemImage: "doc.on.doc")
            }

            Button {
                showingShareSheet = true
            } label: {
                Label("Share with Friends", systemImage: "square.and.arrow.up")
            }
        }
    }

    private var statsSection: some View {
        Section("Stats") {
            LabeledContent("Friends Referred", value: "\(viewModel.referralCount)")
        }
    }
}
