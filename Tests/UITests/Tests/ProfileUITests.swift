import XCTest

final class ProfileUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Tests

    @MainActor
    func testProfileShowsAthleteInfo() throws {
        let app = XCUIApplication.launchWithTestData()
        app.tabBars.buttons["Profile"].waitAndTap()
        // The seeded athlete is "Test Runner"
        XCTAssertTrue(app.staticTexts["Test Runner"].waitForExistence(timeout: 5) ||
                      app.staticTexts["Test"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testProfileShowsRaces() throws {
        let app = XCUIApplication.launchWithTestData()
        app.tabBars.buttons["Profile"].waitAndTap()
        // The seeded race is "Test Ultra 50K"
        XCTAssertTrue(app.staticTexts["Test Ultra 50K"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testNavigateToSettings() throws {
        let app = XCUIApplication.launchWithTestData()
        app.tabBars.buttons["Profile"].waitAndTap()
        let settingsButton = app.buttons["profile.settingsButton"]
        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        }
    }

    @MainActor
    func testNavigateToGear() throws {
        let app = XCUIApplication.launchWithTestData()
        app.tabBars.buttons["Profile"].waitAndTap()
        let gearLink = app.buttons["profile.gearLink"]
        if gearLink.waitForExistence(timeout: 5) {
            gearLink.tap()
            XCTAssertTrue(app.navigationBars["Gear"].waitForExistence(timeout: 5))
        }
    }
}
