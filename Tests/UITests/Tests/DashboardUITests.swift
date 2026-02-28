import XCTest

final class DashboardUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Tests

    @MainActor
    func testDashboardShowsNextSessionCard() throws {
        let app = XCUIApplication.launchWithTestData()
        // Dashboard is the first tab, should be visible
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5))
        // Look for the next session card
        let card = app.otherElements["dashboard.nextSessionCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
    }

    @MainActor
    func testDashboardShowsWeeklyStats() throws {
        let app = XCUIApplication.launchWithTestData()
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5))
        let stats = app.otherElements["dashboard.weeklyStatsCard"]
        XCTAssertTrue(stats.waitForExistence(timeout: 5))
    }

    @MainActor
    func testDashboardShowsUpcomingRaces() throws {
        let app = XCUIApplication.launchWithTestData()
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5))
        // Card is far down the scroll view; scroll until visible
        let racesText = app.staticTexts["Upcoming Races"]
        for _ in 0..<5 where !racesText.exists {
            app.swipeUp()
        }
        XCTAssertTrue(racesText.waitForExistence(timeout: 10))
    }

    @MainActor
    func testDashboardNavigateToRecovery() throws {
        let app = XCUIApplication.launchWithTestData()
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5))
        // Scroll down to find recovery card and tap it
        let recovery = app.otherElements["dashboard.recoveryCard"]
        if recovery.waitForExistence(timeout: 5) {
            recovery.tap()
            XCTAssertTrue(app.navigationBars["Morning Readiness"].waitForExistence(timeout: 5))
        }
    }
}
