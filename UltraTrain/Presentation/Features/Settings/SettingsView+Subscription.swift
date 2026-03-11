import SwiftUI

extension SettingsView {
    var subscriptionSection: some View {
        Section {
            Button {
                showingPaywall = true
            } label: {
                Label("settings.manageSubscription", systemImage: "crown")
            }
        } header: {
            Text("settings.subscription")
        }
        .sheet(isPresented: $showingPaywall) {
            if let service = subscriptionService {
                PaywallView(
                    subscriptionService: service,
                    firstName: viewModel.athlete?.firstName ?? "Runner",
                    isDismissable: true,
                    onSubscribed: {
                        showingPaywall = false
                    },
                    onDismiss: {
                        showingPaywall = false
                    }
                )
            }
        }
    }
}
