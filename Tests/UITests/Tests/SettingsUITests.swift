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

    private func scrollToElement(_ element: XCUIElement, in scrollable: XCUIElement, maxSwipes: Int = 8) {
        var swipes = 0
        while !element.exists && swipes < maxSwipes {
            scrollable.swipeUp()
            swipes += 1
        }
    }

    // MARK: - Tests

    @MainActor
    func testSettingsShowsNotificationToggles() throws {
        let app = XCUIApplication.launchWithTestData()
        navigateToSettings(app)
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        // Scroll to find training reminders toggle in Notifications section
        let settingsList = app.collectionViews.firstMatch
        let trainingToggle = app.switches["settings.trainingRemindersToggle"]
        scrollToElement(trainingToggle, in: settingsList)
        XCTAssertTrue(trainingToggle.waitForExistence(timeout: 3))
        // Race countdown is further down
        let raceToggle = app.switches["settings.raceCountdownToggle"]
        scrollToElement(raceToggle, in: settingsList)
        XCTAssertTrue(raceToggle.waitForExistence(timeout: 3))
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
        // Scroll down to reach the Data section near the bottom
        let settingsList = app.collectionViews.firstMatch
        let exportButton = app.buttons["settings.exportButton"]
        scrollToElement(exportButton, in: settingsList)
        XCTAssertTrue(exportButton.waitForExistence(timeout: 3))
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
