import XCTest
import CoreKit
import GameEngine
@testable import TripKit

final class TripBuilderTests: XCTestCase {
    private var manifests: [GameManifest] {
        [
            GameManifest(
                id: "roadbingo", nameKey: "r", icon: "star", minPlayers: 1,
                ageBands: .preschool ... .adult, driverSafe: false,
                screenLevel: .minimal, travelModes: [.car], contentScope: .youngestInRound
            ),
            GameManifest(
                id: "cabinbingo", nameKey: "c", icon: "star", minPlayers: 1,
                ageBands: .preschool ... .adult, driverSafe: true,
                screenLevel: .minimal, travelModes: [.plane], contentScope: .youngestInRound
            ),
            GameManifest(
                id: "trainbingo", nameKey: "t", icon: "star", minPlayers: 1,
                ageBands: .preschool ... .adult, driverSafe: true,
                screenLevel: .minimal, travelModes: [.train], contentScope: .youngestInRound
            )
        ]
    }

    func testCarTripBoardAndActivation() {
        let travelers = [
            Traveler(name: "Mom", age: 35, isDriver: true),
            Traveler(name: "Kid", age: 6)
        ]
        let now = Date(timeIntervalSince1970: 1_000)
        let trip = TripBuilder.makeTrip(
            travelers: travelers, mode: .car, length: .long,
            destinationName: "Grandma", manifests: manifests, now: now
        )
        XCTAssertEqual(trip.gameBoard, ["roadbingo"])
        XCTAssertEqual(trip.status, .active)
        XCTAssertEqual(trip.startedAt, now)
        XCTAssertFalse(trip.quietMode)
    }

    // §1.4 — plane trips get plane games and Quiet Mode on by default.
    func testPlaneTripDefaultsQuietModeAndPlaneGames() {
        let trip = TripBuilder.makeTrip(
            travelers: [Traveler(name: "Kid", age: 8)],
            mode: .plane, length: .medium, manifests: manifests
        )
        XCTAssertEqual(trip.gameBoard, ["cabinbingo"])
        XCTAssertTrue(trip.quietMode)
    }

    // Train trips: window-spotting game matched, Quiet Mode on, no driver needed.
    func testTrainTripMatchesTrainGamesQuietByDefault() {
        let trip = TripBuilder.makeTrip(
            travelers: [Traveler(name: "Kid", age: 8), Traveler(name: "Dad", age: 40)],
            mode: .train, length: .long, manifests: manifests
        )
        XCTAssertEqual(trip.gameBoard, ["trainbingo"])
        XCTAssertTrue(trip.quietMode)
        XCTAssertEqual(trip.status, .active)
        XCTAssertFalse(trip.travelers.contains { $0.isDriver })
    }

    func testScheduledTripStaysScheduled() {
        let trip = TripBuilder.makeTrip(
            travelers: [Traveler(name: "Kid", age: 8)],
            mode: .car, length: .short, manifests: [],
            startNow: false, scheduledStart: Date(timeIntervalSince1970: 9_999)
        )
        XCTAssertEqual(trip.status, .scheduled)
        XCTAssertNil(trip.startedAt)
    }

    func testLeaderboardAggregatesAcrossSessions() {
        let mom = Traveler(name: "Mom", age: 35)
        let kid = Traveler(name: "Kid", age: 6)
        let s1 = GameSessionRecord(gameID: "roadbingo", scores: [mom.id: 2, kid.id: 3])
        let s2 = GameSessionRecord(gameID: "trivia", scores: [kid.id: 4])

        let ranked = Leaderboard.ranked(travelers: [mom, kid], sessions: [s1, s2])
        XCTAssertEqual(ranked.map(\.traveler.name), ["Kid", "Mom"])
        XCTAssertEqual(ranked.map(\.points), [7, 2])
    }

    func testLeaderboardTieBrokenByName() {
        let b = Traveler(name: "Bella", age: 7)
        let a = Traveler(name: "Alex", age: 9)
        let session = GameSessionRecord(gameID: "g", scores: [a.id: 5, b.id: 5])
        let ranked = Leaderboard.ranked(travelers: [b, a], sessions: [session])
        XCTAssertEqual(ranked.map(\.traveler.name), ["Alex", "Bella"])
    }
}
