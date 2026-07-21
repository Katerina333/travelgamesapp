import XCTest

/// Drives the happy path and saves screenshots as always-kept attachments so
/// they can be exported from the .xcresult for design review.
final class ScreenshotUITests: XCTestCase {
    private func snap(_ app: XCUIApplication, _ name: String) {
        let shot = app.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    func testCaptureKeyScreens() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()

        // Onboarding (empty)
        app.buttons["btn.newTrip"].tap()
        XCTAssertTrue(app.buttons["btn.addTraveler"].waitForExistence(timeout: 5))
        snap(app, "01-onboarding-empty")

        // Add traveler with a real name + avatar
        app.buttons["btn.addTraveler"].tap()
        let nameField = app.textFields["field.travelerName"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Mia")
        snap(app, "02-add-traveler")
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "7")
        app.buttons["btn.saveTraveler"].tap()

        // Add a second traveler (the driver)
        app.buttons["btn.addTraveler"].tap()
        let n2 = app.textFields["field.travelerName"]
        XCTAssertTrue(n2.waitForExistence(timeout: 5))
        n2.tap(); n2.typeText("Dad")
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "38")
        app.switches["toggle.driver"].firstMatch
            .coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        app.buttons["btn.saveTraveler"].tap()

        snap(app, "03-onboarding-filled")

        // Create the trip → board with several games
        app.buttons["btn.createTrip"].tap()
        XCTAssertTrue(app.buttons["row.game.wouldyourather"].waitForExistence(timeout: 6))
        snap(app, "04-trip-board")

        // Open Would You Rather
        app.buttons["row.game.wouldyourather"].tap()
        XCTAssertTrue(app.buttons["btn.wyrOption.0"].waitForExistence(timeout: 5))
        snap(app, "05-would-you-rather")
        app.buttons["btn.wyrOption.0"].tap()
        snap(app, "06-wyr-picked")
    }
}
