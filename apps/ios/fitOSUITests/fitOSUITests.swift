import XCTest

/// Full end-to-end UI tests for fitOS — every main tab, segment, and key control.
/// Requires a logged-in session on device for most cases (cookie persists).
/// Run: xcodebuild test -scheme fitOS -destination 'id=<device>'
final class fitOSUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITest"]
        app.launch()
        // Wait for bootstrap (hydrate / login)
        _ = app.navigationBars.firstMatch.waitForExistence(timeout: 15)
            || app.staticTexts["fitOS"].waitForExistence(timeout: 15)
    }

    // MARK: - Boot

    func test01_AppLaunches() throws {
        XCTAssertTrue(
            isLoggedIn || isOnLogin,
            "App should show login or main UI"
        )
    }

    // MARK: - Main tabs

    func test02_AllMainTabsReachable() throws {
        try requireLoggedIn()

        assertTab("Today", nav: "Today")
        assertTab("Food", nav: "Food")
        assertTab("Workout", nav: "Workout")
        assertTab("Progress", nav: "Progress")
        assertTab("Profile", nav: "Profile")
        assertTab("Today", nav: "Today")
    }

    // MARK: - Today

    func test03_TodayShowsCaloriesAndMeals() throws {
        try requireLoggedIn()
        tapTab("Today")
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6))
        // Calories eyebrow / macros section
        XCTAssertTrue(
            app.staticTexts["Calories"].waitForExistence(timeout: 4)
                || app.staticTexts["Macros"].exists
                || app.staticTexts["Today's meals"].exists
                || app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "kcal")).count > 0,
            "Today should show calorie / macro / meals content"
        )
    }

    // MARK: - Food

    func test04_FoodLogAndPlanSegments() throws {
        try requireLoggedIn()
        tapTab("Food")
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 6))

        // Segmented control Log / Plan
        let log = app.buttons["Log"]
        let plan = app.buttons["Plan"]
        XCTAssertTrue(log.waitForExistence(timeout: 4) || app.segmentedControls.firstMatch.exists)

        if plan.exists {
            plan.tap()
            // Plan shows weekday strip
            XCTAssertTrue(
                app.buttons["Mon"].waitForExistence(timeout: 4)
                    || app.staticTexts["Planned intake"].waitForExistence(timeout: 4)
                    || app.staticTexts["Breakfast"].waitForExistence(timeout: 4),
                "Meal plan should show weekdays or meal sections"
            )
        }
        if log.exists { log.tap() }
    }

    func test05_FoodSearchAndList() throws {
        try requireLoggedIn()
        tapTab("Food")
        // Inline search field
        let search = app.textFields["Search foods"]
        if search.waitForExistence(timeout: 4) {
            search.tap()
            search.typeText("egg")
            // Should still show list rows (or empty) without crash
            XCTAssertTrue(app.navigationBars["Food"].exists)
            // Clear
            if app.buttons["Clear text"].exists {
                app.buttons["Clear text"].tap()
            } else if app.images["xmark.circle.fill"].exists {
                app.images["xmark.circle.fill"].tap()
            }
        }
    }

    // MARK: - Workout

    func test06_WorkoutAllSegments() throws {
        try requireLoggedIn()
        tapTab("Workout")
        XCTAssertTrue(app.navigationBars["Workout"].waitForExistence(timeout: 6))

        for seg in ["Today", "Plan", "Browse", "Body"] {
            let btn = app.buttons[seg]
            if btn.waitForExistence(timeout: 2) {
                btn.tap()
                // Nav title stays Workout — content should not crash
                XCTAssertTrue(app.navigationBars["Workout"].exists, "Still on Workout after \(seg)")
            }
        }
    }

    func test07_WorkoutTodayRestToggleAndAdd() throws {
        try requireLoggedIn()
        tapTab("Workout")
        let todaySeg = app.buttons["Today"]
        if todaySeg.waitForExistence(timeout: 3) { todaySeg.tap() }

        // Rest day toggle
        let rest = app.switches["Rest day"]
        if rest.waitForExistence(timeout: 3) {
            let before = rest.value as? String
            rest.tap()
            // Toggle back to avoid leaving user on rest day forever
            if rest.exists { rest.tap() }
            XCTAssertNotNil(before)
        }

        let add = app.buttons["Add exercise"]
        if add.waitForExistence(timeout: 3) {
            add.tap()
            XCTAssertTrue(
                app.navigationBars["Add exercise"].waitForExistence(timeout: 4)
                    || app.buttons["Cancel"].waitForExistence(timeout: 4),
                "Exercise picker should open"
            )
            if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
        }
    }

    func test08_WorkoutPlanWeekdays() throws {
        try requireLoggedIn()
        tapTab("Workout")
        let plan = app.buttons["Plan"]
        if plan.waitForExistence(timeout: 3) { plan.tap() }

        for day in ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] {
            let b = app.buttons[day]
            if b.waitForExistence(timeout: 2) {
                b.tap()
            }
        }
        XCTAssertTrue(app.navigationBars["Workout"].exists)
    }

    func test09_WorkoutBrowseAndExerciseDetail() throws {
        try requireLoggedIn()
        tapTab("Workout")
        let browse = app.buttons["Browse"]
        if browse.waitForExistence(timeout: 3) { browse.tap() }

        // Tap first exercise-like cell if any
        let cells = app.buttons.matching(NSPredicate(format: "label.length > 2"))
        if cells.count > 3 {
            // Skip segment buttons; try a later button (grid cards)
            let candidate = cells.element(boundBy: min(5, cells.count - 1))
            if candidate.exists {
                candidate.tap()
                // Detail sheet or nothing
                if app.buttons["Done"].waitForExistence(timeout: 3) {
                    // May see Add to today
                    _ = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Add")).firstMatch.exists
                    app.buttons["Done"].tap()
                }
            }
        }
        XCTAssertTrue(app.navigationBars["Workout"].exists)
    }

    func test10_WorkoutBodyMap() throws {
        try requireLoggedIn()
        tapTab("Workout")
        let body = app.buttons["Body"]
        if body.waitForExistence(timeout: 3) { body.tap() }

        // Front / Back picker or loading
        let front = app.buttons["Front"]
        let back = app.buttons["Back"]
        if front.waitForExistence(timeout: 8) {
            front.tap()
            if back.exists { back.tap() }
            if front.exists { front.tap() }
        } else {
            // Loading anatomy is OK
            XCTAssertTrue(
                app.staticTexts["Loading anatomy…"].exists
                    || app.navigationBars["Workout"].exists
            )
        }
    }

    // MARK: - Progress

    func test11_ProgressStatsAndLogWeight() throws {
        try requireLoggedIn()
        tapTab("Progress")
        XCTAssertTrue(app.navigationBars["Progress"].waitForExistence(timeout: 6))

        XCTAssertTrue(
            app.staticTexts["Current"].waitForExistence(timeout: 4)
                || app.staticTexts["BMI"].waitForExistence(timeout: 2)
                || app.staticTexts["Weight trend"].waitForExistence(timeout: 2),
            "Progress should show weight stats"
        )

        let logBtn = app.buttons["Log"]
        if logBtn.waitForExistence(timeout: 3) {
            logBtn.tap()
            if app.navigationBars["Log weight"].waitForExistence(timeout: 3)
                || app.buttons["Cancel"].waitForExistence(timeout: 3) {
                if app.buttons["Cancel"].exists {
                    app.buttons["Cancel"].tap()
                } else if app.buttons["Save"].exists {
                    // Don't save garbage
                    if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
                }
            }
        }
    }

    // MARK: - Profile

    func test12_ProfileFormVisible() throws {
        try requireLoggedIn()
        tapTab("Profile")
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 6))

        XCTAssertTrue(
            app.staticTexts["You"].waitForExistence(timeout: 3)
                || app.staticTexts["Body"].waitForExistence(timeout: 2)
                || app.buttons["Save profile"].waitForExistence(timeout: 2)
                || app.buttons["Saved ✓"].waitForExistence(timeout: 2)
                || app.buttons["Log out"].waitForExistence(timeout: 2),
            "Profile form sections should be visible"
        )
    }

    func test13_ProfileSaveButtonExists() throws {
        try requireLoggedIn()
        tapTab("Profile")
        let save = app.buttons["Save profile"]
        let saved = app.buttons["Saved ✓"]
        XCTAssertTrue(
            save.waitForExistence(timeout: 4) || saved.waitForExistence(timeout: 2),
            "Save profile control should exist"
        )
        // Do not logout in automated tests
        XCTAssertTrue(app.buttons["Log out"].exists || app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Log out")).count > 0)
    }

    // MARK: - Login (only when logged out)

    func test14_LoginValidationWhenLoggedOut() throws {
        guard isOnLogin else {
            throw XCTSkip("Logged in — skip login validation")
        }
        let user = app.textFields["login.username"]
        let pass = app.secureTextFields["login.password"]
        let submit = app.buttons["login.submit"]
        if user.exists {
            user.tap()
            user.typeText("ab")
        }
        if pass.exists {
            pass.tap()
            pass.typeText("12")
        }
        if submit.exists { submit.tap() }
        XCTAssertTrue(isOnLogin || app.staticTexts["login.error"].exists)
    }

    // MARK: - Stress: rapid tab switching (jump regression)

    func test15_RapidTabSwitchNoCrash() throws {
        try requireLoggedIn()
        for _ in 0..<3 {
            for name in ["Today", "Food", "Workout", "Progress", "Profile"] {
                tapTab(name)
            }
        }
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }

    func test16_RapidWorkoutSegmentSwitchNoCrash() throws {
        try requireLoggedIn()
        tapTab("Workout")
        for _ in 0..<3 {
            for seg in ["Today", "Plan", "Browse", "Body"] {
                let b = app.buttons[seg]
                if b.exists { b.tap() }
            }
        }
        XCTAssertTrue(app.navigationBars["Workout"].exists)
    }

    func test17_RapidFoodSegmentSwitchNoCrash() throws {
        try requireLoggedIn()
        tapTab("Food")
        for _ in 0..<4 {
            if app.buttons["Plan"].exists { app.buttons["Plan"].tap() }
            if app.buttons["Log"].exists { app.buttons["Log"].tap() }
        }
        XCTAssertTrue(app.navigationBars["Food"].exists)
    }

    // MARK: - Helpers

    private var isLoggedIn: Bool {
        app.tabBars.firstMatch.exists
            || app.navigationBars["Today"].exists
            || app.otherElements["main.tabs"].exists
    }

    private var isOnLogin: Bool {
        app.buttons["login.submit"].exists
            || app.otherElements["screen.login"].exists
            || (app.staticTexts["fitOS"].exists && app.secureTextFields.firstMatch.exists)
    }

    private func requireLoggedIn() throws {
        if isOnLogin && !isLoggedIn {
            throw XCTSkip("Not logged in — sign in once on device, then re-run UI tests.")
        }
        // Wait for tabs
        if !app.tabBars.firstMatch.waitForExistence(timeout: 10) {
            throw XCTSkip("Main tabs not visible")
        }
    }

    private func tapTab(_ name: String) {
        let tab = app.tabBars.buttons[name]
        if tab.waitForExistence(timeout: 3) {
            tab.tap()
            return
        }
        let any = app.buttons[name]
        if any.exists { any.tap() }
    }

    private func assertTab(_ name: String, nav: String) {
        tapTab(name)
        XCTAssertTrue(
            app.navigationBars[nav].waitForExistence(timeout: 6)
                || app.otherElements["screen.\(nav.lowercased())"].waitForExistence(timeout: 2),
            "\(name) tab should show \(nav)"
        )
    }
}
