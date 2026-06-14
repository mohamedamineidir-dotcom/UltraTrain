import SwiftUI

/// Attractive referral page: highlights the "7 days free" reward, shows the
/// athlete's code, a prominent share CTA, and (for referred users who haven't
/// earned it yet) a "1/2 done" progress nudge to refer a friend.
struct ReferralRewardView: View {
    @State private var viewModel: ReferralSettingsViewModel
    @State private var showingShareSheet = false
    @State private var copied = false
    @Environment(\.colorScheme) private var colorScheme

    init(referralRepository: any ReferralRepository) {
        _viewModel = State(initialValue: ReferralSettingsViewModel(
            referralRepository: referralRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                heroCard
                if viewModel.hasActiveBonus {
                    activeBonusBanner
                }
                progressCard
                if let code = viewModel.referralCode {
                    codeCard(code: code)
                    shareButton
                }
                statsRow
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Gradients.futuristicBackground(colorScheme: colorScheme).ignoresSafeArea())
        .navigationTitle(String(localized: "referral.title", defaultValue: "Refer & earn"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: { Text(viewModel.error ?? "") }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [viewModel.shareText])
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "gift.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white)
                .frame(width: 80, height: 80)
                .background(Circle().fill(Theme.Gradients.warmCoralCTA))
                .shadow(color: Theme.Colors.warmCoral.opacity(0.4), radius: 12, y: 6)

            Text(String(localized: "referral.hero.title", defaultValue: "Get 7 days free"))
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(String(localized: "referral.hero.sub", defaultValue: "Share your code. When a friend joins UltraTrain with it, you get 7 days of full access, free."))
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.md)
    }

    private var activeBonusBanner: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.Colors.success)
            Text(String(localized: "referral.bonus.active", defaultValue: "\(viewModel.bonusDaysRemaining) free days active"))
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).fill(Theme.Colors.success.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).stroke(Theme.Colors.success.opacity(0.35), lineWidth: 1))
    }

    // MARK: - Progress / how it works

    @ViewBuilder
    private var progressCard: some View {
        if viewModel.rewardClaimed {
            // Already earned the one-time reward.
            infoCard(
                title: String(localized: "referral.done.title", defaultValue: "Reward unlocked 🎉"),
                lines: [(true, String(localized: "referral.done.line", defaultValue: "You've earned your 7 free days. Thanks for spreading the word!"))]
            )
        } else if viewModel.wasReferred {
            // Referred friend, 1/2 done → refer someone to unlock their 7 days.
            infoCard(
                title: String(localized: "referral.progress.title", defaultValue: "You're halfway to 7 free days"),
                lines: [
                    (true, String(localized: "referral.progress.step1", defaultValue: "You joined with a friend's code")),
                    (false, String(localized: "referral.progress.step2", defaultValue: "Refer a friend who signs up — and your 7 days unlock"))
                ]
            )
        } else {
            infoCard(
                title: String(localized: "referral.how.title", defaultValue: "How it works"),
                lines: [
                    (false, String(localized: "referral.how.step1", defaultValue: "Share your code below with a friend")),
                    (false, String(localized: "referral.how.step2", defaultValue: "They sign up and enter it during registration")),
                    (false, String(localized: "referral.how.step3", defaultValue: "You get 7 days of UltraTrain free (one-time)"))
                ]
            )
        }
    }

    private func infoCard(title: String, lines: [(done: Bool, text: String)]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    HStack(spacing: Theme.Spacing.md) {
                        stepBadge(number: index + 1, done: line.done)
                        Text(line.text)
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.label)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 52)

                    if index < lines.count - 1 {
                        Divider().overlay(Color.primary.opacity(0.06))
                    }
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    /// Uniform leading badge for a "how it works" step: a numbered coral disc,
    /// or a green check once that step is done. Fixed size so every row aligns.
    private func stepBadge(number: Int, done: Bool) -> some View {
        ZStack {
            Circle()
                .fill(done ? Theme.Colors.success : Theme.Colors.warmCoral.opacity(0.15))
            if done {
                Image(systemName: "checkmark")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
            } else {
                Text("\(number)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.Colors.warmCoral)
            }
        }
        .frame(width: 30, height: 30)
    }

    // MARK: - Code

    private func codeCard(code: String) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(String(localized: "referral.yourCode", defaultValue: "Your referral code"))
                .font(.caption).foregroundStyle(Theme.Colors.secondaryLabel)
            Text(code)
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .kerning(4)
            Button {
                UIPasteboard.general.string = code
                withAnimation { copied = true }
            } label: {
                Label(copied ? String(localized: "referral.copied", defaultValue: "Copied!") : String(localized: "referral.copy", defaultValue: "Copy code"),
                      systemImage: copied ? "checkmark" : "doc.on.doc")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.Colors.warmCoral)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).stroke(Theme.Colors.warmCoral.opacity(0.3), lineWidth: 1))
    }

    private var shareButton: some View {
        Button {
            showingShareSheet = true
        } label: {
            Label(String(localized: "referral.share", defaultValue: "Share my code"), systemImage: "square.and.arrow.up")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Theme.Gradients.warmCoralCTA)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Theme.Colors.warmCoral.opacity(0.3), radius: 8, y: 4)
        }
    }

    private var statsRow: some View {
        HStack {
            Text(String(localized: "referral.friendsReferred", defaultValue: "Friends referred"))
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
            Text("\(viewModel.referralCount)").font(.headline)
        }
        .font(.subheadline)
        .padding(.horizontal, Theme.Spacing.xs)
    }
}
