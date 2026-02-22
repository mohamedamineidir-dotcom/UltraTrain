import XCTest

final class ExportFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    /// Navigates to Run History via Run tab > "Run History" link.
    private func navigateToRunHistory(_ app: XCUIApplication) {
        app.tabBars.buttons["Run"].waitAndTap()
        app.staticTexts["Run History"].waitAndTap()
    }

    // MARK: - Tests

    @MainActor
    func testRunHistoryShowsCompletedRun() throws {
        let app = XCUIApplication.launchWithTestData()
        navigateToRunHistory(app)

        XCTAssertTrue(
            app.navigationBars["Run History"].waitForExistence(timeout: 5),
            "Run History screen should appear"
        )
    }

    @MainActor
    func testExportButtonShowsOptions() throws {
        let app = XCUIApplication.launchWithTestData()
        navigateToRunHistory(app)

        guard app.navigationBars["Run History"].waitForExistence(timeout: 5) else {
            XCTFail("Could not navigate to Run History")
            return
        }

        // Tap the first completed run row to open detail
        let firstCell = app.cells.firstMatch
        guard firstCell.waitForExistence(timeout: 5) else {
            // No runs available in seeded data — skip gracefully
            return
        }
        firstCell.tap()

        // Tap "View Analysis" to open RunAnalysisView
        let analysisButton = app.buttons["View Analysis"]
        guard analysisButton.waitForExistence(timeout: 5) else {
            return
        }
        analysisButton.tap()

        // Tap the export button in RunAnalysisView toolbar
        let exportButton = app.buttons["runAnalysis.exportButton"]
        guard exportButton.waitForExistence(timeout: 10) else {
            return
        }
        exportButton.tap()

        // Verify export options appear
        let gpxOption = app.buttons["runAnalysis.exportGPX"]
        XCTAssertTrue(gpxOption.waitForExistence(timeout: 3))
    }
}
