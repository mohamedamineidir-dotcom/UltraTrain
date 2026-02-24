import XCTest

final class NutritionUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Tests

    @MainActor
    func testNutritionTabLoads() throws {
        let app = XCUIApplication.launchWithTestData()
        app.tabBars.buttons["Nutrition"].waitAndTap()
        // The default tab is "Training" — verify training content or the tab picker loads
        let trainingView = app.otherElements["nutrition.trainingView"]
        let tabPicker = app.segmentedControls["nutrition.tabPicker"]
        XCTAssertTrue(trainingView.waitForExistence(timeout: 5) || tabPicker.waitForExistence(timeout: 5))
    }

    @MainActor
    func testNutritionShowsGenerateButton() throws {
        let app = XCUIApplication.launchWithTestData()
        app.tabBars.buttons["Nutrition"].waitAndTap()
        // If no plan exists, generate button should appear
        let emptyState = app.otherElements["nutrition.emptyState"]
        if emptyState.waitForExistence(timeout: 5) {
            let generateButton = app.buttons["nutrition.generateButton"]
            XCTAssertTrue(generateButton.exists)
        }
    }

    @MainActor
    func testProductLibraryOpens() throws {
        let app = XCUIApplication.launchWithTestData()
        app.tabBars.buttons["Nutrition"].waitAndTap()
        let libraryButton = app.buttons["nutrition.productLibraryButton"]
        if libraryButton.waitForExistence(timeout: 5) {
            libraryButton.tap()
            // Verify a sheet or navigation appeared
            XCTAssertTrue(app.staticTexts["Product Library"].waitForExistence(timeout: 3) ||
                          app.navigationBars["Product Library"].waitForExistence(timeout: 3))
        }
    }
}
