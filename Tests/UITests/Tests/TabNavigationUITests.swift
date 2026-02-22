import XCTest

final class TabNavigationUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Tests

    @MainActor
    func testSwitchBetweenAllTabs() throws {
        let app = XCUIApplication.launchWithTestData()

        // Start on Dashboard
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5))

        // Switch to Plan
        app.tabBars.buttons["Plan"].tap()
        XCTAssertTrue(app.tabBars.buttons["Plan"].isSelected)

        // Switch to Run
        app.tabBars.buttons["Run"].tap()
        XCTAssertTrue(app.tabBars.buttons["Run"].isSelected)

        // Switch to Nutrition
        app.tabBars.buttons["Nutrition"].tap()
        XCTAssertTrue(app.tabBars.buttons["Nutrition"].isSelected)

        // Switch to Profile
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.tabBars.buttons["Profile"].isSelected)
    }

    @MainActor
    func testDashboardIsDefaultTab() throws {
        let app = XCUIApplication.launchWithTestData()
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].isSelected)
    }
}
