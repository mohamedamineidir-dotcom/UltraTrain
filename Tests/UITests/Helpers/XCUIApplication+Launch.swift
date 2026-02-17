import XCTest

extension XCUIApplication {

    /// Launches in UI test mode with an empty database.
    /// Onboarding will be shown.
    static func launchForOnboardingTest() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestMode"]
        app.launch()
        return app
    }

    /// Launches in UI test mode with seeded test data.
    /// Onboarding is skipped — the app opens to MainTabView.
    static func launchWithTestData() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestMode", "-UITestSkipOnboarding"]
        app.launch()
        return app
    }
}
