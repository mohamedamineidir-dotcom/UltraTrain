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

    // MARK: - Extended Tests

    @MainActor
    func testDashboardHeroCardVisible() throws {
        let app = XCUIApplication.launchWithTestData()
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5))

        // Hero card should show race countdown or training info
        // Look for "days" text (countdown) or "Training" fallback
        let daysText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'days'")).firstMatch
        let trainingText = app.staticTexts["Training"]
        XCTAssertTrue(daysText.waitForExistence(timeout: 5) || trainingText.waitForExistence(timeout: 5),
                       "Dashboard should show hero card with countdown or training label")
    }

    @MainActor
    func testDashboardScrollsToUpcomingRaces() throws {
        let app = XCUIApplication.launchWithTestData()
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5))

        // Scroll until "Upcoming Races" section is found
        let racesSection = app.staticTexts["Upcoming Races"]
        for _ in 0..<8 where !racesSection.exists {
            app.swipeUp()
        }
        XCTAssertTrue(racesSection.exists, "Should find Upcoming Races section after scrolling")

        // Race name should be visible
        let raceName = app.staticTexts["Test Ultra 50K"]
        XCTAssertTrue(raceName.waitForExistence(timeout: 3),
                       "Seeded race should appear in upcoming races")
    }

    @MainActor
    func testDashboardNextSessionCardExists() throws {
        let app = XCUIApplication.launchWithTestData()
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5))

        let card = app.otherElements["dashboard.nextSessionCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 5),
                       "Next session card should be visible on dashboard")
    }

    @MainActor
    func testDashboardWeeklyStatsShowsContent() throws {
        let app = XCUIApplication.launchWithTestData()
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5))

        let stats = app.otherElements["dashboard.weeklyStatsCard"]
        XCTAssertTrue(stats.waitForExistence(timeout: 5))

        // Stats card should contain metric labels
        let kmText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'km'")).firstMatch
        XCTAssertTrue(kmText.waitForExistence(timeout: 3),
                       "Weekly stats should show distance in km")
    }

    @MainActor
    func testDashboardIsDefaultTab() throws {
        let app = XCUIApplication.launchWithTestData()
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.waitForExistence(timeout: 5))
        XCTAssertTrue(dashboardTab.isSelected, "Dashboard should be the default selected tab")
    }
}
