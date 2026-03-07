import SwiftUI

struct WelcomeClubView: View {
    let firstName: String
    let referralRepository: any ReferralRepository
    let onContinue: () -> Void

    @State private var showReferralField = false
    @State private var referralCode = ""
    @State private var isApplyingCode = false
    @State private var referralSuccess = false
    @State private var referralError: String?

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xxl) {
                Spacer()

                // Welcome illustration
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.accentColor)

                // Welcome text
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Welcome to the club\(firstName.isEmpty ? "" : ",")")
                        .font(.title)
                        .fontWeight(.bold)

                    if !firstName.isEmpty {
                        Text("\(firstName)!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)
                    }

                    Text("You're about to start your trail running journey.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.top, Theme.Spacing.xs)
                }

                Spacer()

                // Referral section
                VStack(spacing: Theme.Spacing.md) {
                    if !showReferralField {
                        Button {
                            withAnimation { showReferralField = true }
                        } label: {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "ticket.fill")
                                Text("Have a friend's code?")
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.accentColor)
                        }
                    } else {
                        referralInputSection
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)

                // Continue button
                PrimaryOnboardingButton(title: "Let's Get Started") {
                    onContinue()
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.lg)
            }
        }
        .navigationBarBackButtonHidden()
    }

    private var referralInputSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                OnboardingTextField(
                    placeholder: "Enter referral code",
                    text: $referralCode,
                    autocapitalization: .characters
                )

                Button {
                    Task { await applyReferralCode() }
                } label: {
                    if isApplyingCode {
                        ProgressView()
                            .frame(width: 50, height: 52)
                    } else {
                        Text("Apply")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(width: 70, height: 52)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .disabled(referralCode.count < 8 || isApplyingCode)
            }

            if referralSuccess {
                Label("Code applied! You'll get 2 extra free weeks.", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.success)
            }

            if let error = referralError {
                Label(error, systemImage: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.danger)
            }
        }
    }

    private func applyReferralCode() async {
        isApplyingCode = true
        referralError = nil
        referralSuccess = false

        do {
            try await referralRepository.applyReferralCode(referralCode.uppercased())
            referralSuccess = true
        } catch {
            referralError = "Invalid or expired code"
        }

        isApplyingCode = false
    }
}
