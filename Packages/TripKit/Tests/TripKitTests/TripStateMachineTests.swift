import XCTest
import CoreKit
import GameEngine
@testable import TripKit

final class TripStateMachineTests: XCTestCase {
    // §2.2 — scheduled → active ⇄ paused → completed.
    func testValidTransitions() {
        XCTAssertTrue(TripStateMachine.canTransition(from: .scheduled, to: .active))
        XCTAssertTrue(TripStateMachine.canTransition(from: .active, to: .paused))
        XCTAssertTrue(TripStateMachine.canTransition(from: .paused, to: .active))
        XCTAssertTrue(TripStateMachine.canTransition(from: .active, to: .completed))
        XCTAssertTrue(TripStateMachine.canTransition(from: .paused, to: .completed))
    }

    func testInvalidTransitions() {
        XCTAssertFalse(TripStateMachine.canTransition(from: .scheduled, to: .paused))
        XCTAssertFalse(TripStateMachine.canTransition(from: .scheduled, to: .completed))
        XCTAssertFalse(TripStateMachine.canTransition(from: .completed, to: .active))
        XCTAssertFalse(TripStateMachine.canTransition(from: .completed, to: .scheduled))
        XCTAssertFalse(TripStateMachine.canTransition(from: .paused, to: .scheduled))
        XCTAssertFalse(TripStateMachine.canTransition(from: .active, to: .active))
    }

    func testTransitionStampsTimestamps() {
        let trip = Trip(travelMode: .car, status: .scheduled)
        let start = Date(timeIntervalSince1970: 1_000)
        let end = Date(timeIntervalSince1970: 5_000)

        XCTAssertTrue(TripStateMachine.transition(trip, to: .active, at: start))
        XCTAssertEqual(trip.startedAt, start)

        XCTAssertTrue(TripStateMachine.transition(trip, to: .paused, at: start.addingTimeInterval(60)))
        XCTAssertTrue(TripStateMachine.transition(trip, to: .active, at: start.addingTimeInterval(120)))
        // startedAt is first activation only.
        XCTAssertEqual(trip.startedAt, start)

        XCTAssertTrue(TripStateMachine.transition(trip, to: .completed, at: end))
        XCTAssertEqual(trip.completedAt, end)
        XCTAssertEqual(trip.status, .completed)
    }

    func testInvalidTransitionLeavesTripUntouched() {
        let trip = Trip(travelMode: .car, status: .scheduled)
        XCTAssertFalse(TripStateMachine.transition(trip, to: .completed))
        XCTAssertEqual(trip.status, .scheduled)
        XCTAssertNil(trip.completedAt)
    }

    // §2.1 — board recommends only playable games ordered by age fit.
    func testGameBoardGeneratorFiltersAndOrders() {
        let players = [
            PlayerContext(id: UUID(), name: "Driver", ageBand: .adult, isDriver: true),
            PlayerContext(id: UUID(), name: "Kid", ageBand: .early, isDriver: false)
        ]
        let kidGame = GameManifest(
            id: "kid-fit", nameKey: "k", icon: "star", minPlayers: 1,
            ageBands: .preschool ... .tween, driverSafe: false, screenLevel: .minimal,
            contentScope: .activePlayer
        )
        let familyGame = GameManifest(
            id: "family-fit", nameKey: "f", icon: "star", minPlayers: 1,
            ageBands: .preschool ... .adult, driverSafe: true, screenLevel: .none,
            contentScope: .youngestInRound
        )
        let planeOnly = GameManifest(
            id: "plane-only", nameKey: "p", icon: "star", minPlayers: 1,
            ageBands: .preschool ... .adult, driverSafe: true, screenLevel: .minimal,
            travelModes: [.plane], contentScope: .youngestInRound
        )

        let board = GameBoardGenerator.recommendedManifests(
            from: [kidGame, familyGame, planeOnly],
            players: players,
            mode: .car
        )

        XCTAssertEqual(board.map(\.id), ["family-fit", "kid-fit"])
    }
}
