import XCTest

final class SettingsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    private func navigateToSettings(_ app: XCUIApplication) {
        app.tabBars.buttons["Profile"].waitAndTap()
        let settingsButton = app.buttons["profile.settingsButton"]
        settingsButton.waitAndTap()
    }

    // MARK: - Tests

    @MainActor
    func testSettingsShowsNotificationToggles() throws {
        let app = XCUIApplication.launchWithTestData()
        navigateToSettings(app)
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        let trainingToggle = app.switches["settings.trainingRemindersToggle"]
        XCTAssertTrue(trainingToggle.waitForExistence(timeout: 5))
        let raceToggle = app.switches["settings.raceCountdownToggle"]
        XCTAssertTrue(raceToggle.waitForExistence(timeout: 5))
    }

    @MainActor
    func testSettingsShowsAutoPause() throws {
        let app = XCUIApplication.launchWithTestData()
        navigateToSettings(app)
        let autoPause = app.switches["settings.autoPauseToggle"]
        XCTAssertTrue(autoPause.waitForExistence(timeout: 5))
    }

    @MainActor
    func testExportButtonExists() throws {
        let app = XCUIApplication.launchWithTestData()
        navigateToSettings(app)
        let exportButton = app.buttons["settings.exportButton"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testClearDataShowsConfirmation() throws {
        let app = XCUIApplication.launchWithTestData()
        navigateToSettings(app)
        let clearButton = app.buttons["settings.clearDataButton"]
        if clearButton.waitForExistence(timeout: 5) {
            clearButton.tap()
            // Should show confirmation alert
            XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 3))
        }
    }
}
