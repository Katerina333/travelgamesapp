import XCTest

/// End-to-end vertical slice (dev plan §8.5 step 2): onboarding → trip
/// creation → Road Bingo → leaderboard → force-quit → resume at the exact
/// board with scores intact.
final class VerticalSliceUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    // Train mode: no driver concept, board matched to train games only.
    func testTrainTripHasNoDriverAndGetsTrainGames() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()

        app.buttons["btn.newTrip"].tap()
        app.buttons["travelType.train"].tap()

        app.buttons["btn.addTraveler"].tap()
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.switches["toggle.driver"].exists, "trains have no driver")
        app.buttons["btn.saveTraveler"].tap()

        let createButton = app.buttons["btn.createTrip"]
        XCTAssertTrue(createButton.isEnabled, "no driver required for train trips")
        createButton.tap()

        XCTAssertTrue(app.buttons["row.game.trainbingo"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["row.game.roadbingo"].exists)
        XCTAssertFalse(app.buttons["row.game.cabinbingo"].exists)
    }

    func testCreateTripPlayBingoForceQuitAndResume() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()

        // Onboarding
        app.buttons["btn.newTrip"].tap()

        // Traveler 1: adult driver ("Player 1", 35)
        app.buttons["btn.addTraveler"].tap()
        let ageWheel = app.pickerWheels.firstMatch
        XCTAssertTrue(ageWheel.waitForExistence(timeout: 5))
        ageWheel.adjust(toPickerWheelValue: "35")
        // The switch element's frame spans the whole form row; tap the right
        // edge where the actual control sits.
        let driverToggle = app.switches["toggle.driver"].firstMatch
        XCTAssertTrue(driverToggle.waitForExistence(timeout: 3))
        driverToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        XCTAssertEqual(driverToggle.value as? String, "1", "driver toggle must be on")
        app.buttons["btn.saveTraveler"].tap()

        // Traveler 2: kid ("Player 2", 6)
        app.buttons["btn.addTraveler"].tap()
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "6")
        app.buttons["btn.saveTraveler"].tap()

        let createButton = app.buttons["btn.createTrip"]
        XCTAssertTrue(createButton.isEnabled)
        createButton.tap()

        // Trip screen → Road Bingo
        let bingoRow = app.buttons["row.game.roadbingo"]
        XCTAssertTrue(bingoRow.waitForExistence(timeout: 5))
        bingoRow.tap()

        // Mark cell 0. The driver is excluded from bingo (§1.2), so the kid
        // is the only eligible spotter and the point auto-assigns.
        let cell = app.buttons["bingo.cell.0"]
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        let itemBeforeQuit = cell.label
        cell.tap()
        XCTAssertEqual(cell.value as? String, "marked")

        // Leaderboard shows the kid's point.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let points = app.staticTexts["leaderboard.points.Player 2"]
        XCTAssertTrue(points.waitForExistence(timeout: 5))
        XCTAssertEqual(points.label, "1")

        // Force-quit mid-round.
        app.terminate()

        // Relaunch WITHOUT the reset flag — everything must be restored.
        let relaunched = XCUIApplication()
        relaunched.launch()

        let continueButton = relaunched.buttons["btn.continueTrip"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        let resumedRow = relaunched.buttons["row.game.roadbingo"]
        XCTAssertTrue(resumedRow.waitForExistence(timeout: 5))
        // Open session badge proves the round survived the kill.
        XCTAssertTrue(relaunched.staticTexts["trip.status.inProgress"].exists
                      || resumedRow.label.contains("In progress"))
        resumedRow.tap()

        let resumedCell = relaunched.buttons["bingo.cell.0"]
        XCTAssertTrue(resumedCell.waitForExistence(timeout: 5))
        XCTAssertEqual(resumedCell.value as? String, "marked", "mark must survive force-quit")
        XCTAssertEqual(resumedCell.label, itemBeforeQuit, "board must be the identical one, not regenerated")

        // Score survived too.
        relaunched.navigationBars.buttons.element(boundBy: 0).tap()
        let resumedPoints = relaunched.staticTexts["leaderboard.points.Player 2"]
        XCTAssertTrue(resumedPoints.waitForExistence(timeout: 5))
        XCTAssertEqual(resumedPoints.label, "1")
    }
}
