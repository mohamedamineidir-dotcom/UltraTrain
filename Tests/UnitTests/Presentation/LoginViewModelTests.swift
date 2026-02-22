import Foundation
import Testing
@testable import UltraTrain

@Suite("LoginViewModel Tests")
struct LoginViewModelTests {

    @MainActor
    private func makeViewModel(
        authService: MockAuthService = MockAuthService()
    ) -> (LoginViewModel, MockAuthService) {
        let vm = LoginViewModel(authService: authService)
        return (vm, authService)
    }

    // MARK: - Initial State

    @Test("Initial state has empty fields and no error")
    @MainActor
    func initialState() {
        let (vm, _) = makeViewModel()
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
        #expect(vm.email.isEmpty)
        #expect(vm.password.isEmpty)
        #expect(vm.isAuthenticated == false)
        #expect(vm.isRegistering == false)
    }

    // MARK: - Validation

    @Test("Submit with empty email shows error")
    @MainActor
    func submitWithEmptyEmailShowsError() async {
        let (vm, _) = makeViewModel()
        vm.email = ""
        vm.password = "password123"

        await vm.submit()

        #expect(vm.error == "Please enter email and password")
    }

    @Test("Submit with empty password shows error")
    @MainActor
    func submitWithEmptyPasswordShowsError() async {
        let (vm, _) = makeViewModel()
        vm.email = "runner@test.com"
        vm.password = ""

        await vm.submit()

        #expect(vm.error == "Please enter email and password")
    }

    // MARK: - Login

    @Test("Submit calls login when isRegistering is false")
    @MainActor
    func submitCallsLogin() async {
        let (vm, mock) = makeViewModel()
        vm.email = "runner@test.com"
        vm.password = "password123"
        vm.isRegistering = false

        await vm.submit()

        #expect(mock.loginCallCount == 1)
        #expect(mock.registerCallCount == 0)
        #expect(mock.lastEmail == "runner@test.com")
        #expect(mock.lastPassword == "password123")
    }

    // MARK: - Register

    @Test("Submit calls register when isRegistering is true")
    @MainActor
    func submitCallsRegister() async {
        let (vm, mock) = makeViewModel()
        vm.email = "newrunner@test.com"
        vm.password = "securepass"
        vm.isRegistering = true

        await vm.submit()

        #expect(mock.registerCallCount == 1)
        #expect(mock.loginCallCount == 0)
        #expect(mock.lastEmail == "newrunner@test.com")
        #expect(mock.lastPassword == "securepass")
    }

    // MARK: - Success

    @Test("Successful login sets isAuthenticated to true")
    @MainActor
    func successfulLoginSetsAuthenticated() async {
        let (vm, _) = makeViewModel()
        vm.email = "runner@test.com"
        vm.password = "password123"

        await vm.submit()

        #expect(vm.isAuthenticated == true)
        #expect(vm.error == nil)
        #expect(vm.isLoading == false)
    }

    // MARK: - Failure

    @Test("Failed login sets error message")
    @MainActor
    func failedLoginSetsError() async {
        let mock = MockAuthService()
        mock.shouldFail = true
        let (vm, _) = makeViewModel(authService: mock)
        vm.email = "runner@test.com"
        vm.password = "wrongpass"

        await vm.submit()

        #expect(vm.error != nil)
        #expect(vm.isAuthenticated == false)
        #expect(vm.isLoading == false)
    }

    // MARK: - Toggle

    @Test("isRegistering toggle works")
    @MainActor
    func isRegisteringToggle() {
        let (vm, _) = makeViewModel()
        #expect(vm.isRegistering == false)
        vm.isRegistering = true
        #expect(vm.isRegistering == true)
        vm.isRegistering = false
        #expect(vm.isRegistering == false)
    }

    // MARK: - Logout

    @Test("Logout clears state")
    @MainActor
    func logoutClearsState() async {
        let (vm, _) = makeViewModel()
        vm.email = "runner@test.com"
        vm.password = "password123"

        await vm.submit()
        #expect(vm.isAuthenticated == true)

        await vm.logout()

        #expect(vm.isAuthenticated == false)
        #expect(vm.email.isEmpty)
        #expect(vm.password.isEmpty)
    }

    @Test("Logout increments logout call count")
    @MainActor
    func logoutCallsService() async {
        let (vm, mock) = makeViewModel()
        vm.email = "runner@test.com"
        vm.password = "password123"
        await vm.submit()

        await vm.logout()

        #expect(mock.logoutCallCount == 1)
    }
}
