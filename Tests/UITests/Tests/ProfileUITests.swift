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

    // MARK: - Extended Tests

    @MainActor
    func testProfileShowsAthleteStats() throws {
        let app = XCUIApplication.launchWithTestData()
        app.tabBars.buttons["Profile"].waitAndTap()

        // Look for stat-related labels
        let weight = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'kg'")).firstMatch
        let hr = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'bpm'")).firstMatch
        let experience = app.staticTexts["Intermediate"]

        // At least one stat should be visible
        XCTAssertTrue(
            weight.waitForExistence(timeout: 5) ||
            hr.waitForExistence(timeout: 5) ||
            experience.waitForExistence(timeout: 5),
            "Profile should show athlete statistics"
        )
    }

    @MainActor
    func testProfileShowsRaceName() throws {
        let app = XCUIApplication.launchWithTestData()
        app.tabBars.buttons["Profile"].waitAndTap()

        // Seeded race should appear
        let raceName = app.staticTexts["Test Ultra 50K"]
        // Scroll if needed
        for _ in 0..<3 where !raceName.exists {
            app.swipeUp()
        }
        XCTAssertTrue(raceName.waitForExistence(timeout: 5),
                       "Profile should show the seeded race name")
    }

    @MainActor
    func testProfileSettingsNavigationReturns() throws {
        let app = XCUIApplication.launchWithTestData()
        app.tabBars.buttons["Profile"].waitAndTap()

        let settingsButton = app.buttons["profile.settingsButton"]
        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

            // Navigate back
            app.navigationBars.buttons.firstMatch.tap()
            XCTAssertTrue(app.staticTexts["Test Runner"].waitForExistence(timeout: 5) ||
                          app.staticTexts["Test"].waitForExistence(timeout: 5),
                           "Should return to profile after back navigation")
        }
    }

    @MainActor
    func testProfileGearNavigationReturns() throws {
        let app = XCUIApplication.launchWithTestData()
        app.tabBars.buttons["Profile"].waitAndTap()

        let gearLink = app.buttons["profile.gearLink"]
        if gearLink.waitForExistence(timeout: 5) {
            gearLink.tap()
            XCTAssertTrue(app.navigationBars["Gear"].waitForExistence(timeout: 5))

            // Navigate back
            app.navigationBars.buttons.firstMatch.tap()
            XCTAssertTrue(app.staticTexts["Test Runner"].waitForExistence(timeout: 5) ||
                          app.staticTexts["Test"].waitForExistence(timeout: 5),
                           "Should return to profile after back navigation")
        }
    }

    @MainActor
    func testProfileShowsEditButton() throws {
        let app = XCUIApplication.launchWithTestData()
        app.tabBars.buttons["Profile"].waitAndTap()

        // Wait for profile to load
        XCTAssertTrue(app.staticTexts["Test Runner"].waitForExistence(timeout: 5) ||
                      app.staticTexts["Test"].waitForExistence(timeout: 5))

        // Edit button should be in the toolbar
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3),
                       "Edit button should appear in profile toolbar")
    }
}
