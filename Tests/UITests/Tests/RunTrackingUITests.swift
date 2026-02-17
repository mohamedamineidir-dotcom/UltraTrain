import XCTest

final class RunTrackingUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    private func navigateToRunTab(_ app: XCUIApplication) {
        let runTab = app.tabBars.buttons["Run"]
        XCTAssertTrue(runTab.waitForExistence(timeout: 5), "Run tab should exist")
        runTab.tap()
    }

    private func startRun(_ app: XCUIApplication) {
        let startButton = app.buttons["runTracking.startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5), "Start button should exist")
        XCTAssertTrue(startButton.waitUntilEnabled(timeout: 10), "Start button should become enabled")
        startButton.tap()
    }

    // MARK: - Tests

    @MainActor
    func testRunTrackingLaunchScreenAppears() throws {
        let app = XCUIApplication.launchWithTestData()

        navigateToRunTab(app)

        // Verify hero section
        XCTAssertTrue(app.staticTexts["Ready to Run?"].waitForExistence(timeout: 5), "Hero text should appear")

        // Verify start button exists and becomes enabled after data loads
        let startButton = app.buttons["runTracking.startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5), "Start button should exist")
        XCTAssertTrue(startButton.waitUntilEnabled(timeout: 10), "Start button should be enabled after loading")
    }

    @MainActor
    func testStartPauseStopFlow() throws {
        let app = XCUIApplication.launchWithTestData()

        navigateToRunTab(app)
        startRun(app)

        // Timer should appear
        let timer = app.staticTexts["runTracking.timerDisplay"]
        XCTAssertTrue(timer.waitForExistence(timeout: 10), "Timer display should appear")

        // Pause
        let pauseButton = app.buttons["runTracking.pauseButton"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 5), "Pause button should appear")
        pauseButton.tap()

        // Resume and stop buttons should appear
        let resumeButton = app.buttons["runTracking.resumeButton"]
        let stopButton = app.buttons["runTracking.stopButton"]
        XCTAssertTrue(resumeButton.waitForExistence(timeout: 5), "Resume button should appear")
        XCTAssertTrue(stopButton.exists, "Stop button should appear")

        // Stop
        stopButton.tap()

        // Summary sheet should appear
        XCTAssertTrue(app.staticTexts["Great Run!"].waitForExistence(timeout: 5), "Summary should appear")
        XCTAssertTrue(app.buttons["runTracking.saveButton"].exists)
        XCTAssertTrue(app.buttons["runTracking.discardButton"].exists)
    }

    @MainActor
    func testDiscardRunReturnsToLaunch() throws {
        let app = XCUIApplication.launchWithTestData()

        navigateToRunTab(app)
        startRun(app)

        // Wait for active run, then pause + stop
        XCTAssertTrue(app.staticTexts["runTracking.timerDisplay"].waitForExistence(timeout: 10))
        app.buttons["runTracking.pauseButton"].waitAndTap()
        app.buttons["runTracking.stopButton"].waitAndTap()

        // Summary sheet — tap Discard
        XCTAssertTrue(app.staticTexts["Great Run!"].waitForExistence(timeout: 5))
        app.buttons["runTracking.discardButton"].waitAndTap()

        // Should return to launch screen
        XCTAssertTrue(app.staticTexts["Ready to Run?"].waitForExistence(timeout: 5))
    }
}
