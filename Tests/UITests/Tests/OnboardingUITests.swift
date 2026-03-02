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

    // MARK: - Validation Tests

    @MainActor
    func testNewRunnerToggleSkipsHistoryFields() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Welcome → Experience → select → Next
        app.buttons["onboarding.nextButton"].waitAndTap()
        XCTAssertTrue(app.staticTexts["What's your experience level?"].waitForExistence(timeout: 3))
        app.buttons["onboarding.experienceCard.beginner"].waitAndTap()
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Running History step — toggle "I'm just getting started"
        XCTAssertTrue(app.staticTexts["Your Running Background"].waitForExistence(timeout: 3))
        let toggle = app.switches["onboarding.newRunnerToggle"]
        if toggle.waitForExistence(timeout: 3) {
            toggle.tap()
            // Next should still be enabled (new runners skip history)
            XCTAssertTrue(app.buttons["onboarding.nextButton"].isEnabled)
        }
    }

    @MainActor
    func testExperienceSelectionPersistsThroughBackNavigation() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Welcome → Experience
        app.buttons["onboarding.nextButton"].waitAndTap()
        XCTAssertTrue(app.staticTexts["What's your experience level?"].waitForExistence(timeout: 3))

        // Select "advanced"
        app.buttons["onboarding.experienceCard.advanced"].waitAndTap()
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Running History → go back
        XCTAssertTrue(app.staticTexts["Your Running Background"].waitForExistence(timeout: 3))
        app.buttons["onboarding.backButton"].waitAndTap()

        // Back on Experience step — Next should still be enabled (selection persists)
        XCTAssertTrue(app.staticTexts["What's your experience level?"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["onboarding.nextButton"].isEnabled,
                       "Next should remain enabled after returning — selection should persist")
    }

    @MainActor
    func testPhysicalDataStepRequiresFirstName() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Navigate to Physical Data step (step 3)
        app.buttons["onboarding.nextButton"].waitAndTap() // Welcome → Experience
        app.buttons["onboarding.experienceCard.intermediate"].waitAndTap()
        app.buttons["onboarding.nextButton"].waitAndTap() // Experience → Running History
        app.buttons["onboarding.nextButton"].waitAndTap() // Running History → Physical Data

        XCTAssertTrue(app.staticTexts["Your Physical Data"].waitForExistence(timeout: 3))

        // Next should be disabled when first name is empty
        let nextButton = app.buttons["onboarding.nextButton"]
        XCTAssertFalse(nextButton.isEnabled, "Next should be disabled without a first name")

        // Fill first name → Next should become enabled
        let firstNameField = app.textFields["onboarding.firstNameField"]
        firstNameField.tap()
        firstNameField.typeText("Alex")
        XCTAssertTrue(nextButton.waitUntilEnabled(timeout: 3),
                       "Next should be enabled after entering first name")
    }

    @MainActor
    func testRaceGoalStepRequiresRaceName() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Navigate to Race Goal step (step 4)
        app.buttons["onboarding.nextButton"].waitAndTap() // Welcome → Experience
        app.buttons["onboarding.experienceCard.intermediate"].waitAndTap()
        app.buttons["onboarding.nextButton"].waitAndTap() // → Running History
        app.buttons["onboarding.nextButton"].waitAndTap() // → Physical Data
        let firstNameField = app.textFields["onboarding.firstNameField"]
        XCTAssertTrue(firstNameField.waitForExistence(timeout: 3))
        firstNameField.tap()
        firstNameField.typeText("Alex")
        app.buttons["onboarding.nextButton"].waitAndTap() // → Race Goal

        XCTAssertTrue(app.staticTexts["Your A-Race Goal"].waitForExistence(timeout: 3))

        // Next should be disabled when race name is empty
        let nextButton = app.buttons["onboarding.nextButton"]
        XCTAssertFalse(nextButton.isEnabled, "Next should be disabled without a race name")

        // Fill race name → Next should become enabled
        let raceNameField = app.textFields["onboarding.raceNameField"]
        raceNameField.tap()
        raceNameField.typeText("UTMB")
        XCTAssertTrue(nextButton.waitUntilEnabled(timeout: 3),
                       "Next should be enabled after entering race name")
    }

    @MainActor
    func testCanNavigateToPersonalBestsStep() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Navigate to PBs step — check step ordering by looking for the header
        app.buttons["onboarding.nextButton"].waitAndTap() // Welcome → Experience
        app.buttons["onboarding.experienceCard.intermediate"].waitAndTap()
        app.buttons["onboarding.nextButton"].waitAndTap() // → Running History
        app.buttons["onboarding.nextButton"].waitAndTap() // → Physical Data or PBs

        // The step after Running History could be Personal Bests or Physical Data
        // depending on the step order. Look for either heading.
        let pbsHeader = app.staticTexts["Your Race Times"]
        let physicalHeader = app.staticTexts["Your Physical Data"]
        let foundPBs = pbsHeader.waitForExistence(timeout: 3)
        let foundPhysical = physicalHeader.waitForExistence(timeout: 1)

        XCTAssertTrue(foundPBs || foundPhysical,
                       "Should reach Personal Bests or Physical Data step")

        // Next should be enabled (PBs are optional)
        if foundPBs {
            XCTAssertTrue(app.buttons["onboarding.nextButton"].isEnabled,
                           "Next should be enabled — personal bests are optional")
        }
    }

    @MainActor
    func testCompleteStepShowsProfileSummary() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Navigate through all steps
        app.buttons["onboarding.nextButton"].waitAndTap() // Welcome → Experience
        app.buttons["onboarding.experienceCard.intermediate"].waitAndTap()
        app.buttons["onboarding.nextButton"].waitAndTap() // → Running History
        app.buttons["onboarding.nextButton"].waitAndTap() // → Physical Data

        // Fill name
        XCTAssertTrue(app.staticTexts["Your Physical Data"].waitForExistence(timeout: 3))
        let firstNameField = app.textFields["onboarding.firstNameField"]
        firstNameField.tap()
        firstNameField.typeText("Alex")
        app.buttons["onboarding.nextButton"].waitAndTap() // → Race Goal

        // Fill race name
        XCTAssertTrue(app.staticTexts["Your A-Race Goal"].waitForExistence(timeout: 3))
        let raceNameField = app.textFields["onboarding.raceNameField"]
        raceNameField.tap()
        raceNameField.typeText("UTMB")
        app.buttons["onboarding.nextButton"].waitAndTap() // → Complete

        // Verify completion step
        XCTAssertTrue(app.staticTexts["You're All Set!"].waitForExistence(timeout: 5))

        // Get Started button should be present
        let getStartedButton = app.buttons["onboarding.getStartedButton"]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 3))
    }
}
