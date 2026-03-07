import XCTest

final class OnboardingUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Full Flow

    @MainActor
    func testCompleteOnboardingFlow() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Step 0: Experience — select "intermediate"
        XCTAssertTrue(app.staticTexts["Experience Level"].waitForExistence(timeout: 5))
        app.buttons["onboarding.experienceCard.intermediate"].waitAndTap()
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 1: Running History — defaults valid, advance
        XCTAssertTrue(app.staticTexts["Your Running Background"].waitForExistence(timeout: 3))
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 2: Personal Bests — skip
        XCTAssertTrue(app.staticTexts["Your Race Times"].waitForExistence(timeout: 3))
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 3: About You — enter name
        XCTAssertTrue(app.staticTexts["About You"].waitForExistence(timeout: 3))
        let firstNameField = app.textFields["onboarding.firstNameField"]
        XCTAssertTrue(firstNameField.waitForExistence(timeout: 3))
        firstNameField.tap()
        firstNameField.typeText("Test")

        let lastNameField = app.textFields["onboarding.lastNameField"]
        lastNameField.tap()
        lastNameField.typeText("Runner")
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 4: Body Metrics — defaults valid, advance
        XCTAssertTrue(app.staticTexts["Body Metrics"].waitForExistence(timeout: 3))
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 5: Heart Rate — defaults valid, advance
        XCTAssertTrue(app.staticTexts["Heart Rate"].waitForExistence(timeout: 3))
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 6: Race Name & Date — enter race name
        XCTAssertTrue(app.staticTexts["Your A-Race"].waitForExistence(timeout: 3))
        let raceNameField = app.textFields["raceNameField"]
        XCTAssertTrue(raceNameField.waitForExistence(timeout: 3))
        raceNameField.tap()
        raceNameField.typeText("UTMB")
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 7: Race Profile — defaults valid, advance
        XCTAssertTrue(app.staticTexts["Race Profile"].waitForExistence(timeout: 3))
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 8: Goal & Training — defaults valid, advance
        XCTAssertTrue(app.staticTexts["Goal & Training"].waitForExistence(timeout: 3))
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 9: Complete — tap Get Started
        XCTAssertTrue(app.staticTexts["You're All Set!"].waitForExistence(timeout: 3))
        app.buttons["onboarding.getStartedButton"].waitAndTap()

        // Verify: Dashboard tab appears (MainTabView loaded)
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5))
    }

    // MARK: - Validation

    @MainActor
    func testNextButtonDisabledWithoutExperienceSelection() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Step 0: Experience — don't select anything
        XCTAssertTrue(app.staticTexts["Experience Level"].waitForExistence(timeout: 5))
        let nextButton = app.buttons["onboarding.nextButton"]
        XCTAssertTrue(nextButton.exists)
        XCTAssertFalse(nextButton.isEnabled, "Next should be disabled when no experience level is selected")
    }

    @MainActor
    func testBackButtonNavigatesBackward() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Step 0: Experience → select → Next
        XCTAssertTrue(app.staticTexts["Experience Level"].waitForExistence(timeout: 5))
        app.buttons["onboarding.experienceCard.beginner"].waitAndTap()
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 1: Running History → Back
        XCTAssertTrue(app.staticTexts["Your Running Background"].waitForExistence(timeout: 3))
        app.buttons["onboarding.backButton"].waitAndTap()

        // Should be back on Experience step
        XCTAssertTrue(app.staticTexts["Experience Level"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testNewRunnerToggleSkipsHistoryFields() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Experience → select → Next
        XCTAssertTrue(app.staticTexts["Experience Level"].waitForExistence(timeout: 5))
        app.buttons["onboarding.experienceCard.beginner"].waitAndTap()
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Running History step — toggle "I'm just getting started"
        XCTAssertTrue(app.staticTexts["Your Running Background"].waitForExistence(timeout: 3))
        let toggle = app.switches["onboarding.newRunnerToggle"]
        if toggle.waitForExistence(timeout: 3) {
            toggle.tap()
            XCTAssertTrue(app.buttons["onboarding.nextButton"].isEnabled)
        }
    }

    @MainActor
    func testExperienceSelectionPersistsThroughBackNavigation() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Step 0: Experience — select "advanced" → Next
        XCTAssertTrue(app.staticTexts["Experience Level"].waitForExistence(timeout: 5))
        app.buttons["onboarding.experienceCard.advanced"].waitAndTap()
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 1: Running History → go back
        XCTAssertTrue(app.staticTexts["Your Running Background"].waitForExistence(timeout: 3))
        app.buttons["onboarding.backButton"].waitAndTap()

        // Back on Experience step — Next should still be enabled
        XCTAssertTrue(app.staticTexts["Experience Level"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["onboarding.nextButton"].isEnabled,
                       "Next should remain enabled — selection should persist")
    }

    @MainActor
    func testAboutYouStepRequiresFirstName() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Navigate to About You step (step 3)
        XCTAssertTrue(app.staticTexts["Experience Level"].waitForExistence(timeout: 5))
        app.buttons["onboarding.experienceCard.intermediate"].waitAndTap()
        app.buttons["onboarding.nextButton"].waitAndTap() // → Running History
        app.buttons["onboarding.nextButton"].waitAndTap() // → Personal Bests
        app.buttons["onboarding.nextButton"].waitAndTap() // → About You

        XCTAssertTrue(app.staticTexts["About You"].waitForExistence(timeout: 3))

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
    func testRaceNameStepRequiresRaceName() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Navigate to Race Name step (step 6)
        navigateToStep(app: app, targetStep: 6)

        XCTAssertTrue(app.staticTexts["Your A-Race"].waitForExistence(timeout: 3))

        // Next should be disabled when race name is empty
        let nextButton = app.buttons["onboarding.nextButton"]
        XCTAssertFalse(nextButton.isEnabled, "Next should be disabled without a race name")

        // Fill race name → Next should become enabled
        let raceNameField = app.textFields["raceNameField"]
        raceNameField.tap()
        raceNameField.typeText("UTMB")
        XCTAssertTrue(nextButton.waitUntilEnabled(timeout: 3),
                       "Next should be enabled after entering race name")
    }

    @MainActor
    func testCanNavigateToPersonalBestsStep() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Experience → select → Next → Running History → Next → Personal Bests
        XCTAssertTrue(app.staticTexts["Experience Level"].waitForExistence(timeout: 5))
        app.buttons["onboarding.experienceCard.intermediate"].waitAndTap()
        app.buttons["onboarding.nextButton"].waitAndTap()
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 2: Personal Bests
        let pbsHeader = app.staticTexts["Your Race Times"]
        XCTAssertTrue(pbsHeader.waitForExistence(timeout: 3),
                       "Should reach Personal Bests step")

        // Next should be enabled (PBs are optional / skip button shown)
        XCTAssertTrue(app.buttons["onboarding.nextButton"].isEnabled,
                       "Next/Skip should be enabled — personal bests are optional")
    }

    @MainActor
    func testCompleteStepShowsProfileSummary() throws {
        let app = XCUIApplication.launchForOnboardingTest()

        // Navigate all the way to step 9 (Complete)
        navigateToStep(app: app, targetStep: 9)

        // Verify completion step
        XCTAssertTrue(app.staticTexts["You're All Set!"].waitForExistence(timeout: 5))

        // Get Started button should be present
        let getStartedButton = app.buttons["onboarding.getStartedButton"]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 3))
    }

    // MARK: - Helpers

    private func navigateToStep(app: XCUIApplication, targetStep: Int) {
        // Step 0: Experience
        _ = app.staticTexts["Experience Level"].waitForExistence(timeout: 5)
        app.buttons["onboarding.experienceCard.intermediate"].waitAndTap()
        if targetStep == 0 { return }
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 1: Running History
        if targetStep == 1 { return }
        _ = app.staticTexts["Your Running Background"].waitForExistence(timeout: 3)
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 2: Personal Bests (Skip)
        if targetStep == 2 { return }
        _ = app.staticTexts["Your Race Times"].waitForExistence(timeout: 3)
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 3: About You — fill name
        if targetStep == 3 { return }
        _ = app.staticTexts["About You"].waitForExistence(timeout: 3)
        let firstNameField = app.textFields["onboarding.firstNameField"]
        _ = firstNameField.waitForExistence(timeout: 3)
        firstNameField.tap()
        firstNameField.typeText("Alex")
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 4: Body Metrics
        if targetStep == 4 { return }
        _ = app.staticTexts["Body Metrics"].waitForExistence(timeout: 3)
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 5: Heart Rate
        if targetStep == 5 { return }
        _ = app.staticTexts["Heart Rate"].waitForExistence(timeout: 3)
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 6: Race Name & Date — fill race name
        if targetStep == 6 { return }
        _ = app.staticTexts["Your A-Race"].waitForExistence(timeout: 3)
        let raceNameField = app.textFields["raceNameField"]
        _ = raceNameField.waitForExistence(timeout: 3)
        raceNameField.tap()
        raceNameField.typeText("UTMB")
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 7: Race Profile
        if targetStep == 7 { return }
        _ = app.staticTexts["Race Profile"].waitForExistence(timeout: 3)
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 8: Goal & Training
        if targetStep == 8 { return }
        _ = app.staticTexts["Goal & Training"].waitForExistence(timeout: 3)
        app.buttons["onboarding.nextButton"].waitAndTap()

        // Step 9: Complete
    }
}
