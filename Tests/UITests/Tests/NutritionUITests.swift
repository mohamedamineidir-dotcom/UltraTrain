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

    // MARK: - Extended Tests

    @MainActor
    func testNutritionTabSwitching() throws {
        let app = XCUIApplication.launchWithTestData()
        app.tabBars.buttons["Nutrition"].waitAndTap()

        let tabPicker = app.segmentedControls["nutrition.tabPicker"]
        if tabPicker.waitForExistence(timeout: 5) {
            // Switch to Race Day tab
            let raceDayButton = tabPicker.buttons["Race Day"]
            if raceDayButton.exists {
                raceDayButton.tap()
                // Should show race day content or empty state
                Thread.sleep(forTimeInterval: 1)
            }

            // Switch back to Training
            let trainingButton = tabPicker.buttons["Training"]
            if trainingButton.exists {
                trainingButton.tap()
                Thread.sleep(forTimeInterval: 1)
            }
        }
    }

    @MainActor
    func testNutritionNavigationTitle() throws {
        let app = XCUIApplication.launchWithTestData()
        app.tabBars.buttons["Nutrition"].waitAndTap()

        XCTAssertTrue(app.navigationBars["Nutrition"].waitForExistence(timeout: 5) ||
                      app.staticTexts["Nutrition"].waitForExistence(timeout: 5),
                       "Nutrition navigation title should be visible")
    }

    @MainActor
    func testNutritionContentOrEmptyState() throws {
        let app = XCUIApplication.launchWithTestData()
        app.tabBars.buttons["Nutrition"].waitAndTap()

        // Either content view or empty state should appear
        let trainingView = app.otherElements["nutrition.trainingView"]
        let emptyState = app.otherElements["nutrition.emptyState"]
        let generateButton = app.buttons["nutrition.generateButton"]

        let hasContent = trainingView.waitForExistence(timeout: 5)
        let hasEmpty = emptyState.waitForExistence(timeout: 2)
        let hasGenerate = generateButton.waitForExistence(timeout: 2)

        XCTAssertTrue(hasContent || hasEmpty || hasGenerate,
                       "Nutrition tab should show training content, empty state, or generate button")
    }

    @MainActor
    func testNutritionRaceDayContent() throws {
        let app = XCUIApplication.launchWithTestData()
        app.tabBars.buttons["Nutrition"].waitAndTap()

        let tabPicker = app.segmentedControls["nutrition.tabPicker"]
        if tabPicker.waitForExistence(timeout: 5) {
            // Switch to Race Day
            let raceDayButton = tabPicker.buttons["Race Day"]
            if raceDayButton.exists {
                raceDayButton.tap()

                // Product library button should appear on Race Day tab
                let libraryButton = app.buttons["nutrition.productLibraryButton"]
                XCTAssertTrue(libraryButton.waitForExistence(timeout: 5),
                               "Product Library button should appear on Race Day tab")
            }
        }
    }
}
