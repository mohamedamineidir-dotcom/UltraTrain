import XCTest

final class GearUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    private func navigateToGear(_ app: XCUIApplication) {
        app.tabBars.buttons["Profile"].waitAndTap()
        app.buttons["profile.gearLink"].waitAndTap()
    }

    // MARK: - Tests

    @MainActor
    func testGearListShowsSeededItems() throws {
        let app = XCUIApplication.launchWithTestData()
        navigateToGear(app)
        XCTAssertTrue(app.navigationBars["Gear"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Speedgoat 5"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Trail Running Poles"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAddGearFlow() throws {
        let app = XCUIApplication.launchWithTestData()
        navigateToGear(app)
        XCTAssertTrue(app.navigationBars["Gear"].waitForExistence(timeout: 5))

        app.buttons["gear.addButton"].waitAndTap()

        let nameField = app.textFields["gear.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Salomon S/Lab")

        let brandField = app.textFields["gear.brandField"]
        brandField.tap()
        brandField.typeText("Salomon")

        app.buttons["gear.saveButton"].waitAndTap()

        // Verify new item appears in the list
        XCTAssertTrue(app.staticTexts["Salomon S/Lab"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testGearCancelDoesNotSave() throws {
        let app = XCUIApplication.launchWithTestData()
        navigateToGear(app)
        XCTAssertTrue(app.navigationBars["Gear"].waitForExistence(timeout: 5))

        app.buttons["gear.addButton"].waitAndTap()

        let nameField = app.textFields["gear.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Should Not Appear")

        app.buttons["gear.cancelButton"].waitAndTap()

        // Verify the item was NOT added
        XCTAssertFalse(app.staticTexts["Should Not Appear"].exists)
    }
}
