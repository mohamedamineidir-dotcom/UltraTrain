import SwiftUI

struct PaywallView: View {
    @State var viewModel: PaywallViewModel
    var onSubscribed: () -> Void
    var onDismiss: (() -> Void)?

    init(
        subscriptionService: any SubscriptionServiceProtocol,
        firstName: String,
        isDismissable: Bool = false,
        onSubscribed: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: PaywallViewModel(
            subscriptionService: subscriptionService,
            firstName: firstName,
            isDismissable: isDismissable
        ))
        self.onSubscribed = onSubscribed
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            Theme.Gradients.premiumBackground
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        PaywallHeaderSection(firstName: viewModel.firstName)
                        PaywallFeatureBullets()
                        PaywallPlanSelector(
                            plans: viewModel.plans,
                            selectedPlanId: $viewModel.selectedPlanId
                        )
                        Text("paywall.pricesInEUR")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                        PaywallTrialTimeline()

                        if let error = viewModel.error {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.Spacing.lg)
                        }
                    }
                    .padding(.bottom, 140)
                }

                PaywallCTASection(viewModel: viewModel)
            }
        }
        .overlay(alignment: .topTrailing) {
            if viewModel.isDismissable {
                Button {
                    onDismiss?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(Theme.Spacing.md)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadPlans()
        }
        .onChange(of: viewModel.purchaseSucceeded) { _, succeeded in
            if succeeded { onSubscribed() }
        }
    }
}
