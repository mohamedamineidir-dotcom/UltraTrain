import Foundation
import Testing
@testable import UltraTrain

@Suite("ForgotPasswordViewModel Tests")
struct ForgotPasswordViewModelTests {

    @MainActor
    private func makeSUT(shouldFail: Bool = false) -> (MockAuthService, ForgotPasswordViewModel) {
        let auth = MockAuthService()
        auth.shouldFail = shouldFail
        let vm = ForgotPasswordViewModel(authService: auth)
        return (auth, vm)
    }

    // MARK: - requestReset

    @Test("requestReset with empty email shows error")
    @MainActor
    func requestResetEmptyEmail() async {
        let (_, vm) = makeSUT()
        vm.email = ""

        await vm.requestReset()

        #expect(vm.error == "Please enter your email")
        #expect(vm.step == .enterEmail)
    }

    @Test("requestReset success advances to enterCode step")
    @MainActor
    func requestResetSuccess() async {
        let (auth, vm) = makeSUT()
        vm.email = "test@example.com"

        await vm.requestReset()

        #expect(vm.step == .enterCode)
        #expect(vm.error == nil)
        #expect(auth.requestPasswordResetCallCount == 1)
    }

    @Test("requestReset failure shows error message")
    @MainActor
    func requestResetFailure() async {
        let (_, vm) = makeSUT(shouldFail: true)
        vm.email = "test@example.com"

        await vm.requestReset()

        #expect(vm.error != nil)
        #expect(vm.step == .enterEmail)
    }

    @Test("requestReset clears loading state after completion")
    @MainActor
    func requestResetClearsLoading() async {
        let (_, vm) = makeSUT()
        vm.email = "test@example.com"

        await vm.requestReset()

        #expect(vm.isLoading == false)
    }

    // MARK: - resetPassword

    @Test("resetPassword with empty fields shows error")
    @MainActor
    func resetPasswordEmptyFields() async {
        let (_, vm) = makeSUT()
        vm.code = ""
        vm.newPassword = ""

        await vm.resetPassword()

        #expect(vm.error == "Please fill in all fields")
        #expect(vm.isResetComplete == false)
    }

    @Test("resetPassword with short password shows error")
    @MainActor
    func resetPasswordShortPassword() async {
        let (_, vm) = makeSUT()
        vm.code = "123456"
        vm.newPassword = "short"

        await vm.resetPassword()

        #expect(vm.error == "Password must be at least 8 characters")
        #expect(vm.isResetComplete == false)
    }

    @Test("resetPassword success sets isResetComplete")
    @MainActor
    func resetPasswordSuccess() async {
        let (auth, vm) = makeSUT()
        vm.email = "test@example.com"
        vm.code = "123456"
        vm.newPassword = "newpassword123"

        await vm.resetPassword()

        #expect(vm.isResetComplete == true)
        #expect(vm.error == nil)
        #expect(auth.resetPasswordCallCount == 1)
    }

    @Test("resetPassword failure shows error")
    @MainActor
    func resetPasswordFailure() async {
        let (_, vm) = makeSUT(shouldFail: true)
        vm.email = "test@example.com"
        vm.code = "123456"
        vm.newPassword = "newpassword123"

        await vm.resetPassword()

        #expect(vm.isResetComplete == false)
        #expect(vm.error != nil)
    }

    @Test("resetPassword clears loading state")
    @MainActor
    func resetPasswordClearsLoading() async {
        let (_, vm) = makeSUT()
        vm.code = "123456"
        vm.newPassword = "newpassword123"

        await vm.resetPassword()

        #expect(vm.isLoading == false)
    }
}
