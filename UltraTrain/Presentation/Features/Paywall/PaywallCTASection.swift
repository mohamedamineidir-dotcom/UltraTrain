import SwiftUI

struct PaywallCTASection: View {
    let viewModel: PaywallViewModel

    var body: some View {
            VStack(spacing: Theme.Spacing.sm) {
                Button {
                    Task { await viewModel.purchase() }
                } label: {
                    Group {
                        if viewModel.isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(viewModel.ctaButtonTitle)
                                .font(.headline.bold())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.Gradients.warmCoralCTA)
                    .shadow(color: Theme.Colors.warmCoral.opacity(0.4), radius: 12, y: 4)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(viewModel.isPurchasing || viewModel.selectedPlanId == nil)
                .padding(.horizontal, Theme.Spacing.lg)
                .accessibilityIdentifier("paywall.subscribeButton")

                /// Reassurance line directly under the CTA — kills the
                /// implicit fear that lets users hesitate right before
                /// committing to the purchase.
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption2)
                    Text("paywall.cta.reassurance")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
                .padding(.top, 2)

                Button {
                    Task { await viewModel.restore() }
                } label: {
                    if viewModel.isRestoring {
                        ProgressView()
                            .tint(Color.secondary)
                    } else {
                        Text("paywall.restore")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(viewModel.isRestoring)
                .accessibilityIdentifier("paywall.restoreButton")

                // Apple 3.1.2 auto-renewable subscription disclosure: must be
                // visible in-app near the purchase, alongside functional EULA
                // (Terms) + Privacy links.
                Text("paywall.legal.autoRenew")
                    .font(.system(size: 10))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, 2)

                HStack(spacing: Theme.Spacing.md) {
                    Link("Terms", destination: URL(string: "https://ultratrain.app/terms")!)
                    Text("|").foregroundStyle(.tertiary)
                    Link("Privacy", destination: URL(string: "https://ultratrain.app/privacy")!)
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
    }
}
