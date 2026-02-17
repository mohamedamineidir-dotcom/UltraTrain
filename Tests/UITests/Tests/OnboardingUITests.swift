import XCTest

final class OnboardingUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Tests

    @MainActor
    func testCompleteOnboardingFlow() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Step 0: Welcome
        XCTAssertTrue(app.staticTexts["Welcome to UltraTrain"].waitForExistence(timeout: 5))
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 1: Experience — select "intermediate"
        XCTAssertTrue(app.staticTexts["What's your experience level?"].waitForExistence(timeout: 3))
        app.buttons["onboarding.experienceCard.intermediate"].waitAndTap()
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 2: Running History — defaults are valid, just advance
        XCTAssertTrue(app.staticTexts["Your Running Background"].waitForExistence(timeout: 3))
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 3: Physical Data — enter name
        XCTAssertTrue(app.staticTexts["Your Physical Data"].waitForExistence(timeout: 3))
        let firstNameField = app.textFields["onboarding.firstNameField"]
        XCTAssertTrue(firstNameField.waitForExistence(timeout: 3))
        firstNameField.tap()
        firstNameField.typeText("Test")

        let lastNameField = app.textFields["onboarding.lastNameField"]
        lastNameField.tap()
        lastNameField.typeText("Runner")
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 4: Race Goal — enter race name
        XCTAssertTrue(app.staticTexts["Your A-Race Goal"].waitForExistence(timeout: 3))
        let raceNameField = app.textFields["onboarding.raceNameField"]
        XCTAssertTrue(raceNameField.waitForExistence(timeout: 3))
        raceNameField.tap()
        raceNameField.typeText("UTMB")
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 5: Complete — tap Get Started
        XCTAssertTrue(app.staticTexts["You're All Set!"].waitForExistence(timeout: 3))
        app.buttons["onboarding.getStartedButton"].waitAndTap()

        // Verify: Dashboard tab appears (MainTabView loaded)
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testNextButtonDisabledWithoutExperienceSelection() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Welcome → Next
        XCTAssertTrue(app.staticTexts["Welcome to UltraTrain"].waitForExistence(timeout: 5))
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Experience step — don't select anything
        XCTAssertTrue(app.staticTexts["What's your experience level?"].waitForExistence(timeout: 3))
        let nextButton = app.buttons["onboarding.nextButton"]
        XCTAssertTrue(nextButton.exists)
        XCTAssertFalse(nextButton.isEnabled, "Next should be disabled when no experience level is selected")
    }

    @MainActor
    func testBackButtonNavigatesBackward() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Welcome → Next
        XCTAssertTrue(app.staticTexts["Welcome to UltraTrain"].waitForExistence(timeout: 5))
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Experience step → select → Next
        XCTAssertTrue(app.staticTexts["What's your experience level?"].waitForExistence(timeout: 3))
        app.buttons["onboarding.experienceCard.beginner"].waitAndTap()
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Running History step → Back
        XCTAssertTrue(app.staticTexts["Your Running Background"].waitForExistence(timeout: 3))
        app.buttons["onboarding.backButton"].waitAndTap()

        // Should be back on Experience step
        XCTAssertTrue(app.staticTexts["What's your experience level?"].waitForExistence(timeout: 3))
    }
}
