import SwiftUI

struct WelcomeClubView: View {
    @Environment(\.colorScheme) private var colorScheme
    let firstName: String
    let referralRepository: any ReferralRepository
    let onContinue: () -> Void

    @State private var showReferralField = false
    @State private var referralCode = ""
    @State private var isApplyingCode = false
    @State private var referralSuccess = false
    @State private var referralError: String?
    @State private var showContent = false

    var body: some View {
        ZStack {
            background
            content
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                showContent = true
            }
        }
    }

    private var background: some View {
        Group {
            if colorScheme == .dark {
                Theme.Gradients.premiumBackground
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.96, blue: 0.94),
                        Color(red: 1.0, green: 0.97, blue: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }

    private var content: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Spacer()

            // Welcome illustration + text
            VStack(spacing: Theme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.warmCoral.opacity(0.12))
                        .frame(width: 110, height: 110)

                    Image("LaunchIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .colorMultiply(Theme.Colors.warmCoral)
                }
                .shadow(color: Theme.Colors.warmCoral.opacity(0.2), radius: 20, y: 6)
                .scaleEffect(showContent ? 1 : 0.6)
                .opacity(showContent ? 1 : 0)

                VStack(spacing: Theme.Spacing.sm) {
                    Text("Welcome to the club\(firstName.isEmpty ? "" : ",")")
                        .font(.title2)
                        .fontWeight(.bold)

                    if !firstName.isEmpty {
                        Text("\(firstName)!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.Colors.warmCoral)
                    }

                    Text("You're about to start your trail running journey.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.xs)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 12)
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
                        .foregroundStyle(Theme.Colors.warmCoral)
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
                            .background(Theme.Gradients.warmCoralCTA)
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
