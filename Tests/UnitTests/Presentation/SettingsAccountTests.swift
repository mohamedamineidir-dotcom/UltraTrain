import Foundation
import Testing
@testable import UltraTrain

@Suite("Settings Account Tests")
struct SettingsAccountTests {

    @MainActor
    private func makeSUT(authShouldFail: Bool = false) -> (MockAuthService, MockClearAllDataUseCase, SettingsViewModel) {
        let auth = MockAuthService()
        auth.isLoggedIn = true
        auth.shouldFail = authShouldFail
        let clearData = MockClearAllDataUseCase()
        let vm = SettingsViewModel(
            athleteRepository: MockAthleteRepository(),
            appSettingsRepository: MockAppSettingsRepository(),
            clearAllDataUseCase: clearData,
            healthKitService: MockHealthKitService(),
            exportService: MockExportService(),
            runRepository: MockRunRepository(),
            stravaAuthService: MockStravaAuthService(),
            notificationService: MockNotificationService(),
            planRepository: MockTrainingPlanRepository(),
            raceRepository: MockRaceRepository(),
            biometricAuthService: MockBiometricAuthService(),
            authService: auth
        )
        return (auth, clearData, vm)
    }

    // MARK: - Change Password

    @Test("changePassword with empty fields shows error")
    @MainActor
    func changePasswordEmptyFields() async {
        let (_, _, vm) = makeSUT()
        vm.currentPassword = ""
        vm.newPassword = ""
        vm.confirmPassword = ""

        await vm.changePassword()

        #expect(vm.error == "Please fill in all fields")
        #expect(vm.changePasswordSuccess == false)
    }

    @Test("changePassword with short new password shows error")
    @MainActor
    func changePasswordShortNewPassword() async {
        let (_, _, vm) = makeSUT()
        vm.currentPassword = "oldpassword"
        vm.newPassword = "short"
        vm.confirmPassword = "short"

        await vm.changePassword()

        #expect(vm.error == "New password must be at least 8 characters")
    }

    @Test("changePassword with mismatched passwords shows error")
    @MainActor
    func changePasswordMismatch() async {
        let (_, _, vm) = makeSUT()
        vm.currentPassword = "oldpassword"
        vm.newPassword = "newpassword123"
        vm.confirmPassword = "different123"

        await vm.changePassword()

        #expect(vm.error == "New passwords do not match")
    }

    @Test("changePassword success clears fields and sets flag")
    @MainActor
    func changePasswordSuccess() async {
        let (auth, _, vm) = makeSUT()
        vm.currentPassword = "oldpassword"
        vm.newPassword = "newpassword123"
        vm.confirmPassword = "newpassword123"

        await vm.changePassword()

        #expect(vm.changePasswordSuccess == true)
        #expect(vm.currentPassword.isEmpty)
        #expect(vm.newPassword.isEmpty)
        #expect(vm.confirmPassword.isEmpty)
        #expect(vm.error == nil)
        #expect(auth.changePasswordCallCount == 1)
    }

    @Test("changePassword failure shows error")
    @MainActor
    func changePasswordFailure() async {
        let (_, _, vm) = makeSUT(authShouldFail: true)
        vm.currentPassword = "oldpassword"
        vm.newPassword = "newpassword123"
        vm.confirmPassword = "newpassword123"

        await vm.changePassword()

        #expect(vm.changePasswordSuccess == false)
        #expect(vm.error != nil)
    }

    @Test("changePassword clears loading state")
    @MainActor
    func changePasswordClearsLoading() async {
        let (_, _, vm) = makeSUT()
        vm.currentPassword = "oldpassword"
        vm.newPassword = "newpassword123"
        vm.confirmPassword = "newpassword123"

        await vm.changePassword()

        #expect(vm.isChangingPassword == false)
    }

    // MARK: - Delete Account

    @Test("deleteAccount calls auth service and clears data")
    @MainActor
    func deleteAccountSuccess() async {
        let (auth, clearData, vm) = makeSUT()

        await vm.deleteAccount()

        #expect(auth.deleteAccountCallCount == 1)
        #expect(clearData.executeCalled == true)
        #expect(vm.didLogout == true)
        #expect(vm.isDeletingAccount == false)
    }

    @Test("deleteAccount failure shows error")
    @MainActor
    func deleteAccountFailure() async {
        let (_, _, vm) = makeSUT(authShouldFail: true)

        await vm.deleteAccount()

        #expect(vm.error != nil)
        #expect(vm.didLogout == false)
        #expect(vm.isDeletingAccount == false)
    }

    // MARK: - Logout

    @Test("logout calls auth service and sets didLogout")
    @MainActor
    func logoutSuccess() async {
        let (auth, _, vm) = makeSUT()

        await vm.logout()

        #expect(auth.logoutCallCount == 1)
        #expect(vm.didLogout == true)
    }

    @Test("logout failure shows error")
    @MainActor
    func logoutFailure() async {
        let (_, _, vm) = makeSUT(authShouldFail: true)

        await vm.logout()

        #expect(vm.error != nil)
        #expect(vm.didLogout == false)
    }
}
