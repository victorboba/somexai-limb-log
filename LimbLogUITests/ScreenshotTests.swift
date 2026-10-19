import XCTest

/// Captures App Store screenshots. Run with scripts/screenshots.sh LimbLog.
final class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testAppScreens() {
        let app = XCUIApplication()
        app.launchArguments = ["-unlock", "-resetData", "-sampleData", "-skipOnboarding", "-uiTesting"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Measure now"].waitForExistence(timeout: 10))
        snap("01-home", app)

        app.buttons["Measure now"].tap()
        XCTAssertTrue(app.navigationBars["Measure"].waitForExistence(timeout: 5))
        snap("02-measure", app)
        app.buttons["Cancel"].tap()

        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        snap("03-history", app)

        app.tabBars.buttons["Report"].tap()
        XCTAssertTrue(app.navigationBars["Report"].waitForExistence(timeout: 5))
        snap("04-report", app)

        app.tabBars.buttons["Home"].tap()
        app.buttons["Log symptoms"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Symptoms"].waitForExistence(timeout: 5))
        snap("05-symptoms", app)
        app.buttons["Cancel"].tap()

        app.buttons["How do I use this app"].tap()
        XCTAssertTrue(app.navigationBars.element.waitForExistence(timeout: 5))
        snap("06-how-to", app)
    }

    func testPaywall() {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "-uiTesting", "-mockPrices"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Lifetime"].waitForExistence(timeout: 10))
        snap("paywall", app)
    }

    private func snap(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
