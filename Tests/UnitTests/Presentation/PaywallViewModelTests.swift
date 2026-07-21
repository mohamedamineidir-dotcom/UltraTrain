import Foundation
import Testing
@testable import UltraTrain

@Suite("Paywall ViewModel Tests")
struct PaywallViewModelTests {

    private static let samplePlans: [SubscriptionPlan] = [
        SubscriptionPlan(
            id: "com.ultratrain.app.premium.yearly",
            period: .yearly,
            price: 49.99,
            pricePerWeek: 0.96,
            displayPrice: "49,99 €",
            displayPricePerWeek: "0,96 €",
            savingsPercent: 72
        ),
        SubscriptionPlan(
            id: "com.ultratrain.app.premium.monthly",
            period: .monthly,
            price: 14.99,
            pricePerWeek: 3.46,
            displayPrice: "14,99 €",
            displayPricePerWeek: "3,46 €",
            savingsPercent: nil
        )
    ]

    // MARK: - Initial State

    @Test("Initial state has no plans and is loading")
    @MainActor
    func initialState() {
        let service = MockSubscriptionService()
        let vm = PaywallViewModel(subscriptionService: service, firstName: "Kilian")
        #expect(vm.plans.isEmpty)
        #expect(vm.isLoading == true)
        #expect(vm.isPurchasing == false)
        #expect(vm.purchaseSucceeded == false)
        #expect(vm.firstName == "Kilian")
        #expect(vm.isDismissable == false)
    }

    // MARK: - Load Plans

    @Test("loadPlans populates plans and selects yearly by default")
    @MainActor
    func loadPlansSuccess() async {
        let service = MockSubscriptionService()
        service.plansToReturn = Self.samplePlans
        let vm = PaywallViewModel(subscriptionService: service, firstName: "Kilian")
        await vm.loadPlans()
        #expect(vm.plans.count == 2)
        #expect(vm.selectedPlanId == "com.ultratrain.app.premium.yearly")
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("loadPlans sets error on failure")
    @MainActor
    func loadPlansFailure() async {
        let service = MockSubscriptionService()
        service.shouldThrowOnFetch = true
        let vm = PaywallViewModel(subscriptionService: service, firstName: "Kilian")
        await vm.loadPlans()
        #expect(vm.plans.isEmpty)
        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    // MARK: - Purchase

    @Test("purchase sets purchaseSucceeded on success")
    @MainActor
    func purchaseSuccess() async {
        let service = MockSubscriptionService()
        service.plansToReturn = Self.samplePlans
        let vm = PaywallViewModel(subscriptionService: service, firstName: "Kilian")
        await vm.loadPlans()
        vm.selectedPlanId = "com.ultratrain.app.premium.monthly"
        await vm.purchase()
        #expect(vm.purchaseSucceeded == true)
        #expect(service.purchaseCalled == true)
        #expect(service.purchasedProductId == "com.ultratrain.app.premium.monthly")
    }

    @Test("purchase shows error on failure")
    @MainActor
    func purchaseFailure() async {
        let service = MockSubscriptionService()
        service.plansToReturn = Self.samplePlans
        service.shouldThrowOnPurchase = true
        let vm = PaywallViewModel(subscriptionService: service, firstName: "Kilian")
        await vm.loadPlans()
        vm.selectedPlanId = "com.ultratrain.app.premium.monthly"
        await vm.purchase()
        #expect(vm.purchaseSucceeded == false)
        #expect(vm.error != nil)
    }

    @Test("purchase does nothing without selected plan")
    @MainActor
    func purchaseNoSelection() async {
        let service = MockSubscriptionService()
        let vm = PaywallViewModel(subscriptionService: service, firstName: "Kilian")
        vm.selectedPlanId = nil
        await vm.purchase()
        #expect(service.purchaseCalled == false)
    }

    // MARK: - Restore

    @Test("restore sets purchaseSucceeded when active subscription found")
    @MainActor
    func restoreSuccess() async {
        let service = MockSubscriptionService()
        service.currentStatus = SubscriptionStatus(
            isActive: true, tier: .premium, expirationDate: Date.now.addingTimeInterval(86400),
            isInTrialPeriod: false, willAutoRenew: true, productId: "yearly"
        )
        let vm = PaywallViewModel(subscriptionService: service, firstName: "Kilian")
        await vm.restore()
        #expect(vm.purchaseSucceeded == true)
        #expect(service.restoreCalled == true)
    }

    @Test("restore shows error when no active subscription")
    @MainActor
    func restoreNoSubscription() async {
        let service = MockSubscriptionService()
        let vm = PaywallViewModel(subscriptionService: service, firstName: "Kilian")
        await vm.restore()
        #expect(vm.purchaseSucceeded == false)
        #expect(vm.error != nil)
    }

    @Test("restore shows error on failure")
    @MainActor
    func restoreFailure() async {
        let service = MockSubscriptionService()
        service.shouldThrowOnRestore = true
        let vm = PaywallViewModel(subscriptionService: service, firstName: "Kilian")
        await vm.restore()
        #expect(vm.purchaseSucceeded == false)
        #expect(vm.error != nil)
    }

    // MARK: - CTA Title

    @Test("CTA title always shows Subscribe Now")
    @MainActor
    func ctaTitle() async {
        let service = MockSubscriptionService()
        service.plansToReturn = Self.samplePlans
        let vm = PaywallViewModel(subscriptionService: service, firstName: "Kilian")
        await vm.loadPlans()
        #expect(vm.ctaButtonTitle == String(localized: "paywall.subscribe"))
    }

    // MARK: - Dismissability

    @Test("isDismissable defaults to false")
    @MainActor
    func notDismissableByDefault() {
        let service = MockSubscriptionService()
        let vm = PaywallViewModel(subscriptionService: service, firstName: "Kilian")
        #expect(vm.isDismissable == false)
    }

    @Test("isDismissable can be set to true")
    @MainActor
    func dismissableFromSettings() {
        let service = MockSubscriptionService()
        let vm = PaywallViewModel(subscriptionService: service, firstName: "Kilian", isDismissable: true)
        #expect(vm.isDismissable == true)
    }
}
