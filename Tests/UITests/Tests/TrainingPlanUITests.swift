import XCTest

final class TrainingPlanUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    private func navigateToPlanTab(_ app: XCUIApplication) {
        let planTab = app.tabBars.buttons["Plan"]
        XCTAssertTrue(planTab.waitForExistence(timeout: 5), "Plan tab should exist")
        planTab.tap()
    }

    // MARK: - Tests

    @MainActor
    func testTrainingPlanShowsWeekCards() throws {
        let app = XCUIApplication.launchWithTestData()
        navigateToPlanTab(app)

        // Verify week cards load (seeded plan has 3 weeks)
        XCTAssertTrue(app.staticTexts["Week 1"].waitForExistence(timeout: 10), "Week 1 should appear")
        XCTAssertTrue(app.staticTexts["Week 2"].exists, "Week 2 should appear")
        XCTAssertTrue(app.staticTexts["Week 3"].exists, "Week 3 should appear")
    }

    @MainActor
    func testCurrentWeekAutoExpandsWithSessions() throws {
        let app = XCUIApplication.launchWithTestData()
        navigateToPlanTab(app)

        // Week 1 is the current week, so it should be auto-expanded.
        // Look for session type text that appears in session rows.
        XCTAssertTrue(app.staticTexts["Week 1"].waitForExistence(timeout: 10), "Week 1 should appear")

        // Seeded sessions include "Recovery" type — check its display name
        XCTAssertTrue(app.staticTexts["Recovery"].waitForExistence(timeout: 5),
                       "Session rows should be visible in auto-expanded current week")
    }

    @MainActor
    func testTapSessionRowOpensDetail() throws {
        let app = XCUIApplication.launchWithTestData()
        navigateToPlanTab(app)

        // Week 1 is auto-expanded — session rows should be visible
        XCTAssertTrue(app.staticTexts["Week 1"].waitForExistence(timeout: 10), "Week 1 should appear")

        // Tap the first "Recovery" session to open its detail
        let recoveryText = app.staticTexts["Recovery"].firstMatch
        XCTAssertTrue(recoveryText.waitForExistence(timeout: 5), "Recovery session should be visible")
        recoveryText.tap()

        // Verify session detail view appears — "Description" section is always present
        XCTAssertTrue(app.staticTexts["Description"].waitForExistence(timeout: 5),
                       "Session detail view should appear")
    }
}
