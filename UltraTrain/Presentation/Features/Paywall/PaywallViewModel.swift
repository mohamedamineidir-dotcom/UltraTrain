import Foundation
import os

@Observable
@MainActor
final class PaywallViewModel {

    // MARK: - Dependencies

    private let subscriptionService: any SubscriptionServiceProtocol

    // MARK: - State

    var plans: [SubscriptionPlan] = []
    var selectedPlanId: String?
    var isLoading = true
    var isPurchasing = false
    var isRestoring = false
    var error: String?
    var purchaseSucceeded = false

    // MARK: - Callbacks

    var onSubscribed: (() -> Void)?

    // MARK: - User Info

    let firstName: String
    let isDismissable: Bool

    // MARK: - Init

    init(
        subscriptionService: any SubscriptionServiceProtocol,
        firstName: String,
        isDismissable: Bool = false
    ) {
        self.subscriptionService = subscriptionService
        self.firstName = firstName
        self.isDismissable = isDismissable
    }

    // MARK: - Load Plans

    func loadPlans() async {
        isLoading = true
        error = nil
        do {
            plans = try await subscriptionService.fetchPlans()
            selectedPlanId = plans.first(where: { $0.period == .yearly })?.id
                ?? plans.first?.id
        } catch {
            self.error = String(localized: "paywall.loadError")
            Logger.subscription.error("Failed to load plans: \(error)")
        }
        isLoading = false
    }

    // MARK: - Purchase

    func purchase() async {
        guard let planId = selectedPlanId, !isPurchasing else { return }
        isPurchasing = true
        error = nil
        do {
            let status = try await subscriptionService.purchase(productId: planId)
            if status.isActive {
                purchaseSucceeded = true
                onSubscribed?()
            }
        } catch {
            self.error = String(localized: "paywall.purchaseError")
            Logger.subscription.error("Purchase failed: \(error)")
        }
        isPurchasing = false
    }

    // MARK: - Restore

    func restore() async {
        guard !isRestoring else { return }
        isRestoring = true
        error = nil
        do {
            let status = try await subscriptionService.restorePurchases()
            if status.isActive {
                purchaseSucceeded = true
                onSubscribed?()
            } else {
                self.error = String(localized: "paywall.noSubscriptionFound")
            }
        } catch {
            self.error = String(localized: "paywall.restoreError")
            Logger.subscription.error("Restore failed: \(error)")
        }
        isRestoring = false
    }

    // MARK: - Computed

    var selectedPlan: SubscriptionPlan? {
        plans.first { $0.id == selectedPlanId }
    }

    var ctaButtonTitle: String {
        if let plan = selectedPlan, plan.trialDays != nil {
            return String(localized: "paywall.startTrial")
        }
        return String(localized: "paywall.subscribe")
    }
}
