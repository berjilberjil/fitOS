import XCTest

/// One-shot tour: login → Progress → Profile (theme) with screenshots under /tmp.
final class DemoTourUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITesting"]
        app.launch()
    }

    func testDemoTour_loginProfileProgress() throws {
        let user = "ios_demo_1784281787"
        let pass = "demo12345"

        // Prefer identifiers; fall back to visible labels (parent AX can swallow ids).
        let loginById = app.buttons["login.submit"]
        let loginByLabel = app.buttons["Log in"]
        let onLogin = loginById.waitForExistence(timeout: 8) || loginByLabel.waitForExistence(timeout: 4)

        if onLogin {
            let u = app.textFields["login.username"].exists
                ? app.textFields["login.username"]
                : app.textFields.firstMatch
            let p = app.secureTextFields["login.password"].exists
                ? app.secureTextFields["login.password"]
                : app.secureTextFields.firstMatch
            XCTAssertTrue(u.waitForExistence(timeout: 4), "username field")
            u.tap()
            if let v = u.value as? String, !v.isEmpty, v != "Username" {
                let del = String(repeating: XCUIKeyboardKey.delete.rawValue, count: min(v.count, 40))
                u.typeText(del)
            }
            u.typeText(user)
            p.tap()
            p.typeText(pass)
            if app.keyboards.buttons["return"].exists {
                app.keyboards.buttons["return"].tap()
            } else if app.keyboards.buttons["Done"].exists {
                app.keyboards.buttons["Done"].tap()
            }
            let submit = app.buttons["login.submit"].exists
                ? app.buttons["login.submit"]
                : app.buttons["Log in"]
            submit.tap()
            // Wait for network login
            _ = app.staticTexts["Today"].waitForExistence(timeout: 20)
                || app.buttons["Today"].waitForExistence(timeout: 2)
                || app.descendants(matching: .any)["tab.today"].waitForExistence(timeout: 2)
            if app.buttons["Log in"].exists {
                app.buttons["Log in"].tap()
                Thread.sleep(forTimeInterval: 3.0)
            }
        }

        func tab(_ id: String, label: String) -> XCUIElement {
            let byId = app.descendants(matching: .any)[id]
            if byId.exists { return byId }
            let byBtn = app.buttons[label]
            if byBtn.exists { return byBtn }
            return app.staticTexts[label]
        }

        let profileTab = tab("tab.profile", label: "Profile")
        let todayTab = tab("tab.today", label: "Today")
        let progressTab = tab("tab.progress", label: "Progress")

        let reached =
            profileTab.waitForExistence(timeout: 25)
            || todayTab.waitForExistence(timeout: 2)
            || app.staticTexts["Today"].waitForExistence(timeout: 2)
            || app.navigationBars["Today"].waitForExistence(timeout: 2)

        if !reached {
            saveShot("00-login-failed")
            let labels = app.staticTexts.allElementsBoundByIndex.prefix(10).map(\.label)
            XCTFail("Login did not reach main UI. labels=\(labels) user=\(user)")
            return
        }

        if todayTab.exists { todayTab.tap() }
        Thread.sleep(forTimeInterval: 1.0)
        saveShot("01-today")

        if progressTab.waitForExistence(timeout: 4) { progressTab.tap() }
        Thread.sleep(forTimeInterval: 1.2)
        saveShot("02-progress")

        if profileTab.waitForExistence(timeout: 4) { profileTab.tap() }
        Thread.sleep(forTimeInterval: 1.0)
        saveShot("03-profile")

        let light = app.buttons["Light"]
        if light.waitForExistence(timeout: 3) {
            light.tap()
            Thread.sleep(forTimeInterval: 1.0)
            saveShot("04-profile-light")
            if app.buttons["Dark"].exists {
                app.buttons["Dark"].tap()
                Thread.sleep(forTimeInterval: 0.8)
                saveShot("05-profile-dark")
            }
        }
    }

    private func saveShot(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
        let url = URL(fileURLWithPath: "/tmp/fitos-\(name).png")
        try? shot.pngRepresentation.write(to: url)
    }
}
