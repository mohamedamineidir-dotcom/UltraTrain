import SwiftUI

struct PaywallView: View {
    @Environment(\.colorScheme) private var colorScheme
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
            Group {
                if colorScheme == .dark {
                    Theme.Gradients.premiumBackground
                } else {
                    LinearGradient(
                        colors: [
                            Color(red: 0.96, green: 0.95, blue: 1.0),
                            Color(red: 0.97, green: 0.96, blue: 1.0),
                            Color(red: 0.95, green: 0.97, blue: 0.99)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .tint(Color.primary)
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
                            .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)
                }
                .padding(Theme.Spacing.md)
            }
        }
        .task {
            viewModel.onSubscribed = onSubscribed
            await viewModel.loadPlans()
        }
        .onChange(of: viewModel.purchaseSucceeded) { _, succeeded in
            if succeeded { onSubscribed() }
        }
    }
}
