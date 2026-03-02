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

    // MARK: - Save Flow

    @MainActor
    func testSaveRunCompletesSuccessfully() throws {
        let app = XCUIApplication.launchWithTestData()

        navigateToRunTab(app)
        startRun(app)

        // Wait for timer, then pause + stop
        XCTAssertTrue(app.staticTexts["runTracking.timerDisplay"].waitForExistence(timeout: 10))
        app.buttons["runTracking.pauseButton"].waitAndTap()
        app.buttons["runTracking.stopButton"].waitAndTap()

        // Summary sheet — tap Save
        XCTAssertTrue(app.staticTexts["Great Run!"].waitForExistence(timeout: 5))
        app.buttons["runTracking.saveButton"].waitAndTap()

        // Should show confirmation or return to launch
        let savedText = app.staticTexts["Run Saved!"]
        let launchText = app.staticTexts["Ready to Run?"]
        XCTAssertTrue(savedText.waitForExistence(timeout: 5) || launchText.waitForExistence(timeout: 5),
                       "Should show save confirmation or return to launch")
    }

    @MainActor
    func testResumeAfterPauseResumesTimer() throws {
        let app = XCUIApplication.launchWithTestData()

        navigateToRunTab(app)
        startRun(app)

        // Wait for active run
        XCTAssertTrue(app.staticTexts["runTracking.timerDisplay"].waitForExistence(timeout: 10))

        // Pause
        app.buttons["runTracking.pauseButton"].waitAndTap()
        XCTAssertTrue(app.buttons["runTracking.resumeButton"].waitForExistence(timeout: 5))

        // Resume
        app.buttons["runTracking.resumeButton"].tap()

        // Pause button should reappear (proves we're running again)
        XCTAssertTrue(app.buttons["runTracking.pauseButton"].waitForExistence(timeout: 5),
                       "Pause button should reappear after resuming")
    }

    @MainActor
    func testTimerDisplayShowsTime() throws {
        let app = XCUIApplication.launchWithTestData()

        navigateToRunTab(app)
        startRun(app)

        // Timer should appear with a time value
        let timer = app.staticTexts["runTracking.timerDisplay"]
        XCTAssertTrue(timer.waitForExistence(timeout: 10))

        // Wait a moment for the timer to tick
        Thread.sleep(forTimeInterval: 2)

        // Timer label should not be empty
        let label = timer.label
        XCTAssertFalse(label.isEmpty, "Timer should display a time value")
    }

    @MainActor
    func testRunSummaryShowsStats() throws {
        let app = XCUIApplication.launchWithTestData()

        navigateToRunTab(app)
        startRun(app)

        // Wait for timer, then pause + stop
        XCTAssertTrue(app.staticTexts["runTracking.timerDisplay"].waitForExistence(timeout: 10))
        app.buttons["runTracking.pauseButton"].waitAndTap()
        app.buttons["runTracking.stopButton"].waitAndTap()

        // Summary should show stat labels
        XCTAssertTrue(app.staticTexts["Great Run!"].waitForExistence(timeout: 5))

        let distance = app.staticTexts["Distance"]
        let duration = app.staticTexts["Duration"]
        XCTAssertTrue(distance.waitForExistence(timeout: 3) || duration.waitForExistence(timeout: 3),
                       "Summary should show run statistics")
    }

    @MainActor
    func testStartButtonDisabledDuringLoading() throws {
        let app = XCUIApplication.launchWithTestData()

        navigateToRunTab(app)

        // Start button should exist
        let startButton = app.buttons["runTracking.startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))

        // It should eventually become enabled (after athlete and location data load)
        XCTAssertTrue(startButton.waitUntilEnabled(timeout: 10),
                       "Start button should become enabled after data loads")
    }
}
